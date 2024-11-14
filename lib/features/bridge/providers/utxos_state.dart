import 'package:plasma_wallet/features/bridge/providers/rpc_channel.dart';
import 'package:plasma_wallet/features/bridge/providers/service_kit.dart';
import 'package:plasma_wallet/features/bridge/providers/wallet_key_vault.dart';
import 'package:plasma_sdk/plasma_sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:plasma_protobuf/plasma_protobuf.dart';

part 'utxos_state.g.dart';

@riverpod
class UtxosState extends _$UtxosState {
  @override
  Stream<UtxosMap> build() async* {
    await ref.watch(walletKeyVaultProvider.future);
    final serviceKit = await ref.watch(serviceKitProvider.future);
    final rpcChannels = ref.watch(rpcChannelProvider);
    final nodeRpcClient = NodeRpcClient(rpcChannels.nodeRpcChannel);
    final genusRpcClient =
        TransactionServiceClient(rpcChannels.genusRpcChannel);

    final encodedGenesisAddress =
        serviceKit.walletStateApi.getAddress("nofellowship", "genesis", 1)!;
    final genesisAddress =
        AddressCodecs.decode(encodedGenesisAddress).getOrThrow();

    Future<UtxosMap> fetchUtxos() async {
      // Get the current address from the wallet
      final encodedAddress = serviceKit.walletStateApi.getCurrentAddress();
      final address = AddressCodecs.decode(encodedAddress).getOrThrow();
      final utxosList = [
        ...(await genusRpcClient.getTxosByLockAddress(QueryByLockAddressRequest(
                address: address, state: TxoState.UNSPENT)))
            .txos,
        // In addition to the local wallet's funds, also fetch the public genesis funds
        ...(await genusRpcClient.getTxosByLockAddress(QueryByLockAddressRequest(
                address: genesisAddress, state: TxoState.UNSPENT)))
            .txos,
      ];
      final utxos =
          Map.fromEntries(utxosList.map((u) => MapEntry(u.outputAddress, u)));
      return utxos;
    }

    yield await fetchUtxos();

    // For each block adoption or unadoption
    await for (final _ in nodeRpcClient
        .synchronizationTraversal(SynchronizationTraversalReq())) {
      // Wait 1 second for Genus to catch up
      await Future.delayed(const Duration(seconds: 1));
      yield await fetchUtxos();
    }
  }
}

typedef UtxosMap = Map<TransactionOutputAddress, Txo>;
