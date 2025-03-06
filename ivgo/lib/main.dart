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

//TODO - Add a list of StopwatchTimers to the StopwatchListPage
//TODO - Add a way to add new StopwatchTimers to the list
//TODO - Add a way to remove StopwatchTimers from the list
//TODO - Add a way to start, stop, and reset each StopwatchTimer
//TODO - Add a way to reorder the StopwatchTimers in the list
//TODO - Add Cupertino support for iOS devices
//TODO - Add a way to save the list of StopwatchTimers to local storage
//TODO - Add a way to load the list of StopwatchTimers from local storage
//TODO - Add a way to clear the list of StopwatchTimers from local storage
//TODO - Add a way to share the list of StopwatchTimers with others
//TODO - Add a way to import a list of StopwatchTimers from others
//TODO - Add a way to export a list of StopwatchTimers to others
//TODO - Add a way to change the theme of the app (light/dark mode)
//TODO - Add a way to change the language of the app
//TODO - Add adverts and sponsorship to the app
//TODO - Add analytics and crash reporting to the app