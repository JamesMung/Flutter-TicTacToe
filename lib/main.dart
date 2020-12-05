import 'package:flutter/material.dart';
import 'LoginPage.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tic Tac Toe",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFEAF0F1),
      ),
      home: LoginPage(),
    );
  }
}

void main() => runApp(MyApp());