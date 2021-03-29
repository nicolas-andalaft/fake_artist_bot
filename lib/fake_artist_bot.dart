import 'dart:io' as io;
import 'dart:math';
import 'package:fake_artist_bot/word_generator.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

TeleDart teledart;
var players = <User>[];
String impostorMessage = 'Você é o impostor 🕵️‍♂️';
String artistMessage;

void initialize() async {
  var token = await io.File('resources/key.txt').readAsString();
  teledart = TeleDart(Telegram(token), Event());
  await teledart.start().then((me) => print('${me.username} is initialised'));

  teledart.onCommand('start').listen(start);
  teledart.onCommand('novojogo').listen(novoJogo);
  teledart.onCommand('entrar').listen(entrar);
  teledart.onCommand('jogadores').listen(jogadores);
  teledart.onCommand('comecar').listen(comecar);

  teledart.onCommand('comandos').listen(comandos);
}

void comandos(TeleDartMessage message) {
  var commands = ['/novojogo', '/entrar', '/jogadores', '/comecar'];
  var keyboard = commands.map((e) => [KeyboardButton(text: e)]).toList();

  message.reply('🤖 Selecione um comando',
      reply_markup: ReplyKeyboardMarkup(keyboard: keyboard));
}

void start(TeleDartMessage message) {
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
  players = <User>[];
  message.reply('🔃 Jogo reiniciado');
}

void entrar(TeleDartMessage message) {
  if (players.any((element) => element.id == message.from.id)) {
    message.reply('👤 ${message.from.first_name} já está no jogo');
    return;
  }
  players.add(message.from);
  message.reply('👤 ${message.from.first_name} foi adicionade ao jogo');
}

void jogadores(TeleDartMessage message) {
  var text = '👥 *Jogadores atuais:*\n\n';
  for (var player in players) {
    text += '- ${player.first_name}\n';
  }
  message.reply(text, parse_mode: 'Markdown');
}

void comecar(TeleDartMessage message) async {
  if (players.length < 3) {
    await message.reply('🤖 É necessário pelo menos 3 jogadores para jogar');
    return;
  }
  await message.reply('⏳ Gerando nova palavra... ⏳');

  var word = await randomWord();
  var translation = await translate(word);
  artistMessage = '🎨 O tema do desenho é: *$translation*';

  var impostorIndex = Random().nextInt(players.length);
  for (var i = 0; i < players.length; i++) {
    await teledart.telegram
        .sendMessage(players[i].id,
            impostorIndex == i ? '$impostorMessage' : '$artistMessage',
            parse_mode: 'Markdown')
        .onError(
          (error, stackTrace) => message
              .reply('😔 Não foi possível enviar mensagem para um jogador'),
        );
  }
}
