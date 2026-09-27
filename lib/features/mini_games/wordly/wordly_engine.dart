import 'dart:math';

import 'package:flutter/services.dart';

/// Tile colour for one letter of a guess.
enum LetterMark {
  /// Right letter, right spot.
  correct,

  /// In the word, wrong spot.
  present,

  /// Not in the word (or all copies already accounted for).
  absent;

  /// One-char code used to sync rows online: G / Y / B.
  String get code => switch (this) {
    correct => 'G',
    present => 'Y',
    absent => 'B',
  };

  static LetterMark fromCode(String c) => switch (c) {
    'G' => correct,
    'Y' => present,
    _ => absent,
  };
}

const kWordLength = 5;
const kMaxGuesses = 6;

/// Scores [guess] against [answer] with standard duplicate handling: exact
/// matches claim their letters first, then leftovers mark as present.
List<LetterMark> scoreGuess(String guess, String answer) {
  final g = guess.toLowerCase();
  final a = answer.toLowerCase();
  final marks = List.filled(kWordLength, LetterMark.absent);
  final remaining = <String, int>{};
  for (var i = 0; i < kWordLength; i++) {
    if (g[i] == a[i]) {
      marks[i] = LetterMark.correct;
    } else {
      remaining[a[i]] = (remaining[a[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < kWordLength; i++) {
    if (marks[i] == LetterMark.correct) continue;
    final left = remaining[g[i]] ?? 0;
    if (left > 0) {
      marks[i] = LetterMark.present;
      remaining[g[i]] = left - 1;
    }
  }
  return marks;
}

/// Best-known state of each keyboard key across all scored rows.
Map<String, LetterMark> keyboardMarks(
  List<String> guesses,
  List<List<LetterMark>> marks,
) {
  final out = <String, LetterMark>{};
  for (var r = 0; r < guesses.length; r++) {
    for (var i = 0; i < kWordLength; i++) {
      final ch = guesses[r][i];
      final m = marks[r][i];
      final prev = out[ch];
      if (prev == null || m.index < prev.index) out[ch] = m;
    }
  }
  return out;
}

/// Points for a finished board: 6 → 1 guesses map to 20…120, 0 if unsolved.
int wordlyPoints({required bool solved, required int guesses}) =>
    solved ? (kMaxGuesses + 1 - guesses) * 20 : 0;

/// Word lists bundled in `assets/wordly/`.
class WordlyWords {
  WordlyWords._(this.answers, this._valid);

  final List<String> answers;
  final Set<String> _valid;

  static WordlyWords? _cache;

  static Future<WordlyWords> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final answers =
        (await rootBundle.loadString('assets/wordly/answers_en.txt'))
            .split('\n')
            .map((w) => w.trim())
            .where((w) => w.length == kWordLength)
            .toList();
    final valid =
        (await rootBundle.loadString('assets/wordly/valid_en.txt'))
            .split('\n')
            .map((w) => w.trim())
            .where((w) => w.length == kWordLength)
            .toSet()
          ..addAll(answers);
    return _cache = WordlyWords._(answers, valid);
  }

  bool isValid(String word) => _valid.contains(word.toLowerCase());

  /// Same word for everyone on a given calendar day.
  String daily(DateTime day) {
    final epoch = DateTime.utc(2024);
    final n = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(epoch).inDays;
    // Stable shuffle so consecutive days aren't alphabetical neighbours.
    return answers[(n * 7919) % answers.length];
  }

  String random([Random? rng]) =>
      answers[(rng ?? Random()).nextInt(answers.length)];
}
