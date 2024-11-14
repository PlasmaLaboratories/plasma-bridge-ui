import 'package:plasma_wallet/features/bridge/providers/password_state.dart';
import 'package:plasma_wallet/features/bridge/providers/service_kit.dart';
import 'package:plasma_sdk/plasma_sdk.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_key_vault.g.dart';

@riverpod
class WalletKeyVault extends _$WalletKeyVault {
  @override
  Future<VaultStore> build() async {
    final serviceKit = await ref.watch(serviceKitProvider.future);
    final password = ref.watch(passwordStateProvider).toUtf8Uint8List();
    try {
      return await serviceKit.walletApi.loadWallet();
    } catch (e) {
      if (e is WalletApiFailure &&
          e.type == WalletApiFailureType.failedToLoadWallet) {
        final saveResult = await serviceKit.walletApi.createNewWallet(password);
        final wallet = saveResult.mainKeyVaultStore;
        await serviceKit.walletApi.saveWallet(wallet);
        final mainKey = serviceKit.walletApi.extractMainKey(wallet, password);
        await serviceKit.walletStateApi.initWalletState(
          NetworkConstants.privateNetworkId,
          NetworkConstants.mainLedgerId,
          mainKey.vk,
        );
        await serviceKit.fellowshipStorageApi
            .addFellowship(WalletFellowship(1, "bridge"));
        return wallet;
      } else {
        rethrow;
      }
    }
  }
}
