import 'package:teledart/model.dart';

class Game {
  final String impostorMessage = 'Você é o impostor 🕵️‍♂️';
  var _players = <User>[];
  var score = <int>[];
  bool isPlaying = false;
  int impostorIndex;
  String artistMessage;
  String poolId;

  void reset() {
    _players = <User>[];
    impostorIndex = 0;
    artistMessage = '';
  }

  List<User> getPlayers() => _players;

  void addPlayer(User newUser) {
    _players.add(newUser);
    score.add(0);
  }
}
