import 'package:flutter/material.dart';

import 'package:app/gestureList.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {   // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestice League',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: HomePage(title: 'Superpowers'),
    );
  }
}

class HomePage extends StatefulWidget { 
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/*
  Needs to take in a list of mini widgets, each representing a gesture.
  Gesture list to map!
*/
class _MyHomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    return Scaffold(
      appBar: AppBar( // MyHomePage object in App.build 's title ...?
        title: Text(widget.title),
      ),
      body: Center( //layout, 1-child, places in middle
        child: Column( //list of children vertically, fills parent, 
          mainAxisAlignment: MainAxisAlignment.center, //mainAxis here is vertical axis, cross is hori
          children: <Widget>[
            GestureItem( 
              false,
              false,
              "5 mins",
              "Telekineseis"
            ),
            GestureItem( 
              true,
              true,
              "15 mins",
              "Woohoo!"
            ),
            GestureItem( 
              false,
              false,
              "0 mins",
              "New Superpower"
            ),
          ],
        ),
      ),
    );
  }
}
