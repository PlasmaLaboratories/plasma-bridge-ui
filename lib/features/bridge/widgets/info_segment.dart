import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plasma_wallet/constants/strings.dart';
import 'package:plasma_wallet/features/bridge/providers/bridge_state.dart';
import 'package:plasma_wallet/utils/ui_utils.dart';

class InfoSegment extends HookConsumerWidget {
  const InfoSegment({super.key});

  static const textStyle = TextStyle(
      color: Colors.white, fontSize: textM, fontWeight: FontWeight.w500);
  static const padding = EdgeInsets.symmetric(vertical: 8, horizontal: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bridgeProvider.notifier);

    /// makes the formatted/converted value reactive, might be a hacky way to do this,
    /// since these values are getters and not properties in the provider
    final (formattedValue, convertedValue) = ref.watch(bridgeProvider
        .select((value) => (notifier.formattedValue, notifier.convertedValue)));

    final toCurrency = useState(Strings.apparatus);
    final toAddress = useState("0x42....0a52");
    final transferTime = useState("~20 seconds");
    final networkFeeAbtc = useState(0.00005);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: a2),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 24),
              horizontalSpacerS,
              const Text(Strings.toAddress, style: textStyle),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(" ${toAddress.value}", style: textStyle),
                      horizontalSpacerS,
                      const Icon(Icons.check_circle_outlined,
                          color: Colors.green, size: 24)
                    ],
                  ))
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: a2,
            ),
          ),
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.currency_exchange,
                  color: Colors.white, size: 24),
              horizontalSpacerS,
              Text("${Strings.receiveOn} ${toCurrency.value}",
                  style: textStyle),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 125),
                child: Text(
                  "\$$convertedValue",
                  style: textStyle.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 4,
                ),
              ),
              horizontalSpacerS,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 125),
                child: Text(
                  "$formattedValue ${Strings.aBTC}",
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 4,
                  textAlign: TextAlign.end,
                ),
              )
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: a2,
            ),
          ),
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 24),
              horizontalSpacerS,
              const Text(Strings.transferTime, style: textStyle),
              const Spacer(),
              Text(" ${transferTime.value}", style: textStyle),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: a2),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
          ),
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.attach_money, color: Colors.white, size: 24),
              horizontalSpacerS,
              const Text(Strings.ourFee, style: textStyle),
              const Spacer(),
              Text("${networkFeeAbtc.value} ${Strings.aBTC}", style: textStyle),
            ],
          ),
        ),
      ],
    );
  }
}
