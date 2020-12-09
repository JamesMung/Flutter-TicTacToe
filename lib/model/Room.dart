class Room {
  final int roomId;
  final String status;

  Room({this.roomId, this.status});

  factory Room.parseForm(Map<String, dynamic> json) {
    return Room(roomId: json['autoid'], status: json['status']);
  }
}