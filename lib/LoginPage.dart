import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:tic_tac_toe/HomePage.dart';
import 'package:tic_tac_toe/model/Player.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final loginUrl = "http://webhelpme.com:8090/api/Login/LoginUser";

  final _formKey = GlobalKey<FormState>();
  String _username;
  String _password;

  Future<Player> _processLogin() async {
    final response = await http.post(loginUrl,
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'username': _username,
          'password': _password
        }));

    var json = jsonDecode(response.body);
    if(json['success'] == true) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(_username),
              maintainState: false));
      return Player.parseForm(json);
    } else {
      showAlertDialog(context);
    }
  }

  showAlertDialog(BuildContext context) {
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Login Failed"),
      content: Text("Incorrect username or password."),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('TicTacToe'),
        ),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(10),
                      child: TextFormField(
                        onSaved: (value) => _username = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Username should not be empty';
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: TextFormField(
                        obscureText: true,
                        onSaved: (value) => _password = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Password should not be empty';
                          return null;
                        },
                      ),
                    ),
                    Container(
                        height: 50,
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: RaisedButton(
                          textColor: Colors.white,
                          color: Colors.blue,
                          child: Text('Login'),
                          onPressed: () {
                            final form = _formKey.currentState;

                            if (form.validate()) {
                              form.save();

                              _processLogin();
                            }
                          },
                        ))
                  ],
                ))));
  }
}
