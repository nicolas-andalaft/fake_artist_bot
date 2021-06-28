import 'dart:io' as io;
import 'dart:math';
import 'package:fake_artist_bot/models/game_poll.dart';
import 'package:fake_artist_bot/word_generator.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:fake_artist_bot/models/game.dart' as game;

TeleDart teledart;
Map<int, game.Game> games = {};
Map<String, GamePoll> openPolls = {};
final Map<String, Function> commands = {
  'ajuda': ajuda,
  'novojogo': novoJogo,
  'entrar': entrar,
  'jogadores': jogadores,
  'comecar': comecar,
  'resultado': resultado,
  'impostorganhou': impostorganhou,
  'impostorperdeu': impostorperdeu,
  'placar': placar,
};

void initialize() async {
  var token = await io.File('resources/key.txt').readAsString();
  teledart = TeleDart(Telegram(token), Event());
  await teledart.start().then((me) => print('${me.username} is initializing'));

  teledart.onCommand('start').listen(ajuda);
  for (var command in commands.entries) {
    teledart.onCommand(command.key).listen(command.value);
  }

  teledart.onPoll().listen((pool) {});

  teledart.onPollAnswer().listen(onPollAnswer);
}

void ajuda(TeleDartMessage message) {
  var text;
  if (message.chat.type == 'group') {
    text = '*Bem vindo ao FakeArtistBot!*\n\n'
        'Antes de começar entre neste usuário >>🤖@FakeArtistBot🤖<< e inicie uma conversa.\n'
        'Digite /comandos para saber o que posso fazer.';
  } else {
    text = '*Bem vindo ao FakeArtistBot!*\n\n'
        'Deixe este chat aberto para receber mensagens ao jogar.\n'
        'Me adicione a um grupo e comece o jogo!';
  }

  message.reply('$text', parse_mode: 'Markdown');
}

void novoJogo(TeleDartMessage message) {
  var id = message.chat.id;
  if (games.containsKey(id)) {
    games[id].reset();
    message.reply('🔃 Jogo reiniciado');
  } else {
    games[id] = game.Game();
    message.reply('🔃 Jogo iniciado');
  }
}

void entrar(TeleDartMessage message) {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }

  if (games[id].getPlayers().any((element) => element.id == message.from.id)) {
    message.reply('👤 ${message.from.first_name} já está no jogo');
  } else {
    games[id].addPlayer(message.from);
    message.reply('👤 ${message.from.first_name} foi adicionade ao jogo');
  }
}

void jogadores(TeleDartMessage message) {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }

  var text = '👥 *Jogadores atuais:*\n\n';
  for (var player in games[id].getPlayers()) {
    text += '- ${player.first_name}\n';
  }
  message.reply(text, parse_mode: 'Markdown');
}

void comecar(TeleDartMessage message) async {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }
  var game = games[id];

  if (game.getPlayers().length < 2) {
    await message.reply('🤖 É necessário pelo menos 2 jogadores para jogar');
    return;
  }

  game.isPlaying = true;
  await message.reply('⏳ Gerando nova palavra... ⏳');

  var word = await randomWord();
  var translation = await translate(word);
  game.artistMessage = '🎨 O tema do desenho é: *$translation*';

  game.impostorIndex = Random().nextInt(game.getPlayers().length);
  for (var i = 0; i < game.getPlayers().length; i++) {
    await teledart.telegram
        .sendMessage(
            game.getPlayers()[i].id,
            game.impostorIndex == i
                ? '${game.impostorMessage}'
                : '${game.artistMessage}',
            parse_mode: 'Markdown')
        .onError(
          (error, stackTrace) => message
              .reply('😔 Não foi possível enviar mensagem para um jogador'),
        );
  }

  _createPoll(message);
}

void resultado(TeleDartMessage message) {
  // var id = message.chat.id;
  // if (!_isValid(id, message)) {
  //   return;
  // }

  // var impostor = games[id].getPlayers()[games[id].impostorIndex];
  // message.reply('*O impostor verdadeiro era...*\n\n${impostor.first_name} 😎',
  //     parse_mode: 'Markdown');
}

void _createPoll(TeleDartMessage message) {
  var id = message.chat.id;

  openPolls.remove(games[id].poolId);
  message
      .replyPoll(
    'Quem é o impostor? 🧐',
    games[id].getPlayers().map((e) => e.first_name).toList(),
    is_anonymous: false,
  )
      .then(
    (value) {
      openPolls[value.poll.id] = GamePoll()..chatId = id;
      games[id].poolId = value.poll.id;
    },
  );
}

void impostorganhou(TeleDartMessage message) {
  var id = message.chat.id;
  var game = games[id];
  if (!_isValid(id, message) || !game.isPlaying) {
    return;
  }

  game.score[game.impostorIndex]++;
  game.isPlaying = false;
}

void impostorperdeu(TeleDartMessage message) {
  var id = message.chat.id;
  var game = games[id];
  if (!_isValid(id, message) || !game.isPlaying) {
    return;
  }

  game.score[game.impostorIndex]--;
  game.isPlaying = false;
}

void placar(TeleDartMessage message) {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }

  var players = games[id].getPlayers();
  var score = games[id].score;
  var text = '*Placar atual:*\n\n';
  for (int i = 0; i < players.length; i++) {
    text += '${players[i].first_name}: *${score[i]}*\n';
  }

  message.reply(text, parse_mode: 'Markdown');
}

void onPollAnswer(PollAnswer pollAnswer) {
  var poll = openPolls[pollAnswer.poll_id];
  if (poll == null) return;

  var user = pollAnswer.user;
  if (pollAnswer.option_ids.isEmpty) {
    poll.votes[user] = null;
    return;
  }

  var game = games[poll.chatId];
  poll.votes[user] = game.getPlayers()[pollAnswer.option_ids[0]];

  teledart.telegram.sendMessage(
    poll.chatId,
    '*${user.first_name}* '
    'votou em '
    '*${poll.votes[user].first_name}* '
    '🤭',
    parse_mode: 'Markdown',
  );
}

bool _isValid(int chatId, TeleDartMessage message) {
  if (!games.containsKey(chatId)) {
    message.reply('❌ Crie um jogo novo primeiro');
    return false;
  }
  return true;
}
