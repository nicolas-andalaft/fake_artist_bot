import 'package:teledart/model.dart';

class GamePoll {
  int chatId;
  Map<User, User> votes = {};

  void reset() {
    votes = {};
  }
}
