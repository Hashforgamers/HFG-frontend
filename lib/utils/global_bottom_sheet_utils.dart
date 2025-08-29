import 'package:flutter/material.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/global_bottom_sheet_service.dart';

/// Utility class to demonstrate how to use the global bottom sheet service
/// from anywhere in the app
class GlobalBottomSheetUtils {
  
  /// Show hash coin redemption bottom sheet from anywhere in the app
  static Future<void> showHashCoinRedemption(
    BuildContext context, {
    required int hashCoin,
  }) async {
    final globalBottomSheetService = locator<GlobalBottomSheetService>();
    
    await globalBottomSheetService.showHashCoinRedemptionBottomSheet(
      context,
      hashCoin: hashCoin,
      onSuccess: (message) {
        globalBottomSheetService.showSuccessSnackbar(context, message);
      },
      onError: (message) {
        globalBottomSheetService.showErrorSnackbar(context, message);
      },
      onLoading: () {
        globalBottomSheetService.showLoadingSnackbar(context);
      },
    );
  }

  /// Example of how to show the bottom sheet from a button press
  static Widget createRedeemButton({
    required BuildContext context,
    required int hashCoin,
    String buttonText = 'Redeem HashCoins',
  }) {
    return ElevatedButton(
      onPressed: () {
        showHashCoinRedemption(context, hashCoin: hashCoin);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xffDE3A3A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(buttonText),
    );
  }

  /// Example of how to show the bottom sheet from a floating action button
  static Widget createRedeemFAB({
    required BuildContext context,
    required int hashCoin,
  }) {
    return FloatingActionButton.extended(
      onPressed: () {
        showHashCoinRedemption(context, hashCoin: hashCoin);
      },
      backgroundColor: const Color(0xffDE3A3A),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.card_giftcard),
      label: const Text('Redeem'),
    );
  }

  /// Example of how to show the bottom sheet from an app bar action
  static List<Widget> createAppBarActions({
    required BuildContext context,
    required int hashCoin,
  }) {
    return [
      IconButton(
        onPressed: () {
          showHashCoinRedemption(context, hashCoin: hashCoin);
        },
        icon: const Icon(Icons.card_giftcard),
        tooltip: 'Redeem HashCoins',
      ),
    ];
  }
}

/// Example usage in any widget:
/// 
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         actions: GlobalBottomSheetUtils.createAppBarActions(
///           context: context,
///           hashCoin: 15000,
///         ),
///       ),
///       body: Center(
///         child: GlobalBottomSheetUtils.createRedeemButton(
///           context: context,
///           hashCoin: 15000,
///         ),
///       ),
///       floatingActionButton: GlobalBottomSheetUtils.createRedeemFAB(
///         context: context,
///         hashCoin: 15000,
///       ),
///     );
///   }
/// }
/// ``` 