import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import 'package:hash/core/localization/app_region.dart';
import 'package:hash/core/utils/app_snackbar.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:shimmer/shimmer.dart';

/// Hash Store design tokens: black canvas, neon green for money and the main
/// action, purple as the secondary accent.
abstract final class StoreColors {
  static const bg = Color(0xFF050506);
  static const surface = Color(0xFF111114);
  static const surfaceHigh = Color(0xFF1A1A1F);
  static const green = Color(0xff00DC00);
  static const greenSoft = Color(0xFF67FF67);
  static const purple = Color(0xFF7A44C0);
  static const purpleSoft = Color(0xFFB38CFF);
  static const border = Color(0x1FFFFFFF);
  static const muted = Color(0x8CFFFFFF);
  static const faint = Color(0x59FFFFFF);
  static const danger = Color(0xFFFF5A5F);
}

num storeNum(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;

/// Medusa 2 amounts are major units, so INR rupees.
String storeMoney(Object? amount) => Money.format(storeNum(amount));

/// Size-specific tracking: large text tightens, small text opens up a
/// touch for legibility, body sits near zero.
double storeTracking(double size) => size >= 28
    ? -0.03 * size
    : size >= 20
    ? -0.02 * size
    : size >= 15
    ? -0.01 * size
    : size <= 12
    ? 0.1
    : 0;

TextStyle storeDisplay([double size = 22]) => GoogleFonts.orbitron(
  color: Colors.white,
  fontSize: size,
  fontWeight: FontWeight.w700,
  // Orbitron is a wide face, so it gets half the usual tightening.
  letterSpacing: storeTracking(size) / 2,
  height: 1.1,
);

TextStyle storeTitle([double size = 16]) => GoogleFonts.inter(
  color: Colors.white,
  fontSize: size,
  fontWeight: FontWeight.w700,
  letterSpacing: storeTracking(size),
  height: size >= 20 ? 1.15 : 1.25,
);

TextStyle storeBody({
  double size = 13,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w400,
  double? height,
}) => GoogleFonts.inter(
  color: color,
  fontSize: size,
  fontWeight: weight,
  letterSpacing: storeTracking(size),
  height: height,
);

/// Small uppercase label, e.g. "FEATURED DROP".
TextStyle storeEyebrow([Color color = StoreColors.greenSoft]) =>
    GoogleFonts.inter(
      color: color,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
    );

void storeToast(String message, {bool error = false}) {
  // Haptic fires with the message so cause and feedback land together.
  error ? Haptics.error() : Haptics.success();
  AppSnackbar.show(
    error ? 'Hash Store' : 'Added',
    message,
    colorText: Colors.white,
    backgroundColor: error ? const Color(0xE63A0D0D) : const Color(0xE60D2A0D),
    margin: const EdgeInsets.all(12),
    borderRadius: 16,
  );
}

/// Jumps to a shop tab from anywhere in the store, closing pushed pages.
void openShopTab(BuildContext context, int index) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  Get.find<ShopController>().setShopMenuIndex(index);
}

// ------------------------------------------------------------------ chrome

/// Pinned glass header used by every store screen.
class StoreHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final bool showBack;
  final bool showCart;
  const StoreHeader({
    super.key,
    this.eyebrow = 'HASH STORE',
    required this.title,
    this.showBack = false,
    this.showCart = true,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        height: top + 76,
        builder: (shrunk) => ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(showBack ? 4 : 20, top + 8, 12, 10),
              decoration: BoxDecoration(
                // Translucent material while content scrolls under it, no
                // hard divider; solid with an edge under Increase Contrast.
                color: StoreColors.bg.withValues(
                  alpha: shrunk && !storeHighContrast(context) ? 0.72 : 1,
                ),
                border: storeHighContrast(context) && shrunk
                    ? const Border(bottom: BorderSide(color: Colors.white54))
                    : null,
              ),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(eyebrow, style: storeEyebrow()),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: storeDisplay(20),
                        ),
                      ],
                    ),
                  ),
                  if (showCart) const StoreCartButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget Function(bool shrunk) builder;
  _HeaderDelegate({required this.height, required this.builder});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      builder(overlaps || shrinkOffset > 0);

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_HeaderDelegate old) => true;
}

/// Centred Orbitron page title under the Figma profile header, used by the
/// shop's tab screens.
class StoreTabTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const StoreTabTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: storeDisplay(17)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: storeBody(color: StoreColors.muted)),
          ],
        ],
      ),
    ),
  );
}

/// Cart icon with a live item count; opens the Cart tab.
class StoreCartButton extends StatelessWidget {
  const StoreCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select((HashStoreCartCubit c) => c.state.itemCount);
    return Semantics(
      button: true,
      label: count == 0 ? 'Cart' : 'Cart, $count items',
      excludeSemantics: true,
      child: StoreGlassIconButton(
        icon: Icons.shopping_bag_outlined,
        onTap: () => openShopTab(context, 2),
        badge: count == 0 ? null : '$count',
      ),
    );
  }
}

class StoreGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  const StoreGlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: StoreColors.border),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: StorePop(
                trigger: badge,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StoreColors.green,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: StoreColors.bg, width: 2),
                  ),
                  child: Text(
                    badge!,
                    style: storeBody(
                      size: 10,
                      color: Colors.black,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Sticky blurred bar for a screen's main action.
class StoreBottomBar extends StatelessWidget {
  final Widget child;
  const StoreBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: StoreColors.bg.withValues(
            alpha: storeHighContrast(context) ? 1 : 0.78,
          ),
          // Bright top edge: light catching the material.
          border: Border(
            top: BorderSide(
              color: storeHighContrast(context)
                  ? Colors.white54
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// "Total ₹848" stacked label used beside a bottom-bar button.
class StoreTotalLabel extends StatelessWidget {
  final String label;
  final Object? amount;
  const StoreTotalLabel({super.key, this.label = 'Total', this.amount});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: storeBody(size: 11, color: StoreColors.muted)),
      const SizedBox(height: 2),
      Text(
        storeMoney(amount),
        style: storeTitle(20).copyWith(color: StoreColors.greenSoft),
      ),
    ],
  );
}

// -------------------------------------------------------------- primitives

class StoreImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  const StoreImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StoreColors.surfaceHigh, StoreColors.surface],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.white24,
        size: 28,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (url == null || url!.isEmpty)
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 250),
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}

class StorePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Gradient? gradient;
  const StorePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = StoreColors.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? StoreColors.surface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}

/// Titled block, e.g. "Delivery address".
class StoreSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const StoreSection({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(title, style: storeTitle(15))),
            ?trailing,
          ],
        ),
      ),
      child,
    ],
  );
}

/// Pill button: filled neon for the main action, outlined otherwise.
class StoreButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool filled;
  final IconData? icon;
  final double height;
  const StoreButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.filled = true,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    final fg = filled ? Colors.black : Colors.white;
    final fgShown = enabled || loading ? fg : fg.withValues(alpha: 0.5);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: BounceTap(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: filled
                ? (enabled || loading
                      ? StoreColors.green
                      : StoreColors.green.withValues(alpha: 0.3))
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(height / 2),
            border: filled ? null : Border.all(color: StoreColors.border),
          ),
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19, color: fgShown),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: storeBody(
                          size: 15,
                          color: fgShown,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class StoreStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StoreStatusChip(
    this.label, {
    super.key,
    this.color = StoreColors.greenSoft,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: storeBody(size: 11, color: color, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Empty / error placeholder with an optional action.
class StoreMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const StoreMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 56, 32, 40),
    child: Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                StoreColors.green.withValues(alpha: 0.18),
                StoreColors.green.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: StoreColors.green.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, size: 36, color: StoreColors.greenSoft),
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: storeTitle(18)),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: storeBody(color: StoreColors.muted, height: 1.45),
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: StoreButton(
              label: actionLabel!,
              onTap: onAction,
              height: 48,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Shimmering placeholder block.
class StoreSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const StoreSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: StoreColors.surface,
    highlightColor: StoreColors.surfaceHigh,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: StoreColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

/// − n + control.
class StoreQtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool compact;
  const StoreQtyStepper({
    super.key,
    required this.value,
    this.onMinus,
    this.onPlus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 54.0;
    Widget btn(IconData icon, String tip, VoidCallback? onTap) => SizedBox(
      width: size,
      height: size,
      child: IconButton(
        tooltip: tip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: compact ? 16 : 20),
        color: Colors.white,
        disabledColor: Colors.white24,
      ),
    );
    return Container(
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: StoreColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, 'Decrease quantity', onMinus),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 18 : 24),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: storeBody(
                size: compact ? 14 : 16,
                weight: FontWeight.w700,
              ),
            ),
          ),
          btn(Icons.add_rounded, 'Increase quantity', onPlus),
        ],
      ),
    );
  }
}

/// Server totals for a cart or order. Never computed on the client.
class StoreTotals extends StatelessWidget {
  final Map<String, dynamic> cart;
  const StoreTotals({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, Object? value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? storeTitle(16)
                  : storeBody(color: StoreColors.muted),
            ),
          ),
          Text(
            label == 'Delivery' && storeNum(value) == 0
                ? 'Free'
                : storeMoney(value),
            style: strong
                ? storeTitle(18).copyWith(color: StoreColors.greenSoft)
                : storeBody(weight: FontWeight.w600),
          ),
        ],
      ),
    );

    final hasShipping = (cart['shipping_methods'] as List? ?? []).isNotEmpty;
    return StorePanel(
      child: Column(
        children: [
          row('Subtotal', cart['item_subtotal'] ?? cart['subtotal']),
          if (hasShipping) row('Delivery', cart['shipping_total']),
          if (storeNum(cart['tax_total']) > 0) row('Tax', cart['tax_total']),
          if (storeNum(cart['discount_total']) > 0)
            row('Discount', -storeNum(cart['discount_total'])),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: StoreColors.border, height: 1),
          ),
          row('Total', cart['total'], strong: true),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- behaviour

/// Adds to the shared cart, asking first when the open cart holds another
/// partner's items (the backend allows one vendor per cart).
Future<bool> addProductToCart(
  BuildContext context,
  Map<String, dynamic> product, {
  int quantity = 1,
}) async {
  final cubit = context.read<HashStoreCartCubit>();
  try {
    await cubit.addItem(product, quantity: quantity);
  } on VendorMismatch {
    if (!context.mounted) return false;
    final replace = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: StoreColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('Start a new cart?', style: storeTitle(20)),
              const SizedBox(height: 10),
              Text(
                'Your cart has items from another partner. Each order comes '
                'from one partner, so adding '
                '${product['title'] ?? 'this'} clears your current cart.',
                style: storeBody(color: StoreColors.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              StoreButton(
                label: 'Start new cart',
                onTap: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              StoreButton(
                label: 'Keep current cart',
                filled: false,
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (replace != true) return false;
    try {
      await cubit.addItem(product, quantity: quantity, replaceCart: true);
    } catch (e) {
      storeToast(e.toString(), error: true);
      return false;
    }
  } catch (e) {
    storeToast(e.toString(), error: true);
    return false;
  }
  storeToast('${product['title'] ?? 'Item'} is in your cart');
  return true;
}

// ------------------------------------------------------------------ motion
//
// Follows Apple's fluid-interface rules: springs instead of fixed curves,
// critically damped unless a gesture carried momentum, motion that starts
// from the current on-screen value, and a gentle cross-fade (not nothing)
// when Reduce Motion is on.

bool storeReduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Increase Contrast on iOS: drop translucency for solid surfaces.
bool storeHighContrast(BuildContext context) =>
    MediaQuery.maybeHighContrastOf(context) ?? false;

/// Apple-style spring from damping ratio and response (seconds), the two
/// numbers Apple tunes instead of mass/stiffness/damping.
SpringDescription storeSpring({double damping = 1, double response = 0.35}) {
  final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
  return SpringDescription(
    mass: 1,
    stiffness: stiffness,
    damping: damping * 2 * math.sqrt(stiffness),
  );
}

/// Perspective matrix shared by the 3D effects.
Matrix4 storePerspective({double rotateX = 0, double rotateY = 0}) =>
    Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(rotateX)
      ..rotateY(rotateY);

/// Tilts its child in 3D toward the finger, tracking 1:1, and springs back
/// critically damped from wherever it is when released or interrupted.
class StoreTilt extends StatefulWidget {
  final Widget child;

  /// Maximum rotation in radians.
  final double maxAngle;
  const StoreTilt({super.key, required this.child, this.maxAngle = 0.12});

  @override
  State<StoreTilt> createState() => _StoreTiltState();
}

class _StoreTiltState extends State<StoreTilt> with TickerProviderStateMixin {
  late final _x = AnimationController.unbounded(vsync: this);
  late final _y = AnimationController.unbounded(vsync: this);

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    // Grabbing mid-spring stops it where it is; no jump.
    _x.stop();
    _y.stop();
    _x.value = (local.dx / size.width - 0.5).clamp(-0.5, 0.5) * 2;
    _y.value = (local.dy / size.height - 0.5).clamp(-0.5, 0.5) * 2;
  }

  void _release() {
    // Independent X and Y springs, critically damped: no wobble.
    final spring = storeSpring(response: 0.4);
    _x.animateWith(SpringSimulation(spring, _x.value, 0, _x.velocity));
    _y.animateWith(SpringSimulation(spring, _y.value, 0, _y.velocity));
  }

  @override
  Widget build(BuildContext context) {
    if (storeReduceMotion(context)) return widget.child;
    return LayoutBuilder(
      builder: (context, c) => Listener(
        onPointerDown: (e) => _track(e.localPosition, c.biggest),
        onPointerMove: (e) => _track(e.localPosition, c.biggest),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_x, _y]),
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: storePerspective(
              rotateX: -_y.value * widget.maxAngle,
              rotateY: _x.value * widget.maxAngle,
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Materialises content: rises a little while scaling up from 96% and
/// fading in, staggered by [index]. Reduce Motion gets a plain fade.
class StoreEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  const StoreEntrance({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final reduce = storeReduceMotion(context);
    final delay = 0.1 * index.clamp(0, 6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: reduce ? 200 : 420 + 50 * index.clamp(0, 6),
      ),
      curve: reduce
          ? Curves.easeOut
          : Interval(delay / (1 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: reduce
            ? child
            : Transform(
                alignment: Alignment.bottomCenter,
                transform: storePerspective(rotateX: (1 - t) * 0.12)
                  ..translateByDouble(0, 14 * (1 - t), 0, 1)
                  ..scaleByDouble(0.96 + 0.04 * t, 0.96 + 0.04 * t, 1, 1),
                child: child,
              ),
      ),
      child: child,
    );
  }
}

/// A short, non-overshooting bump whenever [trigger] changes, e.g. a cart
/// count. Status changes don't carry momentum, so no bounce.
class StorePop extends StatelessWidget {
  final Object? trigger;
  final Widget child;
  const StorePop({super.key, required this.trigger, required this.child});

  @override
  Widget build(BuildContext context) {
    if (storeReduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 1.25, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: child,
    );
  }
}
