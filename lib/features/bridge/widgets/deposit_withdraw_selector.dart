import 'package:flutter/material.dart';
import 'package:plasma_wallet/constants/strings.dart';
import 'package:plasma_wallet/utils/ui_utils.dart';

class DepositWithdrawSelector extends StatefulWidget {
  const DepositWithdrawSelector({super.key});

  @override
  State<DepositWithdrawSelector> createState() =>
      _DepositWithdrawSelectorState();
}

enum Options { deposit, withdraw }

class _DepositWithdrawSelectorState extends State<DepositWithdrawSelector> {
  static const tStyle = TextStyle(color: Colors.white, fontSize: textL);

  Options type = Options.deposit;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Options>(
      segments: <ButtonSegment<Options>>[
        ButtonSegment<Options>(
            value: Options.deposit, label: textPadding(Strings.deposit)),
        ButtonSegment<Options>(
            value: Options.withdraw,
            label: textPadding(Strings.withdraw),
            enabled: false),
      ],
      selected: {type},
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith<BorderSide>(
            (Set<WidgetState> states) {
          return const BorderSide(color: Colors.transparent);
        }),
        shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
            (Set<WidgetState> states) {
          return RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: primary),
          );
        }),
        backgroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return primary.withAlpha(50);
        }),
        foregroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
      ),
      showSelectedIcon: false,
      onSelectionChanged: (Set<Options> newSelection) {
        setState(() {
          // By default there is only a single segment that can be
          // selected at one time, so its value is always the first
          // item in the selected set.
          type = newSelection.first;
        });
      },
    );
  }

  // TODO: widget functions are bad convention, refactor
  Widget textPadding(String label) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, style: tStyle));
  }
}
