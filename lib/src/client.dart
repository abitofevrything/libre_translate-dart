import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:libre_translate/src/errors.dart';
import 'package:libre_translate/src/language.dart';

/// A client that contains methods for interacting with the LibreTranslate API.
class LibreTranslateClient {
  /// The base URI the API is hosted at.
  final Uri base;

  /// The API key to use when accessing the API.
  final String? apiKey;

  /// The client used to make HTTP requests.
  final Client client = Client();

  /// Create a new [LibreTranslateClient].
  LibreTranslateClient({required Uri base, this.apiKey})
      : base = base.path.endsWith('/') ? base : base.replace(path: '${base.path}/');

  void _handlePotentialError(Response response) {
    if (response.statusCode >= 400) {
      try {
        final json = jsonDecode(utf8.decode(response.bodyBytes));

        throw LibreTranslateException(json['error'] ?? 'Unknown error');
      } on FormatException {
        throw LibreTranslateException('${response.statusCode} ${response.reasonPhrase ?? ''}');
      }
    }
  }

  /// Detect the language of some text.
  ///
  /// Returns a mapping of language code to confidence.
  Future<Map<String, double>> detect(String text) async {
    final request = Request('POST', base.resolve('detect'))
      ..bodyFields = {'q': text, if (apiKey != null) 'api_key': apiKey!};

    final response = await Response.fromStream(await client.send(request));
    _handlePotentialError(response);

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return {
      for (final {"confidence": double confidence, "language": String language} in body)
        language: confidence,
    };
  }

  /// List the available [Language]s on this LibreTranslate instance.
  Future<List<Language>> listLanguages() async {
    final request = Request('GET', base.resolve('languages'));

    final response = await Response.fromStream(await client.send(request));
    _handlePotentialError(response);

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return [
      for (final {"code": String code, "name": String name, "targets": List targets} in body)
        Language(code: code, name: name, targets: targets.cast<String>()),
    ];
  }

  /// Translate some text.
  ///
  /// [isHtml] can be set if the [text] contains HTML code.
  Future<String> translate(
    String text, {
    required String source,
    required String target,
    bool isHtml = false,
  }) async {
    final request = Request('POST', base.resolve('translate'))
      ..bodyFields = {
        'q': text,
        'source': source,
        'target': target,
        'format': isHtml ? 'html' : 'text',
        if (apiKey != null) 'api_key': apiKey!,
      };

    final response = await Response.fromStream(await client.send(request));
    _handlePotentialError(response);

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body['translatedText'];
  }

  /// Translate a file.
  Future<ByteStream> translateFile(
    Uint8List file, {
    required String source,
    required String target,
  }) async {
    final request = MultipartRequest('POST', base.resolve('translate_file'))
      ..files.add(MultipartFile.fromBytes('file', file))
      ..fields.addAll({'source': source, 'target': target, if (apiKey != null) 'api_key': apiKey!});

    final response = await Response.fromStream(await client.send(request));
    _handlePotentialError(response);

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (await client.send(Request('GET', Uri.parse(body['translatedFileUrl'])))).stream;
  }

  /// Close the client and all associated resources.
  void close() => client.close();
}
