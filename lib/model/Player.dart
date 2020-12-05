class Player {
  final String nickName;

  Player({this.nickName});

  factory Player.parseForm(Map<String, dynamic> json) {
    return Player(nickName: json['nickName']);
  }
}