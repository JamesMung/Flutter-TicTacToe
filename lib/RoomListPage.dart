import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tic_tac_toe/HomePage.dart';
import 'package:http/http.dart' as http;

import 'model/Room.dart';

class RoomListPage extends StatefulWidget {
  String username;

  RoomListPage(String username) {
    this.username = username;
  }

  @override
  RoomListPageState createState() => RoomListPageState(username);
}

class RoomListPageState extends State<RoomListPage> {
  String username;
  List<Room> roomList;

  RoomListPageState(String username) {
    this.username = username;
  }

  @override
  void initState() {
    getRoomList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: Text(
          "Room List",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF192A56),
      ),
      body: ListView.builder(
          itemCount: roomList == null ? 0 : roomList.length,
          itemBuilder: (con, ind) {
            return ListTile(
                title: Text('Room ${ind + 1}',
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                      con,
                      MaterialPageRoute(
                          builder: (cc) =>
                              HomePage(roomList[ind].roomId, username)));
                });
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 2.0,
        onPressed: (() => {createRoom()}),
      ),
    ));
  }

  createRoom() async {
    final response = await http.post(
        "http://webhelpme.com:8092/api/Login/CreateGameRoom",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({"username": username}));
    var json = jsonDecode(response.body);

    if (json == 1) {
      getRoomList();
    }
  }

  getRoomList() async {
    final response = await http.get(
        "http://webhelpme.com:8092/api/Login/GetGameRoomList",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        });
    List<dynamic> json = jsonDecode(response.body);

    setState(() {
      roomList = json.map((e) => Room.parseForm(e)).toList();
    });
  }
}
