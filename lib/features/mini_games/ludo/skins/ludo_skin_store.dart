import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/core/repositories/model/hash_coin_spend.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ludo_board_theme.dart';
import 'ludo_dice_skin.dart';
import 'ludo_skin.dart';

/// Which Ludo skins, board themes and dice this player owns and has
/// equipped.
///
/// Kept on the device per account and mirrored to `ludo_skins/<uid>` so a
/// purchase follows the player to another phone.
class LudoSkinStore extends ChangeNotifier {
  LudoSkinStore({this.spend, this.mirror = true});

  static final LudoSkinStore instance = LudoSkinStore();

  static const collection = 'ludo_skins';

  static const _free = [
    LudoSkin.classicId,
    LudoBoardTheme.classicId,
    LudoDiceSkin.classicId,
  ];

  /// Debits the item's price and returns the new balance; defaults to the
  /// HashCoin API.
  final Future<int> Function(LudoShopItem item)? spend;

  /// Whether to sync with Firestore (off in tests).
  final bool mirror;

  final Set<String> _owned = {..._free};
  String _selected = LudoSkin.classicId;
  String _selectedBoard = LudoBoardTheme.classicId;
  String _selectedDice = LudoDiceSkin.classicId;
  String? _loadedFor;

  /// The equipped pawn skin.
  String get selected => _selected;

  /// The equipped board theme (shared with the table when hosting).
  String get selectedBoard => _selectedBoard;

  /// The equipped dice (shown to rivals on this player's rolls).
  String get selectedDice => _selectedDice;

  bool isEquipped(String id) =>
      id == _selected || id == _selectedBoard || id == _selectedDice;
  bool owns(String id) => _owned.contains(id);

  String get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  String get _ownedKey => 'ludo_skins_owned_$_uid';
  String get _selectedKey => 'ludo_skin_selected_$_uid';
  String get _boardKey => 'ludo_board_selected_$_uid';
  String get _diceKey => 'ludo_dice_selected_$_uid';

  /// Loads this account's items once; later calls are free.
  Future<void> load() async {
    final uid = _uid;
    if (_loadedFor == uid) return;
    _loadedFor = uid;
    _owned
      ..clear()
      ..addAll(_free);
    _selected = LudoSkin.classicId;
    _selectedBoard = LudoBoardTheme.classicId;
    _selectedDice = LudoDiceSkin.classicId;
    try {
      final prefs = await SharedPreferences.getInstance();
      _owned.addAll(prefs.getStringList(_ownedKey) ?? const []);
      _selected = prefs.getString(_selectedKey) ?? _selected;
      _selectedBoard = prefs.getString(_boardKey) ?? _selectedBoard;
      _selectedDice = prefs.getString(_diceKey) ?? _selectedDice;
      if (mirror && uid != 'guest') {
        final snap = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get()
            // Never hold up a match on a slow connection.
            .timeout(const Duration(seconds: 3));
        final remote = snap.data()?['owned'];
        if (remote is List) _owned.addAll(remote.map((e) => e.toString()));
        await prefs.setStringList(_ownedKey, _owned.toList());
      }
      if (uid != 'guest' && spend == null) {
        // the HashCoin ledger is the source of truth for what was paid for
        final purchases = await locator<RemoteRepoInterface>()
            .getHashCoinPurchases()
            .timeout(const Duration(seconds: 4));
        final bought = HashCoinPurchase.itemIds(
          purchases,
          'ludo_skin_purchase',
        );
        if (bought.isNotEmpty && !_owned.containsAll(bought)) {
          _owned.addAll(bought);
          await prefs.setStringList(_ownedKey, _owned.toList());
        }
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Ludo skins load failed: $e');
    }
    if (!owns(_selected)) _selected = LudoSkin.classicId;
    if (!owns(_selectedBoard)) _selectedBoard = LudoBoardTheme.classicId;
    if (!owns(_selectedDice)) _selectedDice = LudoDiceSkin.classicId;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_ownedKey, _owned.toList());
      await prefs.setString(_selectedKey, _selected);
      await prefs.setString(_boardKey, _selectedBoard);
      await prefs.setString(_diceKey, _selectedDice);
      final uid = _uid;
      if (mirror && uid != 'guest') {
        await FirebaseFirestore.instance.collection(collection).doc(uid).set({
          'owned': FieldValue.arrayUnion(_owned.toList()),
          'selected': _selected,
          'selected_board': _selectedBoard,
          'selected_dice': _selectedDice,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Ludo skins save failed: $e');
    }
  }

  void _select(String id) {
    if (LudoBoardTheme.isBoard(id)) {
      _selectedBoard = id;
    } else if (LudoDiceSkin.isDice(id)) {
      _selectedDice = id;
    } else {
      _selected = id;
    }
  }

  /// Uses an owned pawn skin, board theme or dice.
  Future<void> equip(String id) async {
    if (!owns(id) || isEquipped(id)) return;
    _select(id);
    notifyListeners();
    await _save();
  }

  /// Pays for [item], then owns and equips it. Returns the new HashCoin
  /// balance; throws (and changes nothing) if the payment fails.
  Future<int> buy(LudoShopItem item) async {
    if (owns(item.id)) throw StateError('Already owned');
    int balance;
    try {
      balance =
          await (spend ??
              (s) => locator<RemoteRepoInterface>().spendHashCoins(
                amount: s.price,
                source: 'ludo_skin_purchase',
                itemId: s.id,
                referenceId: 'ludo_skin_${s.id}_$_uid',
              ))(item);
    } on HashCoinSpendException catch (e) {
      // bought before (another device, or the reply was lost): theirs, no charge
      if (!e.alreadyOwned) rethrow;
      balance = e.balance ?? await locator<RemoteRepoInterface>().getHashCoin();
    }
    _owned.add(item.id);
    _select(item.id);
    notifyListeners();
    await _save();
    return balance;
  }
}
