import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plasma_wallet/constants/themes.dart';
import 'package:plasma_wallet/router.dart';

import 'constants/strings.dart';

void main() {
  runApp(
    /// required for Riverpod state management
    const ProviderScope(
      child: Bridge(),
    ),
  );
}

class Bridge extends StatelessWidget {
  const Bridge({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Strings.appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
