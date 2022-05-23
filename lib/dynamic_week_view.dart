import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_week_view/flutter_week_view.dart';

import 'package:http/http.dart' as http;
import 'package:usmb_app/class_selection_page.dart';

import '../env.dart';

/// A week view that displays dynamically added events.
class DynamicWeekView extends StatefulWidget {
  const DynamicWeekView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DynamicWeekViewState();
}

/// The dynamic week view state.
class DynamicWeekViewState extends State<DynamicWeekView> {
  String selectedClass = "Aucune";

  String selectedCampus = "";

  String calendarHash = "";

  String listClassesHash = "";

  /// The variable used to store the token.
  String _token = "";

  /// Secure storage
  final _storage = const FlutterSecureStorage();

  /// Gets the value of the stored class.
  Future<String> _getSelectedClassFromSharedPref() async {
    String storedSelectedClass =
        await _storage.read(key: 'selectedClass') ?? 'Aucune';

    setState(() {
      selectedClass = storedSelectedClass;
    });

    return storedSelectedClass;
  }

  /// Gets the value of the stored campus.
  Future<void> _getSelectedCampusFromSharedPref() async {
    String storedSelectedCampus = await _storage.read(key: 'campus') ?? '';

    setState(() {
      selectedCampus = storedSelectedCampus;
    });
  }

  /// Gets the hash of the stored class.
  Future<void> _getCalendarHashFromSharedPref() async {
    String storedCalendarHash = await _storage.read(key: 'calendarHash') ?? '';

    setState(() {
      calendarHash = storedCalendarHash;
    });
  }

  /// Downloads the [calendarData] and stores it in a secure storage, along
  /// with its [calendarHash].
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

        await _storage.write(
            key: 'calendarData', value: jsonEncode(calendarData));
        await _storage.write(key: 'calendarHash', value: calendarHash);
      }
    }

    return isSuccess;
  }

  /// Loads the events stored in a secure storage.
  Future<void> _loadCalendarData() async {
    String calendarDataRaw = await _storage.read(key: 'calendarData') ?? '{}';

    dynamic calendarData = jsonDecode(calendarDataRaw);

    List _items = [];

    setState(() {
      /* Try to load the selected class, if something goes wrong
         it will fail back onto an empty list. */

      try {
        _items = calendarData;
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

  /// Reloads the list of events to display.
  Future<bool> _reloadEvents() async {
    bool res = false;

    bool isDownloadCalendarDataSuccess = false;

    try {
      isDownloadCalendarDataSuccess = await _downloadCalendarData();
    } on SocketException catch (_) {
      Fluttertoast.showToast(msg: "Aucune connexion.");
    }

    if (isDownloadCalendarDataSuccess) {
      setState(() {
        events = [];
      });

      await _loadCalendarData();

      res = true;
    }

    _getSelectedClassFromSharedPref();

    return res;
  }

  /// Returns the list of all dates between [startDate] and [endDate].
  List<DateTime> _getDaysInBetween(DateTime startDate, DateTime endDate) {
    List<DateTime> days = [];
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(DateTime(startDate.year, startDate.month, startDate.day + i));
    }
    return days;
  }

  /// Gets the dates for the current school year.
  void _getDatesOfCurrentSchoolYear() {
    DateTime now = DateTime.now();

    if (now.month < 07) {
      dates = _getDaysInBetween(
          DateTime(now.year - 1, 08, 30), DateTime(now.year, 07, 01));
    } else {
      dates = _getDaysInBetween(
          DateTime(now.year, 08, 01), DateTime(now.year + 1, 07, 01));
    }
  }

  /// Gets the value of the stored token.
  Future<void> _getToken() async {
    String tokenValue = await _storage.read(key: 'token') ?? '';

    setState(() {
      _token = tokenValue;
    });
  }

  /// Customizes the style of a day.
  DayViewStyle _setDayViewStyle(DateTime date) =>
      const DayViewStyle(hourRowHeight: 60 * 2);

  /// The list of events that the calendar must display.
  List<FlutterWeekViewEvent> events = [];

  /// The list of dates that the calendar must display.
  List<DateTime> dates = [];

  @override
  void initState() {
    _getToken().then((_) {
      _getSelectedClassFromSharedPref().then((_) {
        _loadCalendarData();
      });
    });

    _getSelectedCampusFromSharedPref();

    _getCalendarHashFromSharedPref();

    _getDatesOfCurrentSchoolYear();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: SizedBox(
                  width: 150,
                  child: FutureBuilder<String>(
                      future: _getSelectedClassFromSharedPref(),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (!snapshot.hasData) {
                          return TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ClassSelection()));
                            },
                            child: const Text(
                              "Chargement...",
                              style: TextStyle(
                                fontSize: 20.0,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        }
                        return TextButton(
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                          ),
                          child: Text(
                            snapshot.data ?? "Aucune",
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20.0,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ClassSelection()));
                          },
                        );
                      })))
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
            _reloadEvents().then((res) {
              if (res) {
                Fluttertoast.showToast(msg: "Données mise à jour.");
              } else {
                Fluttertoast.showToast(msg: "Une erreur est survenue.");
              }
            });
          }),
    );
  }
}
