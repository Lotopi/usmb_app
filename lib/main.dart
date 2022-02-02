import 'package:flutter/material.dart';

import 'package:flutter_week_view/flutter_week_view.dart';

import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(_MyApp());


class _MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

/// The demo material app.
class _MyAppState extends State<_MyApp> {

  final List<String> listItem = ["Aucune"];
  String valueChoose = "Aucune";

  String selectedClass = "Aucune";

  var _dropDownItems;

  Future<void> _getGroups() async {
    /*
      This is an asynchronous function used to load the groups from a JSON file.
    */

    final String response = await rootBundle.loadString('assets/calendar.JSON');
    final data = await json.decode(response);

    setState(() {
      _dropDownItems = data["classes"];
    });
    
    for (var i = 0; i < _dropDownItems.length; i++) {
      String key = _dropDownItems.keys.elementAt(i);

      setState(() {
        listItem.add(key);
      });
    }
  }

  Future<void> _getStringFromSharedPref() async {
    /*
      This asynchronous function get the value of 
      the selected class.
    */
    final prefs = await SharedPreferences.getInstance();
    final storedSelectedClass = prefs.getString('selectedClass');

    setState(() {
      selectedClass = storedSelectedClass ?? "Aucune";
      valueChoose = selectedClass;
    });
  }

  // A boolean that will prevent multiple loading of the same data.
  var dropDownItemmsAreLoaded = false;

  @override
  Widget build(BuildContext context) {

    // Load the events if needed.
    if (!dropDownItemmsAreLoaded) {
      _getGroups().then((_) => _getStringFromSharedPref());
      dropDownItemmsAreLoaded = true;
    }

    return MaterialApp(
        title: 'Emploi du temps',
        initialRoute: '/',
        routes: {
          '/': (context) => inScaffold(body: _DynamicWeekView())
        },
      );
  }

  Future<void> _changeSelectedClass(newSelectedClass) async {
    /*
      This asynchronous function store the newly selected value in
      shared preferences.
    */

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('selectedClass', newSelectedClass);
  }

  Widget inScaffold({
    String title = 'Emploi du temps',
    required Widget body,
  }) =>
      Scaffold(
        appBar: AppBar(
          actions: [
            DropdownButton<String>(
              value: valueChoose,
              onChanged: (newValue) {
                setState(() {
                  valueChoose = newValue as String;
                  //selectedClass = valueChoose;
                  //_changeSelectedClass(valueChoose);
                });

                _changeSelectedClass(valueChoose);
              },
              items: listItem.map((valueItem) {
                return DropdownMenuItem(
                  value: valueItem,
                  child: SizedBox(
                    child: Text(valueItem),
                    width: 100,
                  ),//Text(valueItem),
                );
              }).toList(),
              )
          ],
          title: Text(title),
        ),
        body: body,
      );
}

/// A week view that displays dynamically added events.
class _DynamicWeekView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DynamicWeekViewState();
}

/// The dynamic week view state.
class _DynamicWeekViewState extends State<_DynamicWeekView> {

  String selectedClass = "";

  Future<void> _getStringFromSharedPref() async {
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

  Future<void> _getActualStringFromSharedPref() async {
    /*
      This asynchronous function get the actual value of 
      the selected class. 
      { Used for comparison }
    */

    final prefs = await SharedPreferences.getInstance();
    final storedSelectedClass = prefs.getString('selectedClass');

    setState(() {
      actualSelectedClass = storedSelectedClass ?? "Aucune";
    });
  }

  List _items = [];
  List<FlutterWeekViewEvent> events = [];

  Future<void> _getEvents() async {
    /*
      This asynchronous function load the events from a JSON file.
    */

    final String response = await rootBundle.loadString('assets/calendar.JSON');
    final data = await json.decode(response);

    setState(() {
      /* Try to load the selected class, if something goes wrong
         it will fail back onto the default class. */
      try {
        _items = data["classes"][selectedClass];
      }
      catch(e) {
        _items = data["classes"]["Aucune"];
      }
    });
    
    for (var i = 0; i < _items.length; i++) {
      final DateTime startDate = DateTime.parse(_items[i]['DTSTART']);
      final DateTime endDate = DateTime.parse(_items[i]['DTEND']);

      final event = 
        FlutterWeekViewEvent(
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
    setState(() {
      events = [];
      _getEvents();
    });
  }

  // A boolean that will prevent multiple loading of the same data.
  var eventsAreLoaded = false;

  var actualSelectedClass = "Aucune";

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    // Load the events if needed.
    if (!eventsAreLoaded) {
      _getStringFromSharedPref().then((_) {
        print(selectedClass);
        _getEvents();
      });
      
      eventsAreLoaded = true;
    }

    // Check if the selected class was changed, if true, will reload the events.
    _getActualStringFromSharedPref().then((value) => 
      {
        if (selectedClass != actualSelectedClass) {
          _reloadEvents()
        }
      }
    );
    

    List<DateTime> getDaysInBeteween(DateTime startDate, DateTime endDate) {
      /*
        Return the list of all dates between two given dates.

        Parameters:
          - startDate: The start date.
          - endDate: The end date.
      */

      List<DateTime> days = [];
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        days.add(
          DateTime(
            startDate.year, 
            startDate.month,
            startDate.day + i)
        );
      }
        return days;
    }

    // The list of dates that the calendar must display.
    List<DateTime> dates = [];

    // Get the dates for the current school year.
    if (now.month < 07) {
      dates = getDaysInBeteween(DateTime(now.year - 1, 08, 30), DateTime(now.year, 07, 01));
    } else {
      dates = getDaysInBeteween(DateTime(now.year, 08, 01), DateTime(now.year + 1, 07, 01)); 
    }

    // This is the function used to customize the style of a day.
    DayViewStyle setDayViewStyle(DateTime date) => const DayViewStyle(hourRowHeight: 60 * 2);

    return WeekView(
      initialTime: const HourMinute(hour: 6, minute: 31).atDate(DateTime.now()),
      minimumTime: const HourMinute(hour: 6, minute: 30),
      maximumTime: const HourMinute(hour: 21),
      hoursColumnStyle: const HoursColumnStyle(
        interval: Duration(minutes: 30),
      ),
      userZoomable: false,
      dates: dates,
      dayViewStyleBuilder: setDayViewStyle,
      events: events,
    );
  }
}
