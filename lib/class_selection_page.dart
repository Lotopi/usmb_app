import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:usmb_app/dynamic_week_view.dart';

import 'dart:convert';

import '../env.dart';

class ClassSelection extends StatefulWidget {
  const ClassSelection({Key? key}) : super(key: key);

  @override
  _ClassSelectionState createState() => _ClassSelectionState();
}

class _ClassSelectionState extends State<ClassSelection> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final _userEditTextController = TextEditingController();
  final _dropDownSearchClassKey = GlobalKey<DropdownSearchState<String>>();

  String _token = "";

  String selectedClass = "";

  String selectedClassHash = "";

  String listClassesHash = "";

  String selectedCampus = "";

  List<String> listItems = [];

  dynamic _classesDropDownItems;

  /// Secure storage
  final _storage = const FlutterSecureStorage();

  /// The list of all the USMB campuses.
  final List<String> _campusList = [
    "Annecy",
    "Bourget-du-Lac",
    "Jacob-Bellecombette"
  ];

  /// Gets the value of the stored token.
  Future<void> _getToken() async {
    String tokenValue = await _storage.read(key: 'token') ?? '';

    setState(() {
      _token = tokenValue;
    });
  }

  /// Downloads the list of classes from the server for a given [campus].
  Future<bool> _downloadListClasses() async {
    final response = await http
        .post(Uri.parse("${Env.urlPrefix}/get_list_classes.php"), body: {
      "token": _token,
      "campus": selectedCampus.split('-')[0], // We only need the first word.
      "hash": listClassesHash
    });

    var data = json.decode(response.body);

    bool isSuccess = data["isSuccess"];

    if (isSuccess) {
      bool needUpdate = data["needUpdate"];

      if (needUpdate) {
        setState(() {
          listClassesHash = data["classes_data"]["hash"];
          _classesDropDownItems = data["classes_data"]["data"];
        });
      }
    }

    return isSuccess;
  }

  /// Loads the list of classes and put them in [_classesDropDownItems],
  /// used later for a dropdown.
  void _loadListClasses() {
    setState(() {
      listItems = [];
    });

    for (var i = 0; i < _classesDropDownItems.length; i++) {
      setState(() {
        listItems.add(_classesDropDownItems[i]);
      });
    }

    setState(() {
      listItems.sort();
    });
  }

  /// Downloads the [calendarData] and stores it in a secure storage, along
  /// with its [calendarHash] and the [selectedClass].
  Future<bool> _downloadCalendarData() async {
    String calendarHash = await _storage.read(key: 'calendarHash') ?? '';

    final response =
        await http.post(Uri.parse("${Env.urlPrefix}/get_calendar.php"), body: {
      "token": _token,
      "campus": selectedCampus.split('-')[0], // We only need the first word.
      "class": selectedClass,
      "hash": calendarHash
    });

    var data = json.decode(response.body);

    bool isSuccess = data["isSuccess"];

    if (isSuccess) {
      bool needUpdate = data["needUpdate"];

      if (needUpdate) {
        dynamic calendarData = data["calendar_data"]["data"];
        dynamic calendarHash = data["calendar_data"]["hash"];

        await _storage.write(key: 'selectedClass', value: selectedClass);
        await _storage.write(
            key: 'calendarData', value: jsonEncode(calendarData));
        await _storage.write(key: 'calendarHash', value: calendarHash);
      }

      await _storage.write(key: 'campus', value: selectedCampus);
    }

    return isSuccess;
  }

  /// Updates the listOfClasses.
  ///
  /// Informs the user in case of an error.
  Future<void> _updateListOfClasses() async {
    try {
      await _downloadListClasses();
      _loadListClasses();
    } on SocketException catch (_) {
      Fluttertoast.showToast(msg: "Aucune connexion.");
    }
  }

  /// Updates the calendar.
  ///
  /// Informs the user in case of an error.
  Future<bool> _updateCalendar() async {
    bool isSuccess = false;

    try {
      await _downloadCalendarData();
      isSuccess = true;
    } on SocketException catch (_) {
      Fluttertoast.showToast(msg: "Aucune connexion.");
    }

    return isSuccess;
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
        appBar: AppBar(
          title: const Text("Classes"),
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
            ),
          ),
        ),
        body: Form(
          key: _key,
          child: Center(
            child: SizedBox(
                width: 350,
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownSearch<String>(
                      mode: Mode.BOTTOM_SHEET,
                      validator: (v) => v == null ? "Champs requis." : null,
                      dropdownSearchDecoration: const InputDecoration(
                        hintText: "Sélectionnez un campus.",
                        contentPadding: EdgeInsets.fromLTRB(12, 12, 0, 0),
                        border: OutlineInputBorder(),
                      ),
                      showSelectedItems: true,
                      items: _campusList,
                      onChanged: (value) {
                        // Download the corresponding list of classes.
                        if (value != selectedCampus) {
                          setState(() {
                            selectedCampus = value ?? "";

                            // We reset the other dropdown.
                            _userEditTextController.clear();
                            _dropDownSearchClassKey.currentState?.clear();
                            listItems = [];
                          });
                        }
                        _updateListOfClasses();
                      },
                    ),
                    DropdownSearch<String>(
                      key: _dropDownSearchClassKey,
                      mode: Mode.BOTTOM_SHEET,
                      validator: (v) => v == null ? "Champs requis." : null,
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        controller: _userEditTextController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _userEditTextController.clear();
                            },
                          ),
                        ),
                      ),
                      searchDelay: const Duration(seconds: 0),
                      showClearButton: true,
                      dropdownSearchDecoration: const InputDecoration(
                        hintText: "Sélectionnez une classe.",
                        contentPadding: EdgeInsets.fromLTRB(12, 12, 0, 0),
                        border: OutlineInputBorder(),
                      ),
                      showSelectedItems: true,
                      items: listItems,
                      onChanged: (value) {
                        if (value != selectedClass) {
                          setState(() {
                            selectedClass = value ?? "";
                          });
                        }
                      },
                    ),
                    ElevatedButton(
                        onPressed: () {
                          if (selectedCampus != "" && selectedClass != "") {
                            _updateCalendar().then((isSuccess) {
                              if (isSuccess) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DynamicWeekView()),
                                    (_) => false);
                              }
                            });
                          } else {
                            Fluttertoast.showToast(
                                msg: "Erreur - Champs vide.");
                          }
                        },
                        child: const Text(
                          "Valider",
                          style: TextStyle(fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            fixedSize: const Size(250, 50))),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
