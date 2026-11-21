import 'dart:math';

/// Pure game rules for Pac-Man, separate from rendering so it can be tested.

const List<String> kPacMaze = [
  '###################',
  '#........#........#',
  '#o##.###.#.###.##o#',
  '#.................#',
  '#.##.#.#####.#.##.#',
  '#....#...#...#....#',
  '####.### # ###.####',
  'XXX#.#       #.#XXX',
  '####.# ##-## #.####',
  '    .  #GGG#  .    ',
  '####.# ##### #.####',
  'XXX#.#       #.#XXX',
  '####.# ##### #.####',
  '#........#........#',
  '#.##.###.#.###.##.#',
  '#o.#.....P.....#.o#',
  '##.#.#.#####.#.#.##',
  '#....#...#...#....#',
  '#.######.#.######.#',
  '#.................#',
  '###################',
];

const int kPacCols = 19;
const int kPacRows = 21;

enum PacDir {
  none(0, 0),
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const PacDir(this.dx, this.dy);
  final int dx;
  final int dy;

  PacDir get opposite => switch (this) {
    PacDir.up => PacDir.down,
    PacDir.down => PacDir.up,
    PacDir.left => PacDir.right,
    PacDir.right => PacDir.left,
    PacDir.none => PacDir.none,
  };
}

enum GhostMode { house, chase, frightened }

/// Something that moves tile to tile. Its drawn position is
/// `(x, y) + dir * t`, with `t` in [0, 1).
class PacMover {
  PacMover(this.x, this.y, {this.dir = PacDir.none});
  int x;
  int y;
  PacDir dir;
  double t = 0;

  double get px => x + dir.dx * t;
  double get py => y + dir.dy * t;
}

class PacGhost extends PacMover {
  PacGhost({
    required this.index,
    required int x,
    required int y,
    required this.releaseAfter,
  }) : super(x, y);

  /// 0 red (chaser), 1 pink (ambusher), 2 cyan (flanker), 3 orange (shy).
  final int index;

  /// Seconds in the house before (re)entering the maze.
  double releaseAfter;
  GhostMode mode = GhostMode.house;
  double houseTimer = 0;
}

class PacEngine {
  PacEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  // Scoring kept on the same scale as the old game (1 per dot).
  static const dotPoints = 1;
  static const pelletPoints = 5;
  static const ghostBase = 20;
  static const startLives = 3;

  static const _houseDoor = (9, 7);
  static const _startPlayer = (9, 15);
  static const _houseCells = [(9, 9), (8, 9), (10, 9), (9, 9)];

  late Set<int> dots;
  late Set<int> pellets;
  late PacMover player;
  late List<PacGhost> ghosts;
  PacDir wanted = PacDir.left;
  int score = 0;
  int lives = startLives;
  int level = 1;
  double frightLeft = 0;
  int ghostCombo = 0;
  double elapsed = 0;

  /// Set by [update] for the UI: 'dot', 'pellet', 'ghost', 'death', 'clear'.
  final List<String> events = [];

  static int key(int x, int y) => y * kPacCols + x;

  static String cell(int x, int y) {
    if (y < 0 || y >= kPacRows) return 'X';
    final wx = (x % kPacCols + kPacCols) % kPacCols;
    return kPacMaze[y][wx];
  }

  static bool isWall(int x, int y) {
    final c = cell(x, y);
    return c == '#' || c == 'X' || c == '-' || c == 'G';
  }

  void newGame() {
    score = 0;
    lives = startLives;
    level = 1;
    _loadLevel();
  }

  void nextLevel() {
    level++;
    _loadLevel();
  }

  void _loadLevel() {
    dots = {};
    pellets = {};
    for (var y = 0; y < kPacRows; y++) {
      for (var x = 0; x < kPacCols; x++) {
        final c = kPacMaze[y][x];
        if (c == '.') dots.add(key(x, y));
        if (c == 'o') pellets.add(key(x, y));
      }
    }
    resetPositions();
  }

  /// After a death or a new level: everyone back to the start.
  void resetPositions() {
    player = PacMover(_startPlayer.$1, _startPlayer.$2, dir: PacDir.left);
    wanted = PacDir.left;
    frightLeft = 0;
    ghostCombo = 0;
    elapsed = 0;
    ghosts = [
      for (var i = 0; i < 4; i++)
        PacGhost(
          index: i,
          x: _houseCells[i].$1,
          y: _houseCells[i].$2,
          releaseAfter: i * 3.0,
        ),
    ];
    // Red starts outside the house.
    _release(ghosts.first);
  }

  bool get levelCleared => dots.isEmpty && pellets.isEmpty;

  double get _playerSpeed => 5.4 * (1 + 0.05 * (level - 1)).clamp(1, 1.4);
  double get _ghostSpeed => 4.4 * (1 + 0.07 * (level - 1)).clamp(1, 1.5);
  double get _frightDuration => max(2.0, 7.0 - (level - 1) * 0.8);

  void _release(PacGhost g) {
    g
      ..mode = frightLeft > 0 ? GhostMode.frightened : GhostMode.chase
      ..x = _houseDoor.$1
      ..y = _houseDoor.$2
      ..t = 0
      ..dir = _random.nextBool() ? PacDir.left : PacDir.right;
  }

  /// Advances the simulation by [dt] seconds. Returns false when the player
  /// was caught this step.
  bool update(double dt) {
    events.clear();
    elapsed += dt;
    if (frightLeft > 0) {
      frightLeft = max(0, frightLeft - dt);
      if (frightLeft == 0) {
        for (final g in ghosts) {
          if (g.mode == GhostMode.frightened) g.mode = GhostMode.chase;
        }
      }
    }

    _movePlayer(dt);
    _eat();

    for (final g in ghosts) {
      if (g.mode == GhostMode.house) {
        g.houseTimer += dt;
        if (g.houseTimer >= g.releaseAfter) _release(g);
        continue;
      }
      final speed = g.mode == GhostMode.frightened
          ? _ghostSpeed * 0.55
          : _ghostSpeed;
      _moveGhost(g, dt * speed);
    }

    for (final g in ghosts) {
      if (g.mode == GhostMode.house) continue;
      final d = sqrt(pow(g.px - player.px, 2) + pow(g.py - player.py, 2));
      if (d > 0.7) continue;
      if (g.mode == GhostMode.frightened) {
        ghostCombo++;
        score += ghostBase * (1 << (ghostCombo - 1));
        events.add('ghost');
        g
          ..mode = GhostMode.house
          ..houseTimer = 0
          ..releaseAfter = 3
          ..x = 9
          ..y = 9
          ..t = 0
          ..dir = PacDir.none;
      } else {
        lives--;
        events.add('death');
        return false;
      }
    }
    if (levelCleared) events.add('clear');
    return true;
  }

  void _movePlayer(double dt) {
    final p = player;
    // Reverse immediately, even between tiles.
    if (wanted != PacDir.none && wanted == p.dir.opposite && p.t > 0) {
      p
        ..x += p.dir.dx
        ..y += p.dir.dy
        ..dir = wanted
        ..t = 1 - p.t;
      _wrap(p);
    }
    if (p.dir == PacDir.none || p.t == 0) {
      _turnAtCenter(p);
      if (p.dir == PacDir.none) return;
    }
    p.t += dt * _playerSpeed;
    while (p.t >= 1) {
      p
        ..t -= 1
        ..x += p.dir.dx
        ..y += p.dir.dy;
      _wrap(p);
      _turnAtCenter(p);
      if (p.dir == PacDir.none) {
        p.t = 0;
        break;
      }
    }
  }

  void _turnAtCenter(PacMover p) {
    if (wanted != PacDir.none && !isWall(p.x + wanted.dx, p.y + wanted.dy)) {
      p.dir = wanted;
    } else if (p.dir != PacDir.none && isWall(p.x + p.dir.dx, p.y + p.dir.dy)) {
      p.dir = PacDir.none;
    }
  }

  void _eat() {
    // Eat the tile the player is closest to.
    final x = (player.px.round() % kPacCols + kPacCols) % kPacCols;
    final y = player.py.round();
    final k = key(x, y);
    if (dots.remove(k)) {
      score += dotPoints;
      events.add('dot');
    } else if (pellets.remove(k)) {
      score += pelletPoints;
      frightLeft = _frightDuration;
      ghostCombo = 0;
      events.add('pellet');
      for (final g in ghosts) {
        if (g.mode == GhostMode.chase) {
          g.mode = GhostMode.frightened;
          // Ghosts turn around when frightened.
          if (g.t > 0) {
            g
              ..x += g.dir.dx
              ..y += g.dir.dy
              ..t = 1 - g.t;
          }
          g.dir = g.dir.opposite;
          _wrap(g);
        }
      }
    }
  }

  void _moveGhost(PacGhost g, double step) {
    if (g.dir == PacDir.none) g.dir = _chooseDir(g);
    g.t += step;
    while (g.t >= 1) {
      g
        ..t -= 1
        ..x += g.dir.dx
        ..y += g.dir.dy;
      _wrap(g);
      g.dir = _chooseDir(g);
    }
  }

  (int, int) _target(PacGhost g) {
    final px = player.x, py = player.y;
    final pd = player.dir == PacDir.none ? wanted : player.dir;
    switch (g.index) {
      case 1:
        return (px + pd.dx * 4, py + pd.dy * 4);
      case 2:
        final red = ghosts.first;
        final ax = px + pd.dx * 2, ay = py + pd.dy * 2;
        return (ax * 2 - red.x, ay * 2 - red.y);
      case 3:
        final far = pow(g.x - px, 2) + pow(g.y - py, 2) > 64;
        return far ? (px, py) : (0, kPacRows - 1);
      default:
        return (px, py);
    }
  }

  PacDir _chooseDir(PacGhost g) {
    final options = [
      PacDir.up,
      PacDir.left,
      PacDir.down,
      PacDir.right,
    ].where((d) => d != g.dir.opposite && !isWall(g.x + d.dx, g.y + d.dy));
    final list = options.toList();
    if (list.isEmpty) {
      final back = g.dir.opposite;
      return isWall(g.x + back.dx, g.y + back.dy) ? PacDir.none : back;
    }
    if (g.mode == GhostMode.frightened || _random.nextDouble() < 0.08) {
      return list[_random.nextInt(list.length)];
    }
    final (tx, ty) = _target(g);
    list.sort((a, b) {
      final da = pow(g.x + a.dx - tx, 2) + pow(g.y + a.dy - ty, 2);
      final db = pow(g.x + b.dx - tx, 2) + pow(g.y + b.dy - ty, 2);
      return da.compareTo(db);
    });
    return list.first;
  }

  void _wrap(PacMover m) {
    if (m.x < 0) m.x += kPacCols;
    if (m.x >= kPacCols) m.x -= kPacCols;
  }
}
