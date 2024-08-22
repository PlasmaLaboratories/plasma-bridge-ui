import 'dart:convert';

import 'package:apparatus_wallet/features/bridge/providers/password_state.dart';
import 'package:apparatus_wallet/features/bridge/providers/rpc_channel.dart';
import 'package:apparatus_wallet/features/bridge/providers/service_kit.dart';
import 'package:apparatus_wallet/features/bridge/providers/wallet_key_vault.dart';
import 'package:apparatus_wallet/features/peg_in/logic/bridge_api_interface.dart';
import 'package:apparatus_wallet/features/peg_in/providers/bridge_api.dart';
import 'package:brambldart/brambldart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:topl_common/proto/brambl/models/datum.pb.dart';
import 'package:topl_common/proto/brambl/models/event.pb.dart';
import 'package:topl_common/proto/node/services/bifrost_rpc.pbgrpc.dart';
import 'package:topl_common/proto/quivr/models/proposition.pb.dart';
import 'package:topl_common/proto/quivr/models/shared.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:convert/convert.dart' show hex;

part 'peg_in.freezed.dart';
part 'peg_in.g.dart';

@riverpod
class PegIn extends _$PegIn {
  @override
  PegInState build() {
    ref.watch(walletKeyVaultProvider);
    return PegInState.base();
  }

  startSession() async {
    state = state.copyWith(sessionStarted: true);
    final uuid = const Uuid().v4();
    final uuidBytes = utf8.encode(uuid);
    final hashed = sha256.hash(uuidBytes);
    final hashedEncoded = hex.encode(hashed);
    final serviceKit = await ref.read(serviceKitProvider.future);
    final preimage = Preimage(
      input: uuidBytes,
      salt: [],
    ); // TODO: BramblSc implementation doesn't use a salt when the input is 32 bytes or longer
    final digestProposition =
        Proposition_Digest(routine: "Sha256", digest: Digest(value: hashed));
    serviceKit.walletStateApi.addPreimage(preimage, digestProposition);

    final request = StartSessionRequest(
        pkey:
            // TODO: This should be updated once the bridge supports VK exchange
            "0295bb5a3b80eeccb1e38ab2cbac2545e9af6c7012cdc8d53bd276754c54fc2e4a",
        sha256: hashedEncoded);
    state = state.copyWith(uuid: uuid, sha256: hashedEncoded);
    try {
      final response = await ref.watch(bridgeApiProvider).startSession(request);
      state = state.copyWith(
        sessionID: response.sessionID,
        escrowAddress: response.escrowAddress,
      );
    } catch (e) {
      state = state.copyWith(error: "An error occurred. Lol! $e");
    }
  }

  btcDeposited() {
    state = state.copyWith(btcDeposited: true);
    final bridgeApi = ref.watch(bridgeApiProvider);
    final sub = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => bridgeApi.getMintingStatus(state.sessionID!))
        .map((status) {
          if (status == null) throw Exception("Session not found");
          return status;
        })
        .where((status) =>
            status is MintingStatus_PeginSessionWaitingForRedemption)
        // Using where + take(1) instead of firstWhere to avoid losing the cancelation benefits of the stream
        .cast<MintingStatus_PeginSessionWaitingForRedemption>()
        .take(1)
        .asyncMap((status) => _prepareTx(status.address, status.redeemScript))
        .asyncMap((tx) async {
          final nodeClient =
              NodeRpcClient(ref.read(rpcChannelProvider).nodeRpcChannel);

          // Finally, broadcast the transaction
          await nodeClient
              .broadcastTransaction(BroadcastTransactionReq(transaction: tx));
        })
        .listen((_) {
          state = state.copyWith(tBtcMinted: true);
        });
    sub.onError((e, s) =>
        state = state.copyWith(error: "An error occurred. Lol! $e\n$s"));
    ref.onDispose(sub.cancel);
  }

  tBtcAccepted() {
    state = PegInState.base();
  }

  _prepareTx(String address, String redeemScript) async {
    final genusClient =
        GenusQueryAlgebra(ref.read(rpcChannelProvider).genusRpcChannel);
    final serviceKit = await ref.read(serviceKitProvider.future);
    final templateStorage = serviceKit.templateStorageApi;
    final templateName = "bridge-${state.sha256}";
    const fellowshipName = "bridge";
    final redeemAddress = AddressCodecs.decode(address).getOrThrow();
    final decodedRedeemScript = _decodeRedeemScript(redeemScript);

    await templateStorage.addTemplate(WalletTemplate(
        1, templateName, json.encode(decodedRedeemScript.toJson())));

    await serviceKit.walletStateApi
        .addEntityVks(fellowshipName, templateName, []);

    final lockTemplate =
        serviceKit.walletStateApi.getLockTemplate(templateName)!;
    final lock = lockTemplate.build([]).getOrThrow();
    assert(lock == decodedRedeemScript.build([]).getOrThrow());
    final lockAddress = await serviceKit
        .simpleTransactionAlgebra.transactionBuilderApi
        .lockAddress(lock);
    assert(redeemAddress == lockAddress);
    final indices = serviceKit.walletStateApi
        .getNextIndicesForFunds(fellowshipName, templateName)!;
    final password = ref.read(passwordStateProvider);
    final keyPair = serviceKit.walletApi
        .extractMainKey(await ref.read(walletKeyVaultProvider.future),
            password.toUtf8Uint8List())
        .getOrThrow();
    final deriveChildKey =
        serviceKit.walletApi.deriveChildKeys(keyPair, indices);
    await serviceKit.walletStateApi.updateWalletState(
        Encoding().encodeToBase58Check(lock.predicate.writeToBuffer()),
        AddressCodecs.encode(lockAddress),
        "ExtendedEd25519",
        Encoding().encodeToBase58Check(deriveChildKey.vk.writeToBuffer()),
        indices);

    // Fetch the UTxOs associated with the redeem address
    final redeemUtxos = await genusClient.queryUtxo(fromAddress: redeemAddress);
    // Expect only one UTxO to be associated with the redeem address (since _we_ came up with the unique sha256/UUID)
    final redeemUtxo = redeemUtxos.first;
    // Expect the UTxO to contain an asset value
    final asset = redeemUtxo.transactionOutput.value.ensureAsset();

    // Create a transaction to redeem the asset
    final unprovenTxResult = await serviceKit.simpleTransactionAlgebra
        .createSimpleTransactionFromParams(
      keyfile: WalletApiDefinition.defaultName,
      password: password,
      fromFellowship: fellowshipName,
      fromTemplate: templateName,
      someToFellowship: "self",
      someToTemplate: "default",
      amount: asset.quantity.toBigInt().toInt(), // TODO: int vs Int128
      // TODO: Actual fee
      fee: 0,
      tokenType: AssetType(
        ByteString.fromList(asset.groupId.value),
        ByteString.fromList(asset.seriesId.value),
      ),
    );
    final unprovenTx = unprovenTxResult.getOrThrow()..freeze();
    // TODO: Move Context creation to a separate function
    final nodeRpc = NodeRpcClient(ref.read(rpcChannelProvider).nodeRpcChannel);
    final canonicalHeadId =
        (await nodeRpc.fetchBlockIdAtDepth(FetchBlockIdAtDepthReq()))
            .ensureBlockId();
    final head = (await nodeRpc
            .fetchBlockHeader(FetchBlockHeaderReq(blockId: canonicalHeadId)))
        .ensureHeader();
    final context = Context(
      unprovenTx,
      head.slot + 1,
      {
        "header": Datum(
            header: Datum_Header(event: Event_Header(height: head.height + 1)))
      },
    );
    final txOrErrors = CredentiallerInterpreter(
            serviceKit.walletApi, serviceKit.walletStateApi, keyPair)
        .proveAndValidate(unprovenTx, context);
    final tx = txOrErrors.fold((e) {
      if (e.isEmpty) {
        throw Exception("Validation failed, but no errors reported");
      } else {
        throw e.first;
      }
    }, (t) => t);
    return tx;
  }
}

@freezed
class PegInState with _$PegInState {
  const factory PegInState({
    required bool sessionStarted,
    required String? uuid,
    required String? sha256,
    required String? sessionID,
    required String? escrowAddress,
    required bool btcDeposited,
    required bool tBtcMinted,
    required String? error,
  }) = _PegInState;

  factory PegInState.base() => const PegInState(
        sessionStarted: false,
        uuid: null,
        sha256: null,
        sessionID: null,
        escrowAddress: null,
        btcDeposited: false,
        tBtcMinted: false,
        error: null,
      );
}

PredicateTemplate _decodeRedeemScript(String encoded) {
  // NOTE: The encoded string contains an erroneous quotation mark at the beginning
  final regex = RegExp(
      r'"threshold\(1, sha256\(([a-zA-Z0-9]+)\) and height\(([0-9]+), ([0-9]+)\)\)');
  final matches = regex.allMatches(encoded).first;
  assert(matches.groupCount == 3, "Invalid redeem script");
  final sha256 = matches[1]!;
  final heightMin = Int64.parseInt(matches[2]!);
  final heightMax = Int64.parseInt(matches[3]!);
  return PredicateTemplate(
    [
      AndTemplate(
        DigestTemplate("Sha256", Digest(value: hex.decode(sha256))),
        HeightTemplate("header", heightMin, heightMax),
      ),
    ],
    1,
  );
}
