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
      home: const StopwatchListPage(title: 'Active Stopwatches'),
    );
  }
}