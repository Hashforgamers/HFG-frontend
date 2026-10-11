import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How special a cosmetic is; shops group items under these headings.
enum CosmeticRarity {
  normal('NORMAL', Color(0xFFC9C0FF)),
  premium('PREMIUM', Color(0xFFFFD60A)),
  legendary('LEGENDARY', Color(0xFFFF5FA2));

  const CosmeticRarity(this.label, this.color);
  final String label;
  final Color color;
}

/// A theme or skin for a mini game, bought with HashCoins. [look] is whatever
/// the game needs to draw it (colours, mostly).
///
/// Ids are `<slot>_<name>`; every slot's free default is `<slot>_classic`.
class Cosmetic<T> {
  const Cosmetic({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.look,
  });

  final String id;
  final String name;
  final String tagline;

  /// HashCoins; 0 means everyone owns it.
  final int price;
  final T look;

  CosmeticRarity get rarity => price >= 2500
      ? CosmeticRarity.legendary
      : (price >= 1000 ? CosmeticRarity.premium : CosmeticRarity.normal);
}

/// Which mini-game cosmetics this player owns and has equipped, one choice
/// per slot (e.g. `pac_theme`).
///
/// Kept on the device per account and mirrored to
/// `mini_game_cosmetics/<uid>` so a purchase follows the player to another
/// phone.
class CosmeticStore extends ChangeNotifier {
  CosmeticStore({this.spend, this.mirror = true});

  static final CosmeticStore instance = CosmeticStore();

  static const collection = 'mini_game_cosmetics';

  /// Debits the item's price and returns the new balance; defaults to the
  /// HashCoin API.
  final Future<int> Function(Cosmetic<Object?> item)? spend;

  /// Whether to sync with Firestore (off in tests).
  final bool mirror;

  final Set<String> _owned = {};
  final Map<String, String> _selected = {};
  String? _loadedFor;

  static String defaultOf(String slot) => '${slot}_classic';

  bool owns(String id) => id.endsWith('_classic') || _owned.contains(id);

  /// The id equipped in [slot].
  String selected(String slot) => _selected[slot] ?? defaultOf(slot);

  /// The equipped item of [slot] out of its catalog [items].
  Cosmetic<T> pick<T>(String slot, List<Cosmetic<T>> items) {
    final id = selected(slot);
    return items.firstWhere((i) => i.id == id, orElse: () => items.first);
  }

  String get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  String get _ownedKey => 'cosmetics_owned_$_uid';
  String get _selectedKey => 'cosmetics_selected_$_uid';

  /// Loads this account's cosmetics once; later calls are free.
  Future<void> load() async {
    final uid = _uid;
    if (_loadedFor == uid) return;
    _loadedFor = uid;
    _owned.clear();
    _selected.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      _owned.addAll(prefs.getStringList(_ownedKey) ?? const []);
      for (final entry in prefs.getStringList(_selectedKey) ?? const []) {
        final i = entry.indexOf(':');
        if (i > 0) _selected[entry.substring(0, i)] = entry.substring(i + 1);
      }
      if (mirror && uid != 'guest') {
        final snap = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 3));
        final remote = snap.data()?['owned'];
        if (remote is List) _owned.addAll(remote.map((e) => e.toString()));
        await prefs.setStringList(_ownedKey, _owned.toList());
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Cosmetics load failed: $e');
    }
    _selected.removeWhere((_, id) => !owns(id));
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_ownedKey, _owned.toList());
      await prefs.setStringList(_selectedKey, [
        for (final e in _selected.entries) '${e.key}:${e.value}',
      ]);
      final uid = _uid;
      if (mirror && uid != 'guest') {
        await FirebaseFirestore.instance.collection(collection).doc(uid).set({
          if (_owned.isNotEmpty)
            'owned': FieldValue.arrayUnion(_owned.toList()),
          'selected': _selected,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Cosmetics save failed: $e');
    }
  }

  /// Uses an owned item in [slot].
  Future<void> equip(String slot, String id) async {
    if (!owns(id) || selected(slot) == id) return;
    _selected[slot] = id;
    notifyListeners();
    await _save();
  }

  /// Pays for [item], then owns and equips it in [slot]. Returns the new
  /// HashCoin balance; throws (and changes nothing) if the payment fails.
  Future<int> buy(String slot, Cosmetic<Object?> item) async {
    if (owns(item.id)) throw StateError('Already owned');
    final balance =
        await (spend ??
            (i) => locator<RemoteRepoInterface>().spendHashCoins(
              amount: i.price,
              source: 'mini_game_cosmetic',
              referenceId: 'cosmetic_${i.id}_$_uid',
            ))(item);
    _owned.add(item.id);
    _selected[slot] = item.id;
    notifyListeners();
    await _save();
    return balance;
  }
}
