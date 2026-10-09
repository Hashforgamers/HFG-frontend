import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/ludo/ludo_player.dart';
import 'package:provider/provider.dart';

import 'audio.dart';
import 'constants.dart';
import 'power_ups.dart';
import 'online/ludo_match.dart';
import 'online/ludo_match_service.dart';
import 'ludo_dice_policy.dart';

class LudoProvider extends ChangeNotifier {
  LudoProvider({
    this.againstAi = false,
    this.powerMode = false,
    Random? random,
    this.soundEnabled = true,
    this.tokens = 4,
    Set<LudoPlayerType>? seats,
    this.firstMatch = false,
  }) : _random = random ?? Random(),
       _activeSeats = seats ?? kLudoSeatOrder.toSet();

  final bool againstAi;

  /// Power Ludo: everyone starts with one of each power-up; a capture
  /// refills a used one (local play only).
  final bool powerMode;
  final bool soundEnabled;

  /// Pawns per player: 4 normally, 2 in Quick Ludo.
  final int tokens;

  /// Quick Ludo: fewer tokens for a ~5 minute game. Unranked.
  bool get quickLudo => tokens < 4 && !firstMatch;

  /// A new player's first game: easy bot and a little dice help
  /// ([LudoDicePolicy]). Unranked.
  final bool firstMatch;

  /// The 2-token 1v1 against an easy bot that new players start with.
  factory LudoProvider.firstMatch() => LudoProvider(
    againstAi: true,
    tokens: 2,
    seats: {LudoPlayerType.green, LudoPlayerType.blue},
    firstMatch: true,
  );
  final Random _random;
  Timer? _aiTimer;
  int _generation = 0;
  bool get isAiTurn =>
      (!_online && againstAi && _currentTurn != LudoPlayerType.green) ||
      isBotTurn;

  void _tickAi() {
    if (_stopMoving ||
        !isAiTurn ||
        _isMoving ||
        _diceStarted ||
        _gameState == LudoGameState.finish ||
        winners.length >= _endThreshold) {
      return;
    }
    // Online bots occasionally hesitate a beat so they don't feel instant.
    if (isBotTurn && _random.nextInt(3) == 0) return;
    if (_aiUsePower()) return;
    if (_gameState == LudoGameState.throwDice) {
      throwDice(automated: true);
    } else if (_gameState == LudoGameState.pickPawn) {
      final choices = currentPlayer.pawns
          .where((pawn) => pawn.highlight)
          .toList();
      if (choices.isEmpty) return;
      // Finish advanced pawns first; otherwise bring another pawn into play.
      // The first-match bot does the opposite and dawdles.
      choices.sort(
        (a, b) =>
            firstMatch ? a.step.compareTo(b.step) : b.step.compareTo(a.step),
      );
      final pawn = choices.first;
      move(
        pawn.type,
        pawn.index,
        pawn.step == -1 ? 1 : pawn.step + 1 + diceResult,
      );
    }
  }

  // ---------------------------------------------------------------- powers

  static const int maxPowers = 4;

  final Map<LudoPlayerType, List<PowerUp>> powers = {
    for (final s in LudoPlayerType.values) s: <PowerUp>[],
  };
  final Map<LudoPlayerType, int> _shieldTurns = {};

  /// Seat that armed Boost / Lucky Six (they only fire on that seat's turn).
  LudoPlayerType? _boostFor;
  LudoPlayerType? _luckyFor;
  PowerEvent? _powerEvent;
  int _powerEventId = 0;

  bool get boostArmed => _boostFor == _currentTurn;
  bool get luckyArmed => _luckyFor == _currentTurn;
  PowerEvent? get powerEvent => _powerEvent;
  int shieldTurns(LudoPlayerType type) => _shieldTurns[type] ?? 0;

  bool _isShielded(LudoPlayerType type) =>
      powerMode && (_shieldTurns[type] ?? 0) > 0;

  void _emitPower(LudoPlayerType seat, PowerUp power, {required bool gained}) {
    _powerEvent = PowerEvent(
      id: ++_powerEventId,
      seat: seat,
      power: power,
      gained: gained,
    );
    final id = _powerEventId;
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (_stopMoving || _powerEvent?.id != id) return;
      _powerEvent = null;
      notifyListeners();
    });
  }

  void _grantPower(LudoPlayerType type) {
    if (!powerMode) return;
    final bag = powers[type]!;
    if (bag.length >= maxPowers) return;
    final missing = PowerUp.values.where((p) => !bag.contains(p)).toList();
    if (missing.isEmpty) return;
    final power = missing[_random.nextInt(missing.length)];
    bag.add(power);
    _emitPower(type, power, gained: true);
    Haptics.success();
    notifyListeners();
  }

  /// Whether the current (human) player may use [power] right now.
  bool canUsePower(PowerUp power) =>
      powerMode && !isAiTurn && _canApply(_currentTurn, power);

  bool _canApply(LudoPlayerType type, PowerUp power) {
    if (_stopMoving || _isMoving || _diceStarted) return false;
    if (_gameState == LudoGameState.finish) return false;
    if (!(powers[type]?.contains(power) ?? false)) return false;
    final p = player(type);
    switch (power) {
      case PowerUp.reroll:
        return _gameState == LudoGameState.pickPawn;
      case PowerUp.luckySix:
        return _gameState == LudoGameState.throwDice && _luckyFor != type;
      case PowerUp.boost:
        return _boostFor != type && p.pawns.any((e) => e.step >= 0);
      case PowerUp.shield:
        return !_isShielded(type) && p.pawns.any((e) => e.step >= 0);
    }
  }

  void usePower(PowerUp power) {
    if (!canUsePower(power)) return;
    _applyPower(_currentTurn, power);
  }

  void _applyPower(LudoPlayerType type, PowerUp power) {
    powers[type]!.remove(power);
    _emitPower(type, power, gained: false);
    if (!isAiTurn) Haptics.medium();
    switch (power) {
      case PowerUp.reroll:
        currentPlayer.highlightAllPawns(false);
        _gameState = LudoGameState.throwDice;
        notifyListeners();
        throwDice(automated: isAiTurn);
        return;
      case PowerUp.luckySix:
        _luckyFor = type;
      case PowerUp.boost:
        _boostFor = type;
      case PowerUp.shield:
        // Protects through the opponents' turns until two of the owner's own
        // turns have started.
        _shieldTurns[type] = 3;
    }
    notifyListeners();
  }

  /// Simple AI power usage, called before the AI acts.
  bool _aiUsePower() {
    if (!powerMode) return false;
    final type = _currentTurn;
    final bag = powers[type]!;
    if (bag.isEmpty) return false;
    final p = currentPlayer;
    if (_gameState == LudoGameState.throwDice) {
      if (p.pawnInsideCount == p.pawns.length &&
          _canApply(type, PowerUp.luckySix)) {
        _applyPower(type, PowerUp.luckySix);
        return true;
      }
      if (p.pawns.where((e) => e.step >= 0).length >= 2 &&
          _canApply(type, PowerUp.shield)) {
        _applyPower(type, PowerUp.shield);
        return true;
      }
    } else if (_gameState == LudoGameState.pickPawn) {
      if (_diceResult <= 2 && _canApply(type, PowerUp.reroll)) {
        _applyPower(type, PowerUp.reroll);
        return true;
      }
      if (_canApply(type, PowerUp.boost)) {
        _applyPower(type, PowerUp.boost);
        // Fall through: the AI still moves this tick.
      }
    }
    return false;
  }

  ///Flags to check if pawn is moving
  bool _isMoving = false;

  // --- Online multiplayer (opt-in). When [_online] is false every code path
  // below behaves exactly like the original local hot-seat game. ---
  bool _online = false;
  LudoMatchService? _matchService;
  String? _matchId;
  LudoPlayerType? _mySeat;
  Set<LudoPlayerType> _activeSeats;

  /// The game ends once every seat but one has brought all pawns home.
  int get _endThreshold => (_activeSeats.length - 1).clamp(1, 3);
  StreamSubscription<LudoMatch?>? _matchSub;
  Set<LudoPlayerType> _botSeats = {};

  /// This device plays the bots' turns (it is the match's bot driver).
  bool _drivesBots = false;
  int _version = 0;
  bool _finished = false;

  // Last authoritative values we applied, so we can tell what a fresh remote
  // snapshot actually changed and play sound/haptics for the acting opponent.
  int _lastRemoteDice = 0;
  Map<LudoPlayerType, List<int>> _lastRemotePawns = {};
  String _lastRemoteKey = '';

  /// A snapshot that arrived while a local move was animating; applied as
  /// soon as the move finishes instead of being dropped.
  LudoMatch? _pendingRemote;

  /// Identity of the game state in a snapshot (not reactions/seat metadata).
  static String _stateKey(LudoMatch m) {
    final pawns = [
      for (final s in kLudoSeatOrder)
        if (m.pawns.containsKey(s)) '${s.name}:${m.pawns[s]!.join(',')}',
    ].join('|');
    return '${m.turn.name}/${m.dice}/${m.winners.map((e) => e.name).join(',')}/'
        '${m.status.name}/$pawns';
  }

  bool get isOnline => _online;
  LudoPlayerType? get mySeat => _mySeat;

  /// A seat-less online client is a spectator: it mirrors the match but can
  /// never roll, move or skip.
  bool get isSpectator => _online && _mySeat == null;

  /// Whether the local device may roll/move right now.
  bool get isMyTurn => _online ? _currentTurn == _mySeat : !isAiTurn;

  /// Online: it's a bot seat's turn and this device is the one playing it.
  bool get isBotTurn =>
      _online && _drivesBots && !_finished && _botSeats.contains(_currentTurn);
  Set<LudoPlayerType> get botSeats => _botSeats;
  bool get onlineFinished => _finished;
  Set<LudoPlayerType> get activeSeats => _activeSeats;

  /// Switch this provider into networked mode and start mirroring the match doc.
  void attachOnline({
    required LudoMatchService service,
    required String matchId,
    required LudoPlayerType? mySeat,
    required LudoMatch initial,
  }) {
    _online = true;
    _matchService = service;
    _matchId = matchId;
    _mySeat = mySeat;
    _applyRemote(initial, force: true);
    _matchSub = service.watch(matchId).listen((m) {
      if (m != null) _applyRemote(m);
    });
    // Drives any bot seats whenever this device is the bot driver.
    _aiTimer?.cancel();
    _aiTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _tickAi(),
    );
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Apply an authoritative snapshot from Firestore. Our own writes echo back;
  /// we skip those (we already hold that state) unless [force] (initial load).
  void _applyRemote(LudoMatch m, {bool force = false}) {
    _activeSeats = m.seats.keys.toSet();
    _botSeats = m.botSeats;
    _drivesBots = _mySeat != null && m.botDriverUid == _uid;
    _version = m.version;
    _finished = m.status == LudoMatchStatus.finished;

    final key = _stateKey(m);
    final fromMe = m.lastWriterUid == _uid;
    if (fromMe && !force) {
      _lastRemoteKey = key;
      return; // our own echo — nothing new to apply
    }
    // Reactions, seat joins and timer nudges don't change the game; applying
    // them would reset a player who is mid-way through picking a pawn.
    if (!force && key == _lastRemoteKey) {
      notifyListeners();
      return;
    }
    if (_isMoving && !force) {
      _pendingRemote = m; // apply once the local animation completes
      return;
    }
    _lastRemoteKey = key;

    final wasMyTurn = _currentTurn == _mySeat;

    _currentTurn = m.turn;
    _diceResult = m.dice;
    _diceStarted = false;
    winners
      ..clear()
      ..addAll(m.winners);

    for (final entry in m.pawns.entries) {
      final p = player(entry.key);
      final steps = entry.value;
      for (int i = 0; i < steps.length && i < p.pawns.length; i++) {
        p.movePawn(i, steps[i]);
      }
    }
    for (final p in players) {
      p.highlightAllPawns(false);
    }
    _isMoving = false;
    _gameState = _finished ? LudoGameState.finish : LudoGameState.throwDice;
    notifyListeners();

    // Play the opponent's roll/move/capture on THIS device too, so sound and
    // haptics fire on both ends for every turn — not just for the acting
    // player. Skipped on the initial [force] load (nothing "happened" yet).
    if (!force) _emitRemoteFeedback(m);

    // Gentle cue the moment control comes back to me.
    if (!force && !wasMyTurn && _currentTurn == _mySeat && !_finished) {
      Haptics.medium();
    }

    _lastRemoteDice = m.dice;
    _lastRemotePawns = {
      for (final e in m.pawns.entries) e.key: List<int>.from(e.value),
    };
  }

  /// Compare a fresh remote snapshot with the last one we applied and play the
  /// matching sound + haptic for whatever the opponent just did.
  void _emitRemoteFeedback(LudoMatch m) {
    var advanced = false; // some pawn moved forward
    var captured = false; // some pawn was sent home (step -> -1)
    for (final entry in m.pawns.entries) {
      final prev = _lastRemotePawns[entry.key];
      final next = entry.value;
      for (int i = 0; i < next.length; i++) {
        final before = (prev != null && i < prev.length) ? prev[i] : -1;
        if (next[i] > before) advanced = true;
        if (before > -1 && next[i] == -1) captured = true;
      }
    }
    final rolled = m.dice != _lastRemoteDice;
    if (!rolled && !advanced && !captured) return; // reaction-only update, etc.

    if (soundEnabled && rolled) Audio.rollDice();
    if (advanced) {
      if (soundEnabled) Audio.playMove();
      Haptics.light();
    }
    if (captured) {
      if (soundEnabled) Audio.playKill();
      Haptics.heavy();
    } else if (rolled && !advanced) {
      Haptics.selection();
    }
  }

  /// Serialize the current board and write it as the authoritative state.
  void _pushOnline() {
    if (!_online || _matchService == null || _matchId == null) return;
    _version++;
    final pawnMap = <LudoPlayerType, List<int>>{
      for (final seat in _activeSeats)
        seat: List<int>.generate(4, (i) => player(seat).pawns[i].step),
    };
    // With N seated players the game ends once N-1 have finished.
    final finished = winners.length >= _endThreshold;
    _finished = finished;
    _matchService!.writeState(
      _matchId!,
      turn: _currentTurn,
      dice: _diceResult,
      winners: List<LudoPlayerType>.from(winners),
      pawns: pawnMap,
      version: _version,
      status: finished ? LudoMatchStatus.finished : null,
    );
  }

  ///Flags to stop pawn once disposed
  bool _stopMoving = false;

  LudoGameState _gameState = LudoGameState.throwDice;

  ///Game state to check if the game is in throw dice state or pick pawn state
  LudoGameState get gameState => _gameState;

  LudoPlayerType _currentTurn = LudoPlayerType.green;

  ///The seat whose turn it currently is.
  LudoPlayerType get currentTurnSeat => _currentTurn;

  int _diceResult = 0;

  ///Dice result to check the dice result of the current turn
  int get diceResult {
    if (_diceResult < 1) {
      return 1;
    } else {
      if (_diceResult > 6) {
        return 6;
      } else {
        return _diceResult;
      }
    }
  }

  bool _diceStarted = false;
  bool get diceStarted => _diceStarted;

  LudoPlayer get currentPlayer =>
      players.firstWhere((element) => element.type == _currentTurn);

  ///Fill all players
  final List<LudoPlayer> players = [];

  ///Player win, we use `LudoPlayerType` to make it easier to check
  final List<LudoPlayerType> winners = [];

  LudoPlayer player(LudoPlayerType type) =>
      players.firstWhere((element) => element.type == type);

  ///This method will check if the pawn can kill another pawn or not by checking the step of the pawn
  bool checkToKill(
    LudoPlayerType type,
    int index,
    int step,
    List<List<double>> path,
  ) {
    bool killSomeone = false;
    for (int i = 0; i < tokens; i++) {
      var greenElement = player(LudoPlayerType.green).pawns[i];
      var blueElement = player(LudoPlayerType.blue).pawns[i];
      var redElement = player(LudoPlayerType.red).pawns[i];
      var yellowElement = player(LudoPlayerType.yellow).pawns[i];

      if ((greenElement.step > -1 &&
              !LudoPath.safeArea
                  .map((e) => e.toString())
                  .contains(
                    player(
                      LudoPlayerType.green,
                    ).path[greenElement.step].toString(),
                  )) &&
          type != LudoPlayerType.green &&
          !_isShielded(LudoPlayerType.green)) {
        if (player(LudoPlayerType.green).path[greenElement.step].toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.green).movePawn(i, -1);
          notifyListeners();
        }
      }
      if ((yellowElement.step > -1 &&
              !LudoPath.safeArea
                  .map((e) => e.toString())
                  .contains(
                    player(
                      LudoPlayerType.yellow,
                    ).path[yellowElement.step].toString(),
                  )) &&
          type != LudoPlayerType.yellow &&
          !_isShielded(LudoPlayerType.yellow)) {
        if (player(LudoPlayerType.yellow).path[yellowElement.step].toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.yellow).movePawn(i, -1);
          notifyListeners();
        }
      }
      if ((blueElement.step > -1 &&
              !LudoPath.safeArea
                  .map((e) => e.toString())
                  .contains(
                    player(
                      LudoPlayerType.blue,
                    ).path[blueElement.step].toString(),
                  )) &&
          type != LudoPlayerType.blue &&
          !_isShielded(LudoPlayerType.blue)) {
        if (player(LudoPlayerType.blue).path[blueElement.step].toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.blue).movePawn(i, -1);
          notifyListeners();
        }
      }
      if ((redElement.step > -1 &&
              !LudoPath.safeArea
                  .map((e) => e.toString())
                  .contains(
                    player(LudoPlayerType.red).path[redElement.step].toString(),
                  )) &&
          type != LudoPlayerType.red &&
          !_isShielded(LudoPlayerType.red)) {
        if (player(LudoPlayerType.red).path[redElement.step].toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.red).movePawn(i, -1);
          notifyListeners();
        }
      }
    }
    return killSomeone;
  }

  ///This is the function that will be called to throw the dice
  void throwDice({bool automated = false}) async {
    if (_stopMoving || _diceStarted || _gameState != LudoGameState.throwDice) {
      return;
    }
    if (isAiTurn && !automated) return;
    final generation = _generation;
    // Only the active seat (or the bot driver, for a bot seat) may roll.
    if (_online && !isMyTurn && !isBotTurn) return;
    _diceStarted = true;
    notifyListeners();
    if (soundEnabled) Audio.rollDice();
    if (!isAiTurn) Haptics.selection();

    //Check if already win skip
    if (winners.contains(currentPlayer.type)) {
      nextTurn();
      return;
    }

    //Turn off highlight for all pawns
    currentPlayer.highlightAllPawns(false);

    Future.delayed(const Duration(seconds: 1)).then((value) {
      if (_stopMoving || generation != _generation) return;
      _diceStarted = false;
      // Fair, uniform 1–6 roll. (The template was rigged with nextBool() to
      // force a 6 ~58% of the time.)
      _diceResult = LudoDicePolicy.adjust(
        _random.nextInt(6) + 1,
        easy: firstMatch,
        isBot: isAiTurn,
        allPawnsHome:
            currentPlayer.pawnInsideCount == currentPlayer.pawns.length,
        random: _random,
      );
      if (powerMode && _luckyFor == _currentTurn) {
        _diceResult = 6;
        _luckyFor = null;
      }
      notifyListeners();
      if (!isAiTurn) Haptics.light();

      if (diceResult == 6) {
        currentPlayer.highlightAllPawns();
        _gameState = LudoGameState.pickPawn;
        notifyListeners();
      } else {
        /// all pawns are inside home
        if (currentPlayer.pawnInsideCount == currentPlayer.pawns.length) {
          nextTurn();
          _pushOnline();
          return;
        } else {
          ///Hightlight all pawn outside
          currentPlayer.highlightOutside();
          _gameState = LudoGameState.pickPawn;
          notifyListeners();
        }
      }

      ///Check and disable if any pawn already in the finish box
      for (var i = 0; i < currentPlayer.pawns.length; i++) {
        var pawn = currentPlayer.pawns[i];
        if ((pawn.step + diceResult) > currentPlayer.path.length - 1) {
          currentPlayer.highlightPawn(i, false);
        }
      }

      ///Automatically move random pawn if all pawn are in same step
      var moveablePawn = currentPlayer.pawns.where((e) => e.highlight).toList();
      if (moveablePawn.length > 1) {
        var biggestStep = moveablePawn.map((e) => e.step).reduce(max);
        if (moveablePawn.every((element) => element.step == biggestStep)) {
          var random = 1 + _random.nextInt(moveablePawn.length - 1);
          if (moveablePawn[random].step == -1) {
            var thePawn = moveablePawn[random];
            move(thePawn.type, thePawn.index, (thePawn.step + 1) + 1);
            return;
          } else {
            var thePawn = moveablePawn[random];
            move(thePawn.type, thePawn.index, (thePawn.step + 1) + diceResult);
            return;
          }
        }
      }

      ///If User have 6 dice, but it inside finish line, it will make him to throw again, else it will turn to next player
      if (currentPlayer.pawns.every((element) => !element.highlight)) {
        if (diceResult == 6) {
          _gameState = LudoGameState.throwDice;
          _pushOnline(); // show the 6; same player rolls again
          return;
        } else {
          nextTurn();
          _pushOnline();
          return;
        }
      }

      if (currentPlayer.pawns.where((element) => element.highlight).length ==
          1) {
        var index = currentPlayer.pawns.indexWhere(
          (element) => element.highlight,
        );
        move(
          currentPlayer.type,
          index,
          currentPlayer.pawns[index].step == -1
              ? 1
              : (currentPlayer.pawns[index].step + 1) + diceResult,
        );
        return; // move() commits and pushes on completion
      }

      // Reaching here means we are waiting for the player to pick among several
      // pawns — publish the dice so opponents see the roll while we choose.
      _pushOnline();
    });
  }

  ///Move pawn to next step and check if it can kill other pawn
  void move(LudoPlayerType type, int index, int step) async {
    if (_isMoving || _stopMoving) return;
    final generation = _generation;
    _isMoving = true;
    _gameState = LudoGameState.moving;

    currentPlayer.highlightAllPawns(false);

    try {
      var selectedPlayer = player(type);
      if (powerMode &&
          _boostFor == type &&
          selectedPlayer.pawns[index].step >= 0) {
        _boostFor = null;
        step = min(step + 3, selectedPlayer.path.length);
      }
      for (int i = selectedPlayer.pawns[index].step; i < step; i++) {
        if (_stopMoving || generation != _generation) return;
        if (selectedPlayer.pawns[index].step == i) continue;
        selectedPlayer.movePawn(index, i);
        // Fixed step pace; the sound is fire-and-forget so a stalled audio
        // load can never freeze the move (and the move lock) mid-way.
        if (soundEnabled) unawaited(Audio.playMove());
        await Future.delayed(const Duration(milliseconds: 220));
        if (!isAiTurn) Haptics.selection();
        if (_stopMoving || generation != _generation) return;
        notifyListeners();
        if (_stopMoving || generation != _generation) return;
      }
      if (checkToKill(type, index, step, selectedPlayer.path)) {
        _grantPower(type);
        _gameState = LudoGameState.throwDice;
        if (soundEnabled) Audio.playKill();
        Haptics.heavy();
        notifyListeners();
        _pushOnline(); // killer rolls again
        return;
      }

      final beforeWin = winners.contains(type);
      validateWin(type);
      if (!beforeWin && winners.contains(type)) Haptics.success();
      if (_gameState == LudoGameState.finish) {
        notifyListeners();
        _pushOnline();
        return;
      }

      if (diceResult == 6) {
        _gameState = LudoGameState.throwDice;
        notifyListeners();
      } else {
        nextTurn();
        notifyListeners();
      }
      _pushOnline();
    } catch (_) {
      // Never let an unexpected error strand the board in the "moving" state:
      // hand the turn back so the player can keep rolling.
      _gameState = LudoGameState.throwDice;
      notifyListeners();
    } finally {
      // Always release the movement lock, whatever happened above.
      if (generation == _generation) _isMoving = false;
      final pending = _pendingRemote;
      _pendingRemote = null;
      if (pending != null && _online && !_stopMoving) _applyRemote(pending);
    }
  }

  /// Force-advance the current turn — used when a player's countdown runs out
  /// in online play so an idle/disconnected seat can't stall the match.
  void skipTurn() {
    if (!_online || (!isMyTurn && !isBotTurn) || _isMoving) return;
    for (final p in players) {
      p.highlightAllPawns(false);
    }
    _diceStarted = false;
    nextTurn();
    _pushOnline();
  }

  /// Nudge an *abandoned* turn forward. Unlike [skipTurn] (which only the active
  /// seat may call for itself), any seated player may call this once the active
  /// seat's clock has clearly expired — so a player who left/backgrounded can't
  /// freeze the whole match. Spectators (no seat) never write.
  void forceAdvanceExpiredTurn() {
    if (!_online || _finished || _isMoving || _mySeat == null) return;
    for (final p in players) {
      p.highlightAllPawns(false);
    }
    _diceStarted = false;
    nextTurn();
    _pushOnline();
  }

  /// Offline (AI/local) countdown timeout: pass the current human turn along.
  /// Never fires online (that path has its own skip), during an AI turn, or
  /// mid-roll/move.
  void skipLocalTurn() {
    if (_online ||
        isAiTurn ||
        _isMoving ||
        _diceStarted ||
        _gameState == LudoGameState.finish ||
        winners.length >= _endThreshold) {
      return;
    }
    for (final p in players) {
      p.highlightAllPawns(false);
    }
    nextTurn();
    notifyListeners();
  }

  ///Next turn will be called when the player finish the turn
  void nextTurn() {
    if (winners.length >= _endThreshold) {
      _gameState = LudoGameState.finish;
      notifyListeners();
      return;
    }
    switch (_currentTurn) {
      case LudoPlayerType.green:
        _currentTurn = LudoPlayerType.yellow;
        break;
      case LudoPlayerType.yellow:
        _currentTurn = LudoPlayerType.blue;
        break;
      case LudoPlayerType.blue:
        _currentTurn = LudoPlayerType.red;
        break;
      case LudoPlayerType.red:
        _currentTurn = LudoPlayerType.green;
        break;
    }

    // Skip players who already finished, and empty seats (online rooms, Quick
    // Ludo 1v1) so the turn only ever lands on a real, still-playing seat.
    final skip =
        winners.contains(_currentTurn) || !_activeSeats.contains(_currentTurn);
    if (skip) return nextTurn();
    final shield = _shieldTurns[_currentTurn];
    if (shield != null) {
      if (shield <= 1) {
        _shieldTurns.remove(_currentTurn);
      } else {
        _shieldTurns[_currentTurn] = shield - 1;
      }
    }
    _gameState = LudoGameState.throwDice;
    notifyListeners();
  }

  ///This function will check if the pawn finish the game or not
  void validateWin(LudoPlayerType color) {
    if (winners.map((e) => e.name).contains(color.name)) return;
    if (player(color).pawns
        .map((e) => e.step)
        .every((element) => element == player(color).path.length - 1)) {
      winners.add(color);
      notifyListeners();
    }

    if (winners.length >= _endThreshold) {
      _gameState = LudoGameState.finish;
    }
  }

  void startGame() {
    _aiTimer?.cancel();
    if (againstAi) {
      _aiTimer = Timer.periodic(
        const Duration(milliseconds: 700),
        (_) => _tickAi(),
      );
    }
    winners.clear();
    // Power Ludo: everyone starts with one of each power-up.
    for (final bag in powers.values) {
      bag
        ..clear()
        ..addAll(powerMode ? PowerUp.values : const <PowerUp>[]);
    }
    _shieldTurns.clear();
    _boostFor = null;
    _luckyFor = null;
    _powerEvent = null;
    players.clear();
    players.addAll([
      LudoPlayer(LudoPlayerType.green, pawnCount: tokens),
      LudoPlayer(LudoPlayerType.yellow, pawnCount: tokens),
      LudoPlayer(LudoPlayerType.blue, pawnCount: tokens),
      LudoPlayer(LudoPlayerType.red, pawnCount: tokens),
    ]);
  }

  /// Full reset for a "Play again" from the game-over screen.
  void resetGame() {
    _generation++;
    _stopMoving = false;
    _isMoving = false;
    _gameState = LudoGameState.throwDice;
    _currentTurn = LudoPlayerType.green;
    _diceResult = 0;
    _diceStarted = false;
    startGame();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopMoving = true;
    _generation++;
    _aiTimer?.cancel();
    _matchSub?.cancel();
    super.dispose();
  }

  static LudoProvider read(BuildContext context) => context.read();
}
