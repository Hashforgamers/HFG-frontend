import 'dart:math';

enum ArrowDir {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const ArrowDir(this.dx, this.dy);
  final int dx;
  final int dy;
}

/// A snaking arrow on the board. [cells] runs head first; the head points
/// along [dir], away from the second cell.
class EscapeArrow {
  EscapeArrow({required this.id, required this.cells, required this.dir});

  final int id;
  final List<Point<int>> cells;
  final ArrowDir dir;

  Point<int> get head => cells.first;
  int get length => cells.length;
}

/// Result of tapping an arrow: it either leaves the board or slides [steps]
/// free cells and bumps into another arrow.
class ArrowMove {
  const ArrowMove({required this.escaped, required this.steps});

  final bool escaped;
  final int steps;
}

/// The grid of arrows. Tapping an arrow sends it forward along its head; it
/// escapes only if every cell between the head and the board edge is free.
class ArrowBoard {
  ArrowBoard({required this.cols, required this.rows, required this.arrows})
    : initialCount = arrows.length;

  final int cols;
  final int rows;
  final List<EscapeArrow> arrows;
  final int initialCount;

  /// Builds a board that is always solvable: arrows are added in reverse
  /// removal order, so each new arrow's exit lane is clear of every arrow
  /// placed before it (the ones still on the board when it has to leave).
  ///
  /// [tangle] (0..1) is how hard the generator tries to park new arrows in
  /// the lanes of earlier ones, which is what makes arrows wait on each other.
  factory ArrowBoard.generate({
    required int cols,
    required int rows,
    required Random rng,
    int maxLength = 5,
    double tangle = 0,
  }) {
    final taken = <Point<int>>{};
    // How many placed arrows need each cell free to escape.
    final lanes = <Point<int>, int>{};
    final arrows = <EscapeArrow>[];
    bool inside(Point<int> p) =>
        p.x >= 0 && p.y >= 0 && p.x < cols && p.y < rows;
    List<Point<int>> laneOf(Point<int> head, ArrowDir dir) {
      final lane = <Point<int>>[];
      var p = Point(head.x + dir.dx, head.y + dir.dy);
      while (inside(p)) {
        lane.add(p);
        p = Point(p.x + dir.dx, p.y + dir.dy);
      }
      return lane;
    }

    /// A random head + direction whose neck is free and lane is clear.
    (Point<int>, ArrowDir)? spot() {
      final head = Point(rng.nextInt(cols), rng.nextInt(rows));
      final dir = ArrowDir.values[rng.nextInt(4)];
      final neck = Point(head.x - dir.dx, head.y - dir.dy);
      if (taken.contains(head) || !inside(neck) || taken.contains(neck)) {
        return null;
      }
      if (laneOf(head, dir).any(taken.contains)) return null;
      return (head, dir);
    }

    int blocking(Point<int> head, ArrowDir dir) =>
        (lanes[head] ?? 0) +
        (lanes[Point(head.x - dir.dx, head.y - dir.dy)] ?? 0);

    var misses = 0;
    while (misses < 220 && taken.length < cols * rows) {
      var pick = spot();
      if (pick != null && rng.nextDouble() < tangle) {
        // Shop around for the spot that blocks the most arrows.
        for (var i = 0; i < 14; i++) {
          final other = spot();
          if (other != null &&
              blocking(other.$1, other.$2) > blocking(pick!.$1, pick.$2)) {
            pick = other;
          }
        }
      }
      if (pick == null) {
        misses++;
        continue;
      }
      final (head, dir) = pick;
      final lane = laneOf(head, dir);

      final cells = [head, Point(head.x - dir.dx, head.y - dir.dy)];
      final want = 2 + rng.nextInt(max(1, maxLength - 1));
      while (cells.length < want) {
        final tail = cells.last;
        final next =
            [
                  for (final d in ArrowDir.values)
                    Point(tail.x + d.dx, tail.y + d.dy),
                ]
                .where(
                  (c) =>
                      inside(c) &&
                      !taken.contains(c) &&
                      !cells.contains(c) &&
                      !lane.contains(c),
                )
                .toList();
        if (next.isEmpty) break;
        final inLanes = next.where(lanes.containsKey).toList();
        final pool = inLanes.isNotEmpty && rng.nextDouble() < tangle
            ? inLanes
            : next;
        cells.add(pool[rng.nextInt(pool.length)]);
      }
      taken.addAll(cells);
      for (final c in lane) {
        lanes[c] = (lanes[c] ?? 0) + 1;
      }
      arrows.add(EscapeArrow(id: arrows.length, cells: cells, dir: dir));
      misses = 0;
    }
    return ArrowBoard(cols: cols, rows: rows, arrows: arrows);
  }

  bool get cleared => arrows.isEmpty;
  int get escapedCount => initialCount - arrows.length;

  EscapeArrow? arrowAt(int col, int row) {
    final p = Point(col, row);
    for (final a in arrows) {
      if (a.cells.contains(p)) return a;
    }
    return null;
  }

  /// Free cells ahead of [arrow]'s head, and whether the lane reaches the edge.
  ArrowMove probe(EscapeArrow arrow) {
    var steps = 0;
    var p = Point(arrow.head.x + arrow.dir.dx, arrow.head.y + arrow.dir.dy);
    while (p.x >= 0 && p.y >= 0 && p.x < cols && p.y < rows) {
      final hit = arrowAt(p.x, p.y);
      if (hit != null && hit != arrow) {
        return ArrowMove(escaped: false, steps: steps);
      }
      steps++;
      p = Point(p.x + arrow.dir.dx, p.y + arrow.dir.dy);
    }
    return ArrowMove(escaped: true, steps: steps);
  }

  /// Tries to launch [arrow]; it is removed from the board when it escapes.
  ArrowMove launch(EscapeArrow arrow) {
    final move = probe(arrow);
    if (move.escaped) arrows.remove(arrow);
    return move;
  }

  /// An arrow that can leave right now, or null when none can.
  EscapeArrow? get hint {
    for (final a in arrows) {
      if (probe(a).escaped) return a;
    }
    return null;
  }

  /// Escaping never blocks another arrow, so greedy removal decides this.
  bool get solvable => depth != null;

  /// Arrows that can leave right now.
  int get freeCount => arrows.where((a) => probe(a).escaped).length;

  /// How many waves it takes to clear the board when every free arrow leaves
  /// at once: the length of the longest wait chain. Null if it can't be
  /// cleared.
  int? get depth {
    final copy = ArrowBoard(cols: cols, rows: rows, arrows: [...arrows]);
    var waves = 0;
    while (!copy.cleared) {
      final free = copy.arrows.where((a) => copy.probe(a).escaped).toSet();
      if (free.isEmpty) return null;
      copy.arrows.removeWhere(free.contains);
      waves++;
    }
    return waves;
  }
}

enum ArrowTapOutcome { escaped, levelCleared, blocked, gameOver }

/// One run through the level ladder. Every level number is a fixed puzzle;
/// boards get bigger, longer and more tangled the higher you climb, and the
/// run ends when the lives run out.
class ArrowEscapeRun {
  ArrowEscapeRun({Random? rng, int startLevel = 1})
    : _rng = rng,
      level = max(1, startLevel) {
    _deal();
  }

  static const maxLives = 3;

  /// Lives stop coming back on a clear after this level.
  static const lastRefillLevel = 10;

  /// Overrides the per-level seed (tests).
  final Random? _rng;
  late ArrowBoard board;
  int level;
  int lives = maxLives;
  int score = 0;
  int streak = 0;
  int hints = 0;

  bool get over => lives <= 0;

  static (int cols, int rows) sizeFor(int level) {
    final cols = switch (level) {
      < 3 => 5,
      < 6 => 6,
      < 10 => 7,
      < 15 => 8,
      _ => 9,
    };
    // Past the widest board, levels keep getting taller.
    final extra = level < 20 ? 0 : min((level - 15) ~/ 5, 2);
    return (cols, cols + 2 + extra);
  }

  static int maxLengthFor(int level) => min(3 + level ~/ 4, 5);

  /// See [ArrowBoard.generate]; climbs to 0.95 by level 40.
  static double tangleFor(int level) => min(0.95, 0.1 + 0.022 * (level - 1));

  static int hintsFor(int level) => max(1, 3 - level ~/ 10);

  static String tierFor(int level) => switch (level) {
    < 6 => 'EASY',
    < 13 => 'MEDIUM',
    < 21 => 'HARD',
    < 36 => 'EXPERT',
    _ => 'INSANE',
  };

  /// Bonus paid for finishing [level].
  static int clearBonus(int level) => 50 * level;

  /// Boards generated per level; the knottiest one is kept.
  static int candidatesFor(int level) => min(1 + (level - 1) * 6, 300);

  static ArrowBoard boardFor(int level, {Random? rng}) {
    final (cols, rows) = sizeFor(level);
    final random = rng ?? Random(level * 7919 + 13);
    ArrowBoard? best;
    var bestScore = -1 << 30;
    for (var i = 0; i < candidatesFor(level); i++) {
      final board = ArrowBoard.generate(
        cols: cols,
        rows: rows,
        rng: random,
        maxLength: maxLengthFor(level),
        tangle: tangleFor(level),
      );
      // Long wait chains and few free arrows make a board hard.
      final score =
          6 * (board.depth ?? 0) + board.arrows.length - 3 * board.freeCount;
      if (score > bestScore) {
        best = board;
        bestScore = score;
      }
    }
    return best!;
  }

  void _deal() {
    board = boardFor(level, rng: _rng);
    hints = hintsFor(level);
  }

  (ArrowTapOutcome, ArrowMove) tap(EscapeArrow arrow) {
    final move = board.launch(arrow);
    if (!move.escaped) {
      streak = 0;
      lives--;
      return (over ? ArrowTapOutcome.gameOver : ArrowTapOutcome.blocked, move);
    }
    streak++;
    score += 10 + 2 * min(streak - 1, 10);
    if (!board.cleared) return (ArrowTapOutcome.escaped, move);
    score += clearBonus(level);
    return (ArrowTapOutcome.levelCleared, move);
  }

  /// Spends a hint (and the streak) to reveal an arrow that can leave.
  EscapeArrow? useHint() {
    if (hints <= 0) return null;
    hints--;
    streak = 0;
    return board.hint;
  }

  /// Refills the lives so a lost run carries on from the same board.
  void revive() => lives = maxLives;

  void nextLevel() {
    if (level <= lastRefillLevel) lives = min(lives + 1, maxLives);
    level++;
    _deal();
  }
}
