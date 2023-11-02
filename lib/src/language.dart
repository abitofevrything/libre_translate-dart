/// A language supported by a LibreTranslate instance.
class Language {
  /// The code of this language.
  final String code;

  /// A human-readable name of this language.
  final String name;

  /// A list of valid target languages when translating from this language.
  final List<String> targets;

  /// Create a new [Language].
  Language({required this.code, required this.name, required this.targets});
}
