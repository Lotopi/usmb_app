import 'package:flutter/material.dart';

import 'package:flutter_week_view/flutter_week_view.dart';

import 'package:flutter/services.dart';

import 'dart:convert';

void main() => runApp(_MyApp());

/// The demo material app.
class _MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Emploi du temps',
        initialRoute: '/',
        routes: {
          '/': (context) => inScaffold(body: _DynamicWeekView())
        },
      );

  static Widget inScaffold({
    String title = 'Emploi du temps',
    required Widget body,
  }) =>
      Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: body,
      );
}

/// A day view that displays dynamically added events.
class _DynamicWeekView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DynamicWeekViewState();
}

/// The dynamic day view state.
class _DynamicWeekViewState extends State<_DynamicWeekView> {

  List _items = [];
  List<FlutterWeekViewEvent> events = [];

  Future<void> _getEvents() async {
    /*
      This is an asynchronous function used to load the events from a JSON file.
    */

    final String response = await rootBundle.loadString('assets/calendar.JSON');
    final data = await json.decode(response);

    setState(() {
      _items = data["classes"]["L2-S3-INFO-1"];
    });
    
    for (var i = 0; i < _items.length; i++) {
      final DateTime startDate = DateTime.parse(_items[i]['DTSTART']);
      final DateTime endDate = DateTime.parse(_items[i]['DTEND']);

      final event = 
        FlutterWeekViewEvent(
          title: '${_items[i]['SUMMARY']}',
          description: '${_items[i]['LOCATION']} \n${_items[i]['DESCRIPTION']}',
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

  // A boolean that will prevent multiple loading of the same data.
  var eventsAreLoaded = false;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    // Load the events if needed.
    if (!eventsAreLoaded) {
      _getEvents();
      eventsAreLoaded = true;
    }

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
    DayViewStyle funcTest(DateTime date) => const DayViewStyle(hourRowHeight: 60 * 2);

    return WeekView(
      initialTime: const HourMinute(hour: 6, minute: 31).atDate(DateTime.now()),
      minimumTime: const HourMinute(hour: 6, minute: 30),
      maximumTime: const HourMinute(hour: 21),
      hoursColumnStyle: const HoursColumnStyle(
        interval: Duration(minutes: 30),
      ),
      userZoomable: false,
      dates: dates,
      dayViewStyleBuilder: funcTest,
      events: events,
    );
  }
}
