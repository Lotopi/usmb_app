import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usmb_app/welcome_page.dart';
//import 'package:usmb_app/verification_page.dart';

import 'dynamic_week_view.dart';

void main() => runApp(_MyApp());

class _MyApp extends StatelessWidget {
  Future<bool> _isLoggedIn() async {
    /*
      This asynchronous function return true if the user 
      already logged in.
    */

    bool res = false;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn');

    if (isLoggedIn == true) {
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
