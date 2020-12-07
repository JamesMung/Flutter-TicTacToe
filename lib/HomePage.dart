import 'package:flutter/material.dart';
import 'package:signalr_client/signalr_client.dart';
import 'package:tic_tac_toe/LoginPage.dart';

class HomePage extends StatefulWidget {

  String playerName;

  HomePage(String username) {
    this.playerName = username;
  }

  @override
  _HomePageState createState() => _HomePageState(playerName);
}

class _HomePageState extends State<HomePage> {

  String playerName;
  String _p1;
  String _p2;

  int role;

  _HomePageState(String playerName) {
    this.playerName = playerName;
  }

  //TODO: link up images
  AssetImage cross = AssetImage("images/cross.png");
  AssetImage circle = AssetImage("images/circle.png");
  AssetImage edit = AssetImage("images/edit.png");

  static final serverUrl = "http://webhelpme.com:8090/gamehub";
  String message;
  List<String> gameState;

  bool canMove = false;
  int status;

  final hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

  void _initSignalR() async {
    try {
      hubConnection.onclose((error) => print("Connection Closed"));
      await hubConnection.start();
      print("Connection established");

      //hubConnection.on("ReceiveRegistorMessage", (e) => { handleRegisterMsg(e[0], e[1])});
      hubConnection.on("SyncPlayRoomInfo", (e) => { getGameBoardInfo(e[0], e[1], e[2], e[3]) });
      hubConnection.invoke("GetConnectionID", args: <Object> [playerName]);
    } catch(e) {
      showAlertDialog(context);
    }
  }

  void getGameBoardInfo(p1, p2, status, String trendString) {
    print(p1 + p2 + status + trendString);
    setState(() {
      _p1 = p1;
      _p2 = p2;

      if(role == null) {
        if(_p1 == playerName) {
          role = 1;
        } else if (_p2 == playerName){
          role = 2;
        }
      }

      if(status != "WS") {
        this.status = 1;
      }

      if(status == "W1" && role == 1) {
        canMove = true;
      } else if(status == "W2" && role == 2) {
        canMove = true;
      }

      int idx = 0;
      trendString.split("").forEach((e) {
        int matchedRole = int.parse(e);

        switch(matchedRole) {
          case 0: this.gameState[idx++] = "empty"; break;
          case 1: this.gameState[idx++] = "cross"; break;
          case 2: this.gameState[idx++] = "circle"; break;
        }
        checkWin();
      });
    });
  }

  showAlertDialog(BuildContext context) {
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LoginPage(),
                maintainState: false));
      },
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

  //TODO: initiazlie the state of box with empty
  @override
  void initState() {
    super.initState();
    this._p1 = '';
    this._p2 = '';
    this.status = 0;

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
      setState(() {
        status = 1;
      });
  }

  //TODO: playGame method
  playGame(int index) {
    if(canMove) {
      if (this.gameState[index] == "empty") {
        setState(() {
          if (role == 1) {
            this.gameState[index] = "cross";
          } else if(role == 2){
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
  Delay() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        this.resetGame();
      });
    });
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
    return new MaterialButton(
      color: Color(0xFF0A3D62),
      minWidth: 300.0,
      height: 70.0,
      child: Text(
        status == 0 ? "Start Game" : status == 1 ? "On hold..." : "Exit Game",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
        ),
      ),
      onPressed: () => {status == 0 ? this.registerPlayer() : status == 1 ? null : this.exitGame()},
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(85.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: Text(
          "Tic Tac Toe",
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
          _buildButton(),
        ],
      ),
    ));
  }
}
