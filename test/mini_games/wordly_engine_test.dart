import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/wordly/wordly_engine.dart';

String codes(List<LetterMark> marks) => marks.map((m) => m.code).join();

void main() {
  group('scoreGuess', () {
    test('exact match is all green', () {
      expect(codes(scoreGuess('crane', 'crane')), 'GGGGG');
    });

    test('no shared letters is all grey', () {
      expect(codes(scoreGuess('fuzzy', 'crane')), 'BBBBB');
    });

    test('misplaced letters are yellow', () {
      expect(codes(scoreGuess('nacre', 'crane')), 'YYYYG');
    });

    test('duplicate guess letters only mark as many as the answer has', () {
      // One L in "world": the green L claims it, the other L is grey.
      expect(codes(scoreGuess('hello', 'world')), 'BBBGY');
    });

    test('green takes priority over an earlier yellow of the same letter', () {
      // Answer has one E at the end; the first E must be grey.
      expect(codes(scoreGuess('eerie', 'crane')), 'BBYBG');
    });

    test('both copies count when the answer has two', () {
      expect(codes(scoreGuess('sassy', 'essay')), 'YYGBG');
    });
  });

  test('keyboardMarks keeps the best state per key', () {
    final guesses = ['stare', 'crane'];
    final marks = [scoreGuess('stare', 'crane'), scoreGuess('crane', 'crane')];
    final keys = keyboardMarks(guesses, marks);
    expect(keys['r'], LetterMark.correct);
    expect(keys['s'], LetterMark.absent);
    expect(keys['c'], LetterMark.correct);
  });

  test('points reward fewer guesses and zero for a miss', () {
    expect(wordlyPoints(solved: true, guesses: 1), 120);
    expect(wordlyPoints(solved: true, guesses: 6), 20);
    expect(wordlyPoints(solved: false, guesses: 6), 0);
  });
}
