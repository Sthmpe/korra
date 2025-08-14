extension KorraTextUtils on String {
  /// Title-case each word: "ada okoro" -> "Ada Okoro"
  String get titleCase {
    if (trim().isEmpty) return this;
    return split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
