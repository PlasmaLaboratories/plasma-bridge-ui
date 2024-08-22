import 'package:apparatus_wallet/features/peg_in/providers/peg_in.dart';
import 'package:apparatus_wallet/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
    if (state.error != null) {
      return errorWidget(state.error!);
    }
    if (state.sessionStarted) {
      if (state.escrowAddress == null || state.sessionID == null) {
        return const CircularProgressIndicator();
      } else {
        if (state.tBtcMinted) {
          return PegInClaimFundsPage(onAccepted: () {
            ref.watch(pegInProvider.notifier).tBtcAccepted();
            context.go(walletRoute);
          });
        }
        if (state.btcDeposited) {
          return PegInAwaitingFundsStage(sessionID: state.sessionID!);
        } else {
          return PegInDepositFundsStage(
            sessionID: state.sessionID!,
            escrowAddress: state.escrowAddress!,
            onDeposit: () => ref.watch(pegInProvider.notifier).btcDeposited(),
          );
        }
      }
    } else {
      return startSessionButton(ref);
    }
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

/// A scaffolded page instructing users where to deposit BTC funds
class PegInDepositFundsStage extends StatelessWidget {
  const PegInDepositFundsStage(
      {super.key,
      required this.sessionID,
      required this.escrowAddress,
      required this.onDeposit});

  final String sessionID;
  final String escrowAddress;
  final Function() onDeposit;

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
            TextButton.icon(
              onPressed: onDeposit,
              icon: const Icon(Icons.start),
              label: const Text("Next"),
            ),
          ],
        ),
      );
}

/// A scaffolded page which waits for the API to indicate funds have been deposited
class PegInAwaitingFundsStage extends StatelessWidget {
  const PegInAwaitingFundsStage({super.key, required this.sessionID});

  final String sessionID;

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
