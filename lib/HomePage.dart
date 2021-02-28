import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signalr_client/hub_connection_builder.dart';

class HomePage extends StatefulWidget {
  String playerName;
  var roomId;

  HomePage(roomId, String username) {
    this.playerName = username;
    this.roomId = roomId;
  }

  @override
  _HomePageState createState() => _HomePageState(roomId, playerName);
}

class _HomePageState extends State<HomePage> {
  var roomId;
  String playerName;
  String _p1;
  String _p2;

  int role;

  List memberList;

  _HomePageState(roomId, String playerName) {
    this.playerName = playerName;
    this.roomId = roomId;
  }

  //TODO: link up images
  AssetImage cross = AssetImage("images/cross.png");
  AssetImage circle = AssetImage("images/circle.png");
  AssetImage edit = AssetImage("images/edit.png");

  static final serverUrl = "http://18.163.80.77:8092/gamehub";
  String message;
  List<String> gameState;

  bool canMove = false;
  bool gameComplete = false;
  int status;

  var hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

  void _initSignalR() async {
    try {
      hubConnection.onclose((error) => print("Connection Closed"));
      await hubConnection.start();
      print("Connection established");

      //hubConnection.on("ReceiveRegistorMessage", (e) => { handleRegisterMsg(e[0], e[1])});
      hubConnection.on("SyncPlayRoomInfo",
          (e) => {getGameBoardInfo(e[0], e[1], e[2], e[3])});
      hubConnection.on(
          "ReceivePlayerList", (e) => {updatePlayerInRoom(jsonDecode(e[0]))});
      hubConnection
          .invoke("GetConnectionID", args: <Object>[playerName, roomId]);
    } catch (e) {
      showAlertDialog(context);
    }
  }

  void updatePlayerInRoom(List json) {
    setState(() {
      memberList = json.map((e) => e['UserName']).toList();
    });
  }

  void getGameBoardInfo(p1, p2, status, String trendString) {
    print("p1: " + p1 + ", p2: " + p2 + ", status: " + status + ", board: " + trendString);
    setState(() {
      _p1 = p1;
      _p2 = p2;

      if (role == null && _p1 == playerName) {
        role = 1;
      } else if (role == null && _p2 == playerName) {
        role = 2;
      }

      if(status == "WS") {
        if(role != null) {
          this.status = 1;
        } else if (_p1 == '' || _p2 == '') {
          this.status = 0;
        }
      }

      if(status == "W1" || status == "W2") {
        if (status == "W1" && role == 1) {
          canMove = true;
        } else if (status == "W2" && role == 2) {
          canMove = true;
        }

        if(role != null) {
          this.status = 2;
        } else if (_p1 != '' && _p2 != '') {
          this.status = 1;
        }
      }

      if(status == "E1" || status == "E2" || status == "DR") {
        canMove = false;
        gameComplete = true;
        renderGameBoard(trendString);
      }

      if(gameComplete) {
        Future.delayed(const Duration(milliseconds: 3000), () {
          renderGameBoard(trendString);
          gameComplete = false;
        });
      } else {
        renderGameBoard(trendString);
      }

    });
  }

  renderGameBoard(String trendString) {
    int idx = 0;
    trendString.split("").forEach((e) {
      int matchedRole = int.parse(e);

      switch (matchedRole) {
        case 0:
          this.gameState[idx++] = "empty";
          break;
        case 1:
          this.gameState[idx++] = "cross";
          break;
        case 2:
          this.gameState[idx++] = "circle";
          break;
      }
      checkWin();
    });
  }

  showAlertDialog(BuildContext context) {
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () => {Navigator.of(context, rootNavigator: true).pop()},
    );

    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Establish connection failed."),
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

  showMemberListDialog(BuildContext context) {
    hubConnection.invoke("GetPlayerList");

    Widget okButton = FlatButton(
      child: Text("Close"),
      onPressed: () => {Navigator.of(context, rootNavigator: true).pop()},
    );

    AlertDialog alert = AlertDialog(
      title: Text("Members"),
      content: Container(
          height: 300.0,
          width: 300.0,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: memberList.length,
              itemBuilder: (con, idx) {
                return ListTile(
                    title: Text('${memberList[idx]}',
                        style: TextStyle(color: Colors.black)));
              })),
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

  //TODO: initiazlie the state of box with empty
  @override
  void initState() {
    super.initState();
    this._p1 = '';
    this._p2 = '';
    this.status = 0;
    this.role = null;

    _initSignalR();
    setState(() {
      this.gameState = [
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
      ];
      this.message = "";
    });
  }

  registerPlayer() async {
    await hubConnection.invoke("RegisterPlayer", args: <Object>["R"]);
  }

  //TODO: playGame method
  playGame(int index) {
    if (canMove) {
      if (this.gameState[index] == "empty") {
        setState(() {
          if (role == 1) {
            this.gameState[index] = "cross";
          } else if (role == 2) {
            this.gameState[index] = "circle";
          }
          this.checkWin();
        });

        hubConnection.invoke("UpdateGameboard", args: <Object>[role, index]);
        canMove = false;
      }
    }
  }

  //TODO: Reset game method
  resetGame() {
    setState(() {
      this.gameState = [
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
        "empty",
      ];
      this.message = "";
    });
  }

  exitGame() async {
    await hubConnection.invoke("RegisterPlayer", args: <Object>["E"]);
    canMove = false;
    setState(() {
      status = 0;
      role = null;
    });
  }

  //TODO: get image method
  AssetImage getImage(String value) {
    switch (value) {
      case ('empty'):
        return edit;
        break;
      case ('cross'):
        return cross;
        break;
      case ('circle'):
        return circle;
        break;
    }
  }

  //Delay Effect
  Delay() async {
    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        this.resetGame();
      });
    });
    await hubConnection.invoke("UpdatePlayRoomInfo", args: <Object>[roomId]);
  }

  //TODO: check for win logic
  checkWin() {
    if ((gameState[0] != 'empty') &&
        (gameState[0] == gameState[1]) &&
        (gameState[1] == gameState[2])) {
      // if any user Win update the message state
      setState(() {
        this.message = '${this.gameState[0] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[3] != 'empty') &&
        (gameState[3] == gameState[4]) &&
        (gameState[4] == gameState[5])) {
      setState(() {
        this.message = '${this.gameState[3] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[6] != 'empty') &&
        (gameState[6] == gameState[7]) &&
        (gameState[7] == gameState[8])) {
      setState(() {
        this.message = '${this.gameState[6] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[0] != 'empty') &&
        (gameState[0] == gameState[3]) &&
        (gameState[3] == gameState[6])) {
      setState(() {
        this.message = '${this.gameState[0] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[1] != 'empty') &&
        (gameState[1] == gameState[4]) &&
        (gameState[4] == gameState[7])) {
      setState(() {
        this.message = '${this.gameState[1] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[2] != 'empty') &&
        (gameState[2] == gameState[5]) &&
        (gameState[5] == gameState[8])) {
      setState(() {
        this.message = '${this.gameState[2] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[0] != 'empty') &&
        (gameState[0] == gameState[4]) &&
        (gameState[4] == gameState[8])) {
      setState(() {
        this.message = '${this.gameState[0] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if ((gameState[2] != 'empty') &&
        (gameState[2] == gameState[4]) &&
        (gameState[4] == gameState[6])) {
      setState(() {
        this.message = '${this.gameState[2] == "cross" ? _p1 : _p2} wins';
        this.Delay();
      });
    } else if (!gameState.contains('empty')) {
      setState(() {
        this.message = 'Game Draw';
        this.Delay();
      });
    }
  }

  Widget _buildButton() {
    return MaterialButton(
      color: Color(0xFF0A3D62),
      minWidth: 150.0,
      height: 70.0,
      child: Text(
        status == 0
            ? "Start Game"
            : status == 1
                ? "On hold..."
                : "Exit Game",
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.0,
        ),
      ),
      onPressed: () => {
        status == 0
            ? this.registerPlayer()
            : status == 1
                ? null
                : this.exitGame()
      },
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(85.0),
      ),
    );
  }

  onBackToPage() {
    print("Close Connection");
    hubConnection.stop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          onBackToPage();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Room $roomId",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xFF192A56),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Image(image: this.getImage('cross')),
                        ),
                        Text('$_p1')
                      ],
                    ),
                    Column(),
                    Column(
                      children: <Widget>[
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Image(image: this.getImage('circle')),
                        ),
                        Text('$_p2')
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(15.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0),
                  itemCount: this.gameState.length,
                  itemBuilder: (context, i) => SizedBox(
                    width: 100.0,
                    height: 100.0,
                    child: MaterialButton(
                      onPressed: () {
                        this.playGame(i);
                      },
                      child: Image(
                        image: this.getImage(this.gameState[i]),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  this.message,
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    children: <Widget>[_buildButton()],
                  ),
                  Column(
                    children: <Widget>[
                      MaterialButton(
                        color: Color(0xFF0A3D62),
                        minWidth: 150.0,
                        height: 70.0,
                        child: Text(
                          "Member in Room",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                          ),
                        ),
                        onPressed: () => {showMemberListDialog(context)},
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(85.0),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
