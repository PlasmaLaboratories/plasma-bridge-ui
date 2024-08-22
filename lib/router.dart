import 'package:apparatus_wallet/features/bridge/widgets/utxos_view.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:apparatus_wallet/features/bridge/bridge_ui.dart';
import 'package:apparatus_wallet/features/peg_in/widgets/peg_in.dart';

/// const routes # TODO move to own file once we get more routes
const homeRoute = '/';
const swapRoute = '/swap';
const walletRoute = '/wallet';

// GoRouter configuration
final router = GoRouter(
  initialLocation: homeRoute,
  debugLogDiagnostics:
      !kReleaseMode ? true : false, // Turns logging off when in release mode
  routes: [
    GoRoute(
      path: homeRoute,
      builder: (context, state) => const PegInPage(),
    ),
    GoRoute(
      path: swapRoute,
      builder: (context, state) => const BridgeUi(),
    ),
    GoRoute(
      path: walletRoute,
      builder: (context, state) => const UtxosView(),
    ),
  ],
);
