import 'package:flutter/material.dart';
import 'package:app/homePage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {   // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestice League',
      theme: ThemeData(
        //primarySwatch: Colors.grey,
        primaryColor: Colors.black,
        accentColor: Colors.amber[400],
        canvasColor: Colors.grey[100],
        cardColor: Colors.grey[600],
      ),
      home: HomePage(title: 'Superpowers'),
    );
  }
}