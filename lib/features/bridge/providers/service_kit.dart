import 'package:plasma_wallet/features/bridge/providers/rpc_channel.dart';
import 'package:plasma_sdk/plasma_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:plasma_service_kit/plasma_service_kit.dart';
import 'package:plasma_service_kit/toolkit/features/wallet/wallet_management_utils.dart';

part 'service_kit.freezed.dart';

part 'service_kit.g.dart';

@riverpod
class ServiceKit extends _$ServiceKit {
  @override
  Future<ServiceKitState> build() async {
    final storage = await StorageApi.init();
    return ServiceKitState.base(storage, ref.watch(rpcChannelProvider));
  }
}

@freezed
class ServiceKitState with _$ServiceKitState {
  factory ServiceKitState({
    required StorageApi storageApi,
    required TemplateStorageApi templateStorageApi,
    required FellowshipStorageApi fellowshipStorageApi,
    required WalletApi walletApi,
    required WalletStateApi walletStateApi,
    required SimpleTransactionAlgebra simpleTransactionAlgebra,
  }) = _ServiceKitState;

  factory ServiceKitState.base(StorageApi storage, RpcChannelState channels) {
    final templateStorage = TemplateStorageApi(storage.sembast);
    final fellowshipStorage = FellowshipStorageApi(storage.sembast);
    final walletState = WalletStateApi(storage.sembast, storage.secureStorage,
        kdf: SCrypt(
            SCryptParams(salt: SCrypt.generateSalt(), n: _sCryptDefaultN)));

    final wallet = walletState.api;
    // TODO: Don't hardcode
    const transactionBuilderApi = TransactionBuilderApi(
        NetworkConstants.privateNetworkId, NetworkConstants.mainLedgerId);
    final indexQueryAlgebra = IndexerQueryAlgebra(channels.genusRpcChannel);
    final walletManagementUtils =
        WalletManagementUtils(walletApi: wallet, dataApi: wallet.walletKeyApi);
    final simpleTransactionAlgebra = SimpleTransactionAlgebra(
        walletApi: wallet,
        walletStateApi: walletState,
        utxoAlgebra: indexQueryAlgebra,
        transactionBuilderApi: transactionBuilderApi,
        walletManagementUtils: walletManagementUtils);
    return ServiceKitState(
      storageApi: storage,
      templateStorageApi: templateStorage,
      fellowshipStorageApi: fellowshipStorage,
      walletStateApi: walletState,
      walletApi: wallet,
      simpleTransactionAlgebra: simpleTransactionAlgebra,
    );
  }
}

// SCrypt/KDF is very slow in debug mode, so we use a lower value for testing
const _sCryptDefaultN = kDebugMode ? 2 : 262144;
