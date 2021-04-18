import 'package:teledart/model.dart';

class Game {
  final String impostorMessage = 'Você é o impostor 🕵️‍♂️';
  var players = <User>[];
  int impostorIndex;
  String artistMessage;
  String poolId;

  void reset() {
    players = <User>[];
    impostorIndex = 0;
    artistMessage = '';
  }
}
