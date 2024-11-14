import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plasma_wallet/constants/assets.dart';
import 'package:plasma_wallet/features/bridge/providers/bridge_state.dart';
import 'package:plasma_wallet/features/bridge/widgets/bridge_button.dart';
import 'package:plasma_wallet/features/bridge/widgets/deposit_withdraw_selector.dart';
import 'package:plasma_wallet/features/bridge/widgets/from_segment.dart';
import 'package:plasma_wallet/features/bridge/widgets/info_segment.dart';
import 'package:plasma_wallet/features/bridge/widgets/network_view.dart';
import 'package:plasma_wallet/utils/ui_utils.dart';

class BridgeUi extends ConsumerWidget {
  const BridgeUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: bkg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Assets.apparatusWhite,
            ),
            const Text("Apparatus Demo", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[BridgeContent()],
        ),
      ),
    );
  }
}

class BridgeContent extends ConsumerWidget {
  const BridgeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridgeApi = ref.watch(bridgeProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 650),
      // margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.primary,
        color: const Color(0xFF1e2025),
        borderRadius: BorderRadius.circular(32),
      ),
      width: double.infinity,
      // height: 800,
      // color: const Color(0xFF1e2025),
      child: Container(
          margin: const EdgeInsets.all(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Visibility(
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: !bridgeApi.loading,
                child: const Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DepositWithdrawSelector(),
                    verticalSpacerL,
                    NetworkView(),
                    verticalSpacerL,
                    FromSegment(),
                    verticalSpacerL,
                    InfoSegment(),
                    verticalSpacerL,
                    BridgeButton(),
                  ],
                ),
              ),
              Visibility(
                visible: bridgeApi.loading, // When loading, show the spinner
                child: const Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      strokeWidth: 10,
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
