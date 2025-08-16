double metersToKilometers(int meters) {
  return meters / 1000.0; // 1 kilometer = 1000 meters
}

String toStartCase(String input) {
  final sb = StringBuffer();
  bool capNext = true;

  bool isLetter(String ch) => ch.toLowerCase() != ch.toUpperCase();
  bool isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57; // '0'..'9'
  bool isAlphaNum(String ch) => isLetter(ch) || isDigit(ch);

  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (isAlphaNum(ch)) {
      sb.write(capNext ? ch.toUpperCase() : ch.toLowerCase());
      capNext = false;
    } else {
      sb.write(ch);        // keep punctuation/space
      capNext = true;      // next letter starts a new word
    }
  }
  return sb.toString();
}
