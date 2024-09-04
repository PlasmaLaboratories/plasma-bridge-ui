import 'package:apparatus_wallet/features/peg_in/providers/peg_in.dart';
import 'package:apparatus_wallet/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../logic/bridge_api_interface.dart';

/// A scaffolded page which allows a user to begin a new Peg-In session
class PegInPage extends HookConsumerWidget {
  const PegInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Acquire tBTC"),
      ),
      body: Center(child: body(context, ref)),
    );
  }

  Widget body(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pegInProvider);
    if (state is InactivePegInState) {
      return InactivePegInPage(state: state);
    } else if (state is ActivePegInState) {
      return ActivePegInPage(state: state);
    } else {
      return const CircularProgressIndicator();
    }
  }
}

class InactivePegInPage extends ConsumerWidget {
  final InactivePegInState state;

  const InactivePegInPage({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.error != null) return errorWidget(state.error!);
    return startSessionButton(ref);
  }

  Widget startSessionButton(WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => ref.read(pegInProvider.notifier).startSession(),
      icon: const Icon(Icons.start),
      label: const Text("Start Session"),
    );
  }

  Widget errorWidget(String message) => Text(message,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red));
}

class ActivePegInPage extends ConsumerWidget {
  final ActivePegInState state;

  const ActivePegInPage({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.error != null) return errorWidget(state.error!);
    if (state.mintingStatus is MintingStatus_PeginSessionWaitingForRedemption) {
      return PegInClaimFundsPage(onAccepted: () {
        ref.watch(pegInProvider.notifier).tBtcAccepted();
        context.go(walletRoute);
      });
    } else if (state.mintingStatus
        is MintingStatus_PeginSessionStateWaitingForBTC) {
      return PegInDepositFundsStage(
        escrowAddress: state.escrowAddress,
      );
    } else if (state.mintingStatus
            is MintingStatus_PeginSessionStateMintingTBTC ||
        state.mintingStatus
            is MintingStatus_PeginSessionMintingTBTCConfirmation) {
      return const PegInMintingTBTCStage();
    } else {
      return const PegInAwaitingFundsStage();
    }
  }

  Widget errorWidget(String message) => Center(
        child: Text(message,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
      );
}

/// A scaffolded page instructing users where to deposit BTC funds
class PegInDepositFundsStage extends StatelessWidget {
  const PegInDepositFundsStage({
    super.key,
    required this.escrowAddress,
  });

  final String escrowAddress;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Please send BTC to the following address.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: escrowAddress)),
              icon: const Icon(Icons.copy),
              label: Text(escrowAddress,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w100)),
            ),
          ],
        ),
      );
}

/// A scaffolded page which waits for the API to indicate funds have been deposited
class PegInAwaitingFundsStage extends StatelessWidget {
  const PegInAwaitingFundsStage({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          Center(
            child: Text('Please wait while we confirm the BTC transfer.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          CircularProgressIndicator(),
        ],
      );
}

class PegInMintingTBTCStage extends StatelessWidget {
  const PegInMintingTBTCStage({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          Center(
            child: Text('BTC Confirmed. Minting tBTC.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          CircularProgressIndicator(),
        ],
      );
}

/// A scaffolded page instructing users that tBTC funds are now available in their wallet
class PegInClaimFundsPage extends StatelessWidget {
  const PegInClaimFundsPage({super.key, required this.onAccepted});

  final Function() onAccepted;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Transaction sent. Your tBTC should be available soon.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: onAccepted,
              icon: const Icon(Icons.done),
              label: const Text("Back"),
            ),
          ],
        ),
      );
}
