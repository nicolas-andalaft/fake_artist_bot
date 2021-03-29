import 'package:web_scraper/web_scraper.dart';
import 'package:translator/translator.dart';

final url = 'https://www.generatorslist.com';
final page = '/random/words/pictionary-word-generator';

Future<String> randomWord() async {
  final webScraper = WebScraper(url);
  if (await webScraper.loadWebPage(page)) {
    var elements = webScraper.getElement('.card-title', []);
    return elements[0]['title'];
  }
}

Future<String> translate(String input) async {
  final translator = GoogleTranslator();

  var output = await translator.translate(input, from: 'en', to: 'pt');
  return output.text;
}
