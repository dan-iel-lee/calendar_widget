import 'package:flutter/material.dart';
import 'package:calendar_widget/calendar_widget.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar Widget Example',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Calendar Widget Example'),
        ),
        body: MyHomePage(),
      )
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CalendarHighlighter highlighter = (DateTime dt) {
      // randomly generate a boolean list of length monthLength + 1 (because months start at 1)
      return List.generate(Calendar.monthLength(dt) + 1, (index) {
        return (Random().nextDouble() < 0.3);
      });
    };

    return Container(
      margin: EdgeInsets.only(top: 16),
      alignment: Alignment.topCenter,
      child: Calendar(
        width: MediaQuery.of(context).size.width - 32,
        onTapListener: (DateTime dt) {
          final snackbar = SnackBar(content: Text('Clicked ${dt.month}/${dt.day}/${dt.year}!'),);
          Scaffold.of(context).showSnackBar(snackbar);
        },
        highlighter: highlighter,
      ),
    );
  }

}