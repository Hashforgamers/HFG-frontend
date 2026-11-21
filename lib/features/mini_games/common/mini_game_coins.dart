import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/repositories/model/hash_coin_spend.dart';
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

  /// What to tell the player when the server refuses a spend.
  static String refusalMessage(HashCoinSpendException e, int amount) {
    if (e.insufficient) {
      return e.balance == null
          ? 'You need $amount HashCoins.'
          : 'You need $amount HashCoins. You have ${e.balance}.';
    }
    if (e.notSold) return 'This isn’t available yet. Please try again later.';
    return 'Couldn’t spend HashCoins. Please try again.';
  }

  /// Debits [amount] for [source] (e.g. `pac_man_continue`) and refreshes the
  /// wallet. Returns whether the player now has what they paid for; when they
  /// don't, they are told why and nothing is charged. A spinner covers the
  /// screen meanwhile unless [showLoader] is false (the caller shows its own).
  ///
  /// One reference id is used for the whole attempt, including the automatic
  /// retry after a dropped connection, so the server can never debit twice.
  static Future<bool> spend(
    BuildContext context, {
    required int amount,
    required String source,
    bool showLoader = true,
  }) async {
    final close = showLoader ? _showProcessing(context) : null;
    try {
      return await _spend(context, amount: amount, source: source);
    } finally {
      close?.call();
    }
  }

  /// Covers the screen with a spinner while the server is charging, so a slow
  /// connection doesn't look like a frozen game. Returns the function that
  /// takes it down again.
  static VoidCallback _showProcessing(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    var open = true;
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: _ProcessingCard()),
        ),
      ).whenComplete(() => open = false),
    );
    return () {
      if (open && navigator.mounted) navigator.pop();
    };
  }

  static Future<bool> _spend(
    BuildContext context, {
    required int amount,
    required String source,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    void say(String message) => messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    void refreshWallet() {
      if (!context.mounted) return;
      try {
        BlocProvider.of<HashCoinCubit>(context).getHashCoin();
      } catch (_) {
        // ignore if cubit context is unavailable
      }
    }

    final repo = locator<RemoteRepoInterface>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final referenceId =
        '${source}_${uid}_${DateTime.now().millisecondsSinceEpoch}';
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await repo.spendHashCoins(
          amount: amount,
          source: source,
          referenceId: referenceId,
        );
        refreshWallet();
        return true;
      } on HashCoinSpendException catch (e) {
        if (kDebugMode) AppLogger.d('HashCoin spend refused ($source): $e');
        if (e.alreadyOwned) {
          // a permanent item bought earlier (other device, lost reply): theirs, no charge
          refreshWallet();
          return true;
        }
        say(refusalMessage(e, amount));
        return false;
      } catch (e) {
        // no answer from the server: try once more with the same reference
        if (kDebugMode) AppLogger.d('HashCoin spend failed ($source): $e');
        if (attempt == 0) continue;
        say(
          'Couldn’t reach the server. Check your connection and try again.',
        );
        return false;
      }
    }
    return false;
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF14171F),
      borderRadius: BorderRadius.circular(18),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4C342)),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Spending HashCoins…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
