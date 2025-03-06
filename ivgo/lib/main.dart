import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ivgo/pages/stopwatch_list_page.dart';

void main() {
  runApp(const IVGoApp());
}

class IVGoApp extends StatelessWidget {
  const IVGoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IVGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Colors.lightBlue,
        ),
      ),
      home: const StopwatchListPage(title: 'Active Infusions'),
    );
  }
}

//TODO - Add a way to reorder the StopwatchTimers in the list based on remaining time
//TODO - Add a way to filter the StopwatchTimers in the list based on status (running/stopped)
//TODO - Add a way to search the StopwatchTimers in the list based on title
//TODO - Add a way to edit the StopwatchTimers in the list
//TODO - Add Cupertino support for iOS devices
//TODO - Add a way to save the list of StopwatchTimers to local storage
//TODO - Add a way to load the list of StopwatchTimers from local storage
//TODO - Add a way to clear the list of StopwatchTimers from local storage
//TODO - Add a way to change the theme of the app (light/dark mode)
//TODO - Add a way to change the language of the app
//TODO - Add adverts and sponsorship to the app
//TODO - Add a way to share the list of StopwatchTimers with others
//TODO - Add a way to import a list of StopwatchTimers from others
//TODO - Add a way to export a list of StopwatchTimers to others
//TODO - Add analytics and crash reporting to the app