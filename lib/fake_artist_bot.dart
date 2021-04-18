import 'dart:io' as io;
import 'dart:math';
import 'package:fake_artist_bot/word_generator.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:fake_artist_bot/models/game.dart' as game;

TeleDart teledart;
Map<int, game.Game> games = {};
final Map<String, Function> commands = {
  'ajuda': ajuda,
  'novojogo': novoJogo,
  'entrar': entrar,
  'jogadores': jogadores,
  'comecar': comecar,
  'votar': votar,
  'resultado': resultado,
};

void initialize() async {
  var token = await io.File('resources/key.txt').readAsString();
  teledart = TeleDart(Telegram(token), Event());
  await teledart.start().then((me) => print('${me.username} is initializing'));

  teledart.onCommand('start').listen(ajuda);
  for (var command in commands.entries) {
    teledart.onCommand(command.key).listen(command.value);
  }
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

  if (games[id].players.any((element) => element.id == id)) {
    message.reply('👤 ${message.from.first_name} já está no jogo');
  } else {
    games[id].players.add(message.from);
    message.reply('👤 ${message.from.first_name} foi adicionade ao jogo');
  }
}

void jogadores(TeleDartMessage message) {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }

  var text = '👥 *Jogadores atuais:*\n\n';
  for (var player in games[id].players) {
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

  if (game.players.length < 2) {
    await message.reply('🤖 É necessário pelo menos 2 jogadores para jogar');
    return;
  }
  await message.reply('⏳ Gerando nova palavra... ⏳');

  var word = await randomWord();
  var translation = await translate(word);
  game.artistMessage = '🎨 O tema do desenho é: *$translation*';

  game.impostorIndex = Random().nextInt(game.players.length);
  for (var i = 0; i < game.players.length; i++) {
    await teledart.telegram
        .sendMessage(
            game.players[i].id,
            game.impostorIndex == i
                ? '${game.impostorMessage}'
                : '${game.artistMessage}',
            parse_mode: 'Markdown')
        .onError(
          (error, stackTrace) => message
              .reply('😔 Não foi possível enviar mensagem para um jogador'),
        );
  }
}

void votar(TeleDartMessage message) {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }

  if (games[id].players.length < 2) {
    message.reply('🤖 Adicione mais jogadores para criar uma enquete');
    return;
  }

  message.replyPoll(
    'Quem é o impostor? 🧐',
    games[id].players.map((e) => e.first_name).toList(),
    is_anonymous: false,
  );
}

void resultado(TeleDartMessage message) {
  var id = message.chat.id;
  if (!_isValid(id, message)) {
    return;
  }

  var impostor = games[id].players[games[id].impostorIndex];
  message.reply('*O impostor verdadeiro era...*\n\n${impostor.first_name} 😎',
      parse_mode: 'Markdown');
}

bool _isValid(int chatId, TeleDartMessage message) {
  if (!games.containsKey(chatId)) {
    message.reply('❌ Crie um jogo novo primeiro');
    return false;
  }
  return true;
}
