import 'dart:io' as io;
import 'dart:math';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

TeleDart teledart;
var players = <User>[];
String impostorMessage = 'Você é o impostor';
String artistMessage = 'Você é um artista';

void initialize() async {
  var token = await io.File('resources/key.txt').readAsString();
  teledart = TeleDart(Telegram(token), Event());
  await teledart.start().then((me) => print('${me.username} is initialised'));

  teledart.onCommand('start').listen(start);
  teledart.onCommand('novojogo').listen(novoJogo);
  teledart.onCommand('entrar').listen(entrar);
  teledart.onCommand('jogadores').listen(jogadores);
  teledart.onCommand('gerarimpostor').listen(gerarImpostor);

  teledart.onCommand('comandos').listen(comandos);
}

void comandos(TeleDartMessage message) {
  var commands = ['/novojogo', '/entrar', '/jogadores', '/gerarimpostor'];
  var keyboard = commands.map((e) => [KeyboardButton(text: e)]).toList();

  message.reply('Selecione um comando',
      reply_markup: ReplyKeyboardMarkup(keyboard: keyboard));
}

void start(TeleDartMessage message) {
  var text;
  if (message.chat.type == 'group') {
    text = '*Bem vindo ao FakeArtistBot!*\n\n'
        'Antes de começar entre neste usuário >>@FakeArtistBot<< e inicie uma conversa.\n'
        'Digite /comandos para saber o que posso fazer.';
  } else {
    text = '*Bem vindo ao FakeArtistBot!*\n\n'
        'Deixe este chat aberto para receber mensagens ao jogar.\n'
        'Me adicione a um grupo e comece o jogo!';
  }

  message.reply('$text', parse_mode: 'Markdown');
}

void novoJogo(TeleDartMessage message) {
  players = <User>[];
}

void entrar(TeleDartMessage message) {
  if (players.any((element) => element.id == message.from.id)) {
    message.reply('${message.from.first_name} já está no jogo');
    return;
  }
  players.add(message.from);
  message.reply('${message.from.first_name} foi adicionade ao jogo');
}

void jogadores(TeleDartMessage message) {
  var text = '*Jogadores atuais:*\n\n';
  for (var player in players) {
    text += '- ${player.first_name}\n';
  }
  message.reply(text, parse_mode: 'Markdown');
}

void gerarImpostor(TeleDartMessage message) {
  var impostorIndex = Random().nextInt(players.length);
  for (var i = 0; i < players.length; i++) {
    teledart.telegram.sendMessage(
      players[i].id,
      impostorIndex == i ? impostorMessage : artistMessage,
    );
  }
}
