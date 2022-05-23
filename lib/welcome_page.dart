import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:usmb_app/verification_page.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import '../env.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  // This variable will be used to store the response of the server.
  dynamic _registerResponse;

  // The text field controller, used to get it's value.
  TextEditingController emailController = TextEditingController();

  /// Secure storage
  final _storage = const FlutterSecureStorage();

  /// Checks if the [email] format is correct.
  bool _isGoodFormat(String email) {
    bool res = false;

    // The two possible regex patterns of an email.
    String patternOne = r'(^[a-zA-Z0-9_.+-]+@etu\.univ-smb\.fr)';
    String patternTwo = r'(^[a-zA-Z0-9_.+-]+@univ-smb\.fr)';

    if (RegExp(patternOne).hasMatch(email) ||
        RegExp(patternTwo).hasMatch(email)) {
      res = true;
    }

    return res;
  }

  /// Checks if the [email] is correct, validates if it is.
  String? _validateEmail(String? email) {
    String patternOne = r'(^[a-zA-Z0-9_.+-]+@etu\.univ-smb\.fr$)';
    String patternTwo = r'(^[a-zA-Z0-9_.+-]+@univ-smb\.fr$)';

    if (email == null || email.isEmpty) {
      return "Ce champs est obligatoire.";
    }

    if (!(RegExp(patternOne).hasMatch(email) ||
        RegExp(patternTwo).hasMatch(email))) {
      return "Adresse incorrecte";
    }

    if (_registerResponse != null) {
      if (_registerResponse["isSuccess"] == false) {
        return "Une erreur est survenue.";
      }
    }

    return null;
  }

  /// Sends the email to the API for verification.
  Future<dynamic> _register(email) async {
    final response = await http.post(Uri.parse("${Env.urlPrefix}/register.php"),
        body: {"email": email});

    var data = json.decode(response.body);

    return data;
  }

  /// Saves the newly created token in a secure storage.
  Future<void> _saveToken(token) async {
    await _storage.write(key: 'token', value: token);
  }

  Widget buildAvertissement() => RichText(
        textAlign: TextAlign.justify,
        text: const TextSpan(
          children: [
            TextSpan(
                text: 'Avertissement :',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    decoration: TextDecoration.underline)),
            TextSpan(
                text:
                    " cette application n'est en rien affiliée à l'Université Savoie Mont Blanc (USMB),",
                style: TextStyle(color: Colors.black, fontSize: 16)),
            TextSpan(
                text:
                    " par ailleurs, celle-ci est encore en phase de développement,",
                style: TextStyle(color: Colors.black, fontSize: 16)),
            TextSpan(
                text:
                    " elle ne peut pas être considérée comme fiable, divers problèmes pouvant encore survenir.",
                style: TextStyle(color: Colors.black, fontSize: 16))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("USMB App")),
        body: Form(
          key: _key,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: SizedBox(width: 350, child: buildAvertissement())),
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Adresse éléctronique universitaire.",
                    ),
                    validator: _validateEmail,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20.0),
                  child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          // If the email is not in the good format, don't send API calls.
                          if (!_isGoodFormat(emailController.text)) {
                            _key.currentState!.validate();
                          } else {
                            dynamic data;
                            _register(emailController.text).then((value) {
                              data = value;

                              setState(() {
                                _registerResponse = data;
                              });

                              if (_key.currentState!.validate()) {
                                // Save the token in shared preferences.
                                _saveToken(data["token"]).then((_) =>
                                    // Go to verification page.
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                VerificationPage(
                                                    email: emailController
                                                        .text))));
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
