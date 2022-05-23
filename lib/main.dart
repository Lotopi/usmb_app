import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:usmb_app/welcome_page.dart';

import 'dynamic_week_view.dart';

void main() => runApp(_MyApp());

class _MyApp extends StatelessWidget {
  /// Secure storage
  final _storage = const FlutterSecureStorage();

  Future<bool> _isLoggedIn() async {
    /*
      This asynchronous function return true if the user 
      already logged in.
    */

    bool res = false;

    String isLoggedIn = await _storage.read(key: 'isLoggedIn') ?? '';

    if (isLoggedIn == 'true') {
      res = true;
    }

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FutureBuilder<bool>(
            future: _isLoggedIn(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return const DynamicWeekView();
              }
              return const WelcomePage();
            }));
  }
}
