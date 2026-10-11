import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';

/// Spending HashCoins inside mini games (continues, hints, ...).
class MiniGameCoins {
  /// What things cost, in HashCoins.
  static const arrowEscapeContinue = 2000;
  static const arrowEscapeHint = 200;
  static const pacManContinue = 1000;
  static const hashRushContinue = 1000;
  static const plantVsZombieContinue = 1000;
  static const wordlyReveal = 300;

  /// The signed-in player's HashCoin balance, or null when it can't be read.
  static Future<int?> balance() async {
    try {
      return await locator<RemoteRepoInterface>().getHashCoin();
    } catch (_) {
      return null;
    }
  }

  /// Debits [amount] for [source] (e.g. `pac_man_continue`) and refreshes the
  /// wallet. Returns whether it was paid; when it wasn't, the player is told
  /// why and nothing is charged.
  static Future<bool> spend(
    BuildContext context, {
    required int amount,
    required String source,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    void say(String message) => messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    try {
      final repo = locator<RemoteRepoInterface>();
      final balance = await repo.getHashCoin();
      if (balance < amount) {
        say('You need $amount HashCoins. You have $balance.');
        return false;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      await repo.spendHashCoins(
        amount: amount,
        source: source,
        referenceId:
            '${source}_${uid}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (context.mounted) {
        try {
          BlocProvider.of<HashCoinCubit>(context).getHashCoin();
        } catch (_) {
          // ignore if cubit context is unavailable
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) AppLogger.d('HashCoin spend failed ($source): $e');
      say('Couldn’t spend HashCoins. Please try again.');
      return false;
    }
  }
}
