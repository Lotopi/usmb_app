import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/services.dart';

import 'package:flutter_week_view/flutter_week_view.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import '../env.dart';

/// A week view that displays dynamically added events.
class DynamicWeekView extends StatefulWidget {
  const DynamicWeekView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DynamicWeekViewState();
}

/// The dynamic week view state.
class DynamicWeekViewState extends State<DynamicWeekView> {
  List<String> listItem = ["Aucune"];

  String valueChoose = "Aucune";

  String selectedClass = "Aucune";

  String selectedClassHash = "";

  String listClassesHash = "";

  dynamic _calendarData;

  dynamic _dropDownItems;

  // This variable will be used to store the token.
  String _token = "";

  Future<void> _downloadListClasses() async {
    /*
      This is an asynchronous function used to download the list of classes from
      the server.
    */

    final response = await http.post(
        Uri.parse("${Env.urlPrefix}/get_list_classes.php"),
        body: {"token": _token, "hash": listClassesHash});

    var data = json.decode(response.body);

    bool isSuccess = data["isSuccess"];

    if (isSuccess) {
      bool needUpdate = data["needUpdate"];

      if (needUpdate) {
        setState(() {
          listClassesHash = data["classes_data"]["hash"];
          _dropDownItems = data["classes_data"]["data"];
        });
      }
    } else {
      print(data);
    }
  }

  /// Loads the list of classes and put them in [listItem], used later for a
  /// dropdown.
  void _loadListClasses() {
    setState(() {
      listItem = ["Aucune"];
    });
    for (var i = 0; i < _dropDownItems.length; i++) {
      setState(() {
        listItem.add(_dropDownItems[i]);
      });
    }
  }

  Future<void> _getSelectedClassFromSharedPref() async {
    /*
      This asynchronous function get the value of 
      the selected class.
    */

    final prefs = await SharedPreferences.getInstance();
    final storedSelectedClass = prefs.getString('selectedClass');

    setState(() {
      selectedClass = storedSelectedClass ?? "Aucune";
    });
  }

  Future<void> _changeSelectedClass(newSelectedClass) async {
    /*
      This asynchronous function store the newly selected value in
      shared preferences.
    */

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedClass', newSelectedClass);

    setState(() {
      selectedClass = newSelectedClass;
    });
  }

  Future<bool> _downloadCalendarData() async {
    final response = await http
        .post(Uri.parse("${Env.urlPrefix}/get_calendar.php"), body: {
      "token": _token,
      "class": selectedClass,
      "hash": selectedClassHash
    });

    var data = json.decode(response.body);

    bool isSuccess = data["isSuccess"];

    if (isSuccess) {
      bool needUpdate = data["needUpdate"];

      if (needUpdate) {
        setState(() {
          selectedClassHash = data["calendar_data"]["hash"];
          _calendarData = data["calendar_data"]["data"];
        });
      }
    } else {
      print(data);
    }

    return isSuccess;
  }

  Future<void> _loadCalendarData() async {
    /*
      This asynchronous function load the events stored in shared preferences.
    */

    List _items = [];

    setState(() {
      /* Try to load the selected class, if something goes wrong
         it will fail back onto an empty list. */
      try {
        _items = _calendarData;
      } catch (e) {
        _items = [];
      }

      //events = [];
    });

    //print("items :");
    //print(_items);

    for (var i = 0; i < _items.length; i++) {
      final DateTime startDate = DateTime.parse(_items[i]['DTSTART']).toLocal();
      final DateTime endDate = DateTime.parse(_items[i]['DTEND']).toLocal();

      final event = FlutterWeekViewEvent(
        title: '${_items[i]['SUMMARY']}',
        description: '${_items[i]['LOCATION']} \n\n${_items[i]['DESCRIPTION']}',
        start: startDate,
        end: endDate,
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(12),
        ),
      );

      setState(() {
        events.add(event);
      });
    }
  }

  Future<void> _reloadEvents() async {
    /*
      Reload the list of events to display.
    */

    setState(() {
      events = [];
      _downloadCalendarData().then((_) {
        _loadCalendarData();
      });
      _getSelectedClassFromSharedPref();
    });
  }

  List<DateTime> _getDaysInBetween(DateTime startDate, DateTime endDate) {
    /*
      Return the list of all dates between two given dates.
      Parameters:
        - startDate: The start date.
        - endDate: The end date.
    */

    List<DateTime> days = [];
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(DateTime(startDate.year, startDate.month, startDate.day + i));
    }
    return days;
  }

  void _getDatesOfCurrentSchoolYear() {
    /*
      Get the dates for the current school year.
    */
    DateTime now = DateTime.now();

    if (now.month < 07) {
      dates = _getDaysInBetween(
          DateTime(now.year - 1, 08, 30), DateTime(now.year, 07, 01));
    } else {
      dates = _getDaysInBetween(
          DateTime(now.year, 08, 01), DateTime(now.year + 1, 07, 01));
    }
  }

  Future<void> _getToken() async {
    /*
      This asynchronous function get the value of the stored token.
    */

    final prefs = await SharedPreferences.getInstance();
    final tokenValue = prefs.getString('token');

    setState(() {
      _token = tokenValue ?? "";
    });
  }

  // This is the function used to customize the style of a day.
  DayViewStyle _setDayViewStyle(DateTime date) =>
      const DayViewStyle(hourRowHeight: 60 * 2);

  // The list of events that the calendar must display.
  List<FlutterWeekViewEvent> events = [];

  // The list of dates that the calendar must display.
  List<DateTime> dates = [];

  @override
  void initState() {
    _getToken().then((_) {
      _getSelectedClassFromSharedPref().then((_) {
        _downloadCalendarData().then((_) {
          _loadCalendarData();
        });
      });

      _downloadListClasses().then((_) {
        _loadListClasses();
        _getSelectedClassFromSharedPref()
            .then((_) => valueChoose = selectedClass);
      });
    });

    _getDatesOfCurrentSchoolYear();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          DropdownButton<String>(
            value: valueChoose,
            onChanged: (newValue) {
              setState(() {
                valueChoose = newValue as String;
              });

              // If this is a different value than before, then we update the
              // data.
              if (valueChoose != selectedClass) {
                _changeSelectedClass(valueChoose).then((_) {
                  _reloadEvents();
                });
              }
            },
            items: listItem.map((valueItem) {
              return DropdownMenuItem(
                value: valueItem,
                child: SizedBox(
                  child: Text(valueItem),
                  width: 100,
                ),
              );
            }).toList(),
          )
        ],
        title: const Text("Emploi du temps"),
      ),
      body: WeekView(
        initialTime:
            const HourMinute(hour: 6, minute: 31).atDate(DateTime.now()),
        minimumTime: const HourMinute(hour: 6, minute: 30),
        maximumTime: const HourMinute(hour: 21),
        hoursColumnStyle: const HoursColumnStyle(
          interval: Duration(minutes: 30),
        ),
        userZoomable: false,
        dates: dates,
        dayViewStyleBuilder: _setDayViewStyle,
        events: events,
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(
            Icons.refresh,
          ),
          onPressed: () {
            _downloadListClasses().then((_) {
              _loadListClasses();

              // If the previously selected class is no longer available, then
              // we must inform the user, and fall back to the default null
              // class, "Aucune".
              if (listItem.contains(selectedClass)) {
                _reloadEvents().then((_) {
                  Fluttertoast.showToast(msg: "Données mise à jour.");
                });
              } else {
                _changeSelectedClass("Aucune").then((_) {
                  _reloadEvents().then((_) {
                    Fluttertoast.showToast(msg: "Données mise à jour.");
                    Fluttertoast.showToast(
                        msg:
                            "La classe précédemment sélectionnée n'est plus disponible.");
                  });
                });
              }
            });
          }),
    );
  }
}
