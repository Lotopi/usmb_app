import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_week_view/flutter_week_view.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// A week view that displays dynamically added events.
class DynamicWeekView extends StatefulWidget {
  const DynamicWeekView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DynamicWeekViewState();
}

/// The dynamic week view state.
class DynamicWeekViewState extends State<DynamicWeekView> {
  final List<String> listItem = ["Aucune"];
  String valueChoose = "Aucune";

  String selectedClass = "Aucune";

  dynamic _dropDownItems;

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
  }

  Future<void> _getEvents() async {
    /*
      This asynchronous function load the events from a JSON file.
    */

    List _items = [];

    final String response = await rootBundle.loadString('assets/calendar.JSON');
    final data = await json.decode(response);

    setState(() {
      /* Try to load the selected class, if something goes wrong
         it will fail back onto an empty list. */
      try {
        _items = data["classes"][selectedClass];
      } catch (e) {
        _items = [];
      }
    });
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
      _getEvents();
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

  // This is the function used to customize the style of a day.
  DayViewStyle _setDayViewStyle(DateTime date) =>
      const DayViewStyle(hourRowHeight: 60 * 2);

  // The list of events that the calendar must display.
  List<FlutterWeekViewEvent> events = [];

  // The list of dates that the calendar must display.
  List<DateTime> dates = [];

  @override
  void initState() {
    _getSelectedClassFromSharedPref().then((_) {
      _getEvents();
    });

    _getDatesOfCurrentSchoolYear();

    _getGroups().then((_) => _getSelectedClassFromSharedPref()
        .then((_) => valueChoose = selectedClass));

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
              _changeSelectedClass(valueChoose);
              _reloadEvents();
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
    );
  }
}
