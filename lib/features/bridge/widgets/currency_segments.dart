import 'package:flutter/material.dart';
import 'package:plasma_wallet/constants/assets.dart';
import 'package:plasma_wallet/constants/strings.dart';
import 'package:plasma_wallet/utils/ui_utils.dart';

final ethSegment = Row(
  children: [
    SizedBox(
      width: 48,
      height: 48,
      child: Assets.ethereum,
    ),
    horizontalSpacerM,
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        Strings.from,
        style: TextStyle(
          color: Colors.white,
          fontSize: textM,
        ),
      ),
      Text(
        Strings.ethereum,
        style: TextStyle(
          color: Colors.white,
          fontSize: textL,
        ),
      ),
    ]),
  ],
);

final apparatusSegment = Row(children: [
  SizedBox(
    width: 64,
    height: 64,
    child: Assets.apparatusDark,
  ),
  horizontalSpacerM,
  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(
      Strings.to,
      textAlign: TextAlign.start,
      style: TextStyle(
        color: Colors.white,
        fontSize: textM,
      ),
    ),
    Text(
      Strings.aBTC,
      style: TextStyle(
        color: Colors.white,
        fontSize: textL,
      ),
    ),
  ])
]);

final bitcoinSegment = Row(
  children: [
    SizedBox(
      width: 48,
      height: 48,
      child: Assets.bitcoin,
    ),
    horizontalSpacerM,
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        Strings.from,
        style: TextStyle(
          color: Colors.white,
          fontSize: textM,
        ),
      ),
      Text(
        Strings.bitcoin,
        style: TextStyle(
          color: Colors.white,
          fontSize: textL,
        ),
      ),
    ]),
  ],
);
