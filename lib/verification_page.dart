import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'dynamic_week_view.dart';

import '../env.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({Key? key}) : super(key: key);

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  // This variable will be used to store the response of the server.
  dynamic _verificationResponse;

  // This variable will be used to store the token.
  String _token = "";

  TextEditingController codeController = TextEditingController();

  bool _isGoodFormat(String code) {
    /*
      @param code: The code we need to check.
      @return bool: True if the code format is good,
      false otherwise.

      Checks if the code format is correct.
    */

    bool res = false;

    // The regex pattern of a code.
    String pattern = r'(^[0-9]{6}$)';

    if (RegExp(pattern).hasMatch(code)) {
      res = true;
    }

    return res;
  }

  String? _validateCode(String? code) {
    /*
      @param code: The code we need to check.
      Checks if the code is correct.
    */

    String pattern = r'(^[0-9]{6}$)';

    if (code == null || code.isEmpty) {
      return "Ce champs est obligatoire.";
    }

    if (!RegExp(pattern).hasMatch(code)) {
      return "Format incorrect";
    }

    if (_verificationResponse != null) {
      if (_verificationResponse["isCodeValid"] == false) {
        return "Code erroné.";
      } else if (_verificationResponse["isCodeExpired"] == true) {
        return "Code expiré.";
      }
    }

    return null;
  }

  Future<dynamic> _verifyRegistration(token, code) async {
    /*
      @param token: The token of the registration (equivalent to an ID).
      @param code: The code we need to check.
      This asynchronous function checks that the code entered is valid
      and not expired.
    */

    final response = await http.post(
        Uri.parse("${Env.urlPrefix}/verify_registration.php"),
        body: {"token": token, "verification_code": code});

    var data = json.decode(response.body);

    return data;
  }

  Future<void> _getToken() async {
    /*
      This asynchronous function get the value of 
      the stored token.
    */

    final prefs = await SharedPreferences.getInstance();
    final tokenValue = prefs.getString('token');

    setState(() {
      _token = tokenValue ?? "";
    });
  }

  Future<void> _setIsLoggedIn() async {
    /*
      This asynchronous function store the state of the user in the
      shared preferences.
    */

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  @override
  void initState() {
    _getToken();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: _key,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: "Code de vérification.",
                    ),
                    validator: _validateCode,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20.0),
                  child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          // If the code is not in the good format, don't send
                          // API calls.
                          if (!_isGoodFormat(codeController.text)) {
                            _key.currentState!.validate();
                          } else {
                            dynamic data;

                            _verifyRegistration(_token, codeController.text)
                                .then((value) {
                              data = value;

                              setState(() {
                                _verificationResponse = data;
                              });

                              if (_key.currentState!.validate()) {
                                // Set the user state to "logged in".
                                _setIsLoggedIn();
                                // Go to the calendar page, and prevent the user
                                // from going back.
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DynamicWeekView()),
                                    (_) => false);
                                //
                              }
                            });
                          }
                        },
                        child: const Text('Continuer'),
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder()),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
  }
}
*/
