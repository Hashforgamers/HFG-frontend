import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import '../../hash_store/pages/categories_view.dart';
import '../../hash_store/pages/hash_store_cart_view.dart';
import '../../hash_store/pages/hash_store_home_page.dart';
import '../../hash_store/pages/hash_store_orders_view.dart';

class ShopMenuView extends GetView<ShopController> {
  const ShopMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final index = controller.shopMenuIndex.value;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _buildShopSection(index),
            );
          }),
          const _DelayedComingSoonLock(),
        ],
      ),
    );
  }

  Widget _buildShopSection(int index) {
    switch (index) {
      case 0:
        return const HashStoreHomePage(key: ValueKey('shop_home'));
      case 1:
        return const CategoriesView(key: ValueKey('shop_categories'));
      case 2:
        return const HashStoreCartView(key: ValueKey('shop_cart'));
      case 3:
        return const HashStoreOrdersView(key: ValueKey('shop_orders'));
      default:
        return const HashStoreHomePage(key: ValueKey('shop_default'));
    }
  }
}

class _DelayedComingSoonLock extends StatefulWidget {
  const _DelayedComingSoonLock();

  @override
  State<_DelayedComingSoonLock> createState() => _DelayedComingSoonLockState();
}

class _DelayedComingSoonLockState extends State<_DelayedComingSoonLock> {
  Timer? _revealTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _revealTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _isVisible = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return AbsorbPointer(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 13 * value, sigmaY: 13 * value),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.42 * value),
                child: SafeArea(
                  child: Center(
                    child: Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.94 + (0.06 * value),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth < 360
              ? constraints.maxWidth - 40
              : 300.0;
          return Semantics(
            label: 'Hash Shop coming soon',
            child: SizedBox(
              width: cardWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xF21E1E21), Color(0xF20C0C0F)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: const Color(0xFF00DC00).withValues(alpha: 0.08),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_fill,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'HASH SHOP',
                        style: TextStyle(
                          color: Color(0xFF67FF67),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Coming Soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We’re putting the final polish on a premium shopping experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
