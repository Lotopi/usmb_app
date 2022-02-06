import 'package:flutter/material.dart';

import 'dynamic_week_view.dart';

void main() => runApp(_MyApp());

class _MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {'/': (context) => const DynamicWeekView()},
    );
  }
}
