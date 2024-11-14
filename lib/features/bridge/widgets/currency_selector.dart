import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plasma_wallet/features/bridge/providers/bridge_state.dart';
import 'package:plasma_wallet/features/bridge/widgets/currency_segments.dart';
import 'package:plasma_wallet/utils/ui_utils.dart';

class CurrencySelector extends HookConsumerWidget {
  const CurrencySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridgeApi = ref.watch(bridgeProvider);
    final bridgeApiNotifier = ref.read(bridgeProvider.notifier);

    return Row(
      children: [
        IconButton(
            padding: const EdgeInsets.all(16),
            icon: const Icon(
              Icons.swap_horiz,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              bridgeApiNotifier.swap();
            }),
        horizontalSpacerM,
        Container(
          child: bridgeApi.currency == Currency.ethereum
              ? ethSegment
              : bitcoinSegment,
        )
      ],
    );
  }
}
