import 'package:libre_translate/libre_translate.dart';

void main() async {
  // libretranslate.com requires an API key, so we use a mirror that doesn't require one.
  final client = LibreTranslateClient(base: Uri.https('translate.terraprint.co'));

  print(await client.translate('Hello!', source: 'en', target: 'fr'));
}
