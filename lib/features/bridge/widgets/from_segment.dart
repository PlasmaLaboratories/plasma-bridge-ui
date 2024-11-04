import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plasma_wallet/constants/strings.dart';
import 'package:plasma_wallet/features/bridge/providers/bridge_state.dart';
import 'package:plasma_wallet/utils/ui_utils.dart';
import 'package:plasma_wallet/utils/utils.dart';

class FromSegment extends HookConsumerWidget {
  const FromSegment({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bridgeProvider.notifier);
    final bridgeApi = ref.watch(bridgeProvider);

    // final currValue = useState("0");
    final fetchTimeStamp = useState(DateTime.fromMicrosecondsSinceEpoch(0));
    final fetchedRates = useState(false);
    final fetchTimeStampText = useState(Strings.warningRates);

    useEffect(() {
      void updateTooltip() {
        fetchTimeStampText.value = formatTimestamp(fetchTimeStamp.value);
      }

      void fetchRates() async {
        try {
          await notifier.fetchCryptoRates();
          fetchedRates.value = true;
          fetchTimeStamp.value = DateTime.now();
          updateTooltip();
        } catch (e) {
          if (kDebugMode) {
            // TODO: introduce real logging
            print("${Strings.failedToFetchRates}: $e");
          }
        }
      }

      // Call fetchRates immediately
      fetchRates();

      // Then call fetchRates every 5 minutes
      final timer = Timer.periodic(const Duration(minutes: 5), (Timer t) {
        fetchRates();
        // update tooltip
      });

      final fetchTimer = Timer.periodic(
          const Duration(seconds: 15), (Timer t) => updateTooltip());

      // Return a cleanup function to cancel the timer when the widget is unmounted
      return () {
        timer.cancel();
        fetchTimer.cancel();
      };
    }, const []);

    return Container(
        decoration: BoxDecoration(
          // color: Theme.of(context).colorScheme.primary,
          color: a2,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Strings.deposit,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: textL,
                    fontWeight: FontWeight.bold)),
            Container(
              color: a2,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      // width: 350,
                      child: TextField(
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            hintText: '0',
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 48,
                                fontWeight: FontWeight.bold)),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (value) {
                          if (value.isEmpty) {
                            notifier.updateValue(0);
                            return;
                          } else if (value == ".") {
                            notifier.updateValue(double.parse("0$value"));
                            return;
                          }
                          notifier.updateValue(double.parse(value));
                        },
                      ),
                    ),
                  ),
                  horizontalSpacerM,
                  Text(
                      bridgeApi.currency == Currency.ethereum
                          ? Strings.eth
                          : Strings.btc,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: textL,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Tooltip(
              message: fetchTimeStampText.value,
              child: Row(
                  //  used to keep tooltip on only the visible part of the row
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("≈ \$${notifier.convertedValue}",
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: textM,
                            fontWeight: FontWeight.bold)),
                    horizontalSpacerM,
                    !fetchedRates.value
                        ? const Icon(Icons.warning, color: Colors.red)
                        : const SizedBox(),
                  ]),
            )
          ],
        ));
  }
}
