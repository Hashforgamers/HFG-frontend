import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/localization/app_region.dart';
import 'package:hash/core/utils/app_snackbar.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import 'tournament_theme.dart';

String money(num amount, [String currency = 'INR']) =>
    Money.format(amount, currency: currency);

String fee(Tournament t) => t.isFree ? 'Free' : money(t.entryFee, t.currency);

String fmtDate(DateTime? d) =>
    d == null ? 'TBA' : DateFormat('d MMM').format(d);

String fmtDateTime(DateTime? d) =>
    d == null ? 'TBA' : DateFormat('d MMM, h:mm a').format(d);

/// "in 3h 20m" / "2d left" style countdown; anchored to [now] (server time
/// when available) so a skewed phone clock does not mislead.
String countdown(DateTime? to, {DateTime? now}) {
  if (to == null) return '';
  final diff = to.difference(now ?? DateTime.now());
  if (diff.isNegative) return 'now';
  if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
  if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
  return '${diff.inMinutes.clamp(1, 59)}m';
}

void toast(String message, {bool error = false}) => AppSnackbar.show(
  error ? 'Something went wrong' : 'Done',
  message,
  snackPosition: SnackPosition.BOTTOM,
  colorText: Colors.white,
  backgroundColor: error ? const Color(0xFF3A1414) : const Color(0xFF15301C),
);

void toastError(Object e) =>
    toast(TournamentApiException.from(e).message, error: true);

Color statusColor(TStatus s) => switch (s) {
  TStatus.registrationOpen => CT.success,
  TStatus.live => CT.error,
  TStatus.published => CT.verifiedBlue,
  TStatus.completed || TStatus.cancelled => CT.muted,
  _ => CT.primary,
};

Color stateColor(String s) => switch (s) {
  'confirmed' ||
  'approved' ||
  'completed' ||
  'paid' ||
  'verified' => CT.success,
  'pending_payment' ||
  'pending' ||
  'pending_admin_approval' ||
  'awaiting_results' ||
  'result_pending' ||
  'refund_pending' ||
  'invited' => CT.primary,
  'in_progress' || 'live' => CT.error,
  'disputed' || 'rejected' || 'disqualified' || 'failed' || 'open' => CT.error,
  _ => CT.onSurfaceVariant,
};

String humanize(String s) {
  final t = s.replaceAll('_', ' ').trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

class TPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const TPill(this.label, {super.key, this.color = CT.primary, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
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
          style: CT.body(11.5, color: color, w: FontWeight.w600),
        ),
      ],
    ),
  );
}

class TPanel extends StatelessWidget {
  final Widget child;
  final Color? border;
  final EdgeInsets padding;
  const TPanel({
    super.key,
    required this.child,
    this.border,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: CT.card(borderColor: border ?? CT.outline),
    child: child,
  );
}

class TSectionTitle extends StatelessWidget {
  final String title;
  final String? accent;
  final Widget? trailing;
  const TSectionTitle(this.title, {super.key, this.trailing, this.accent});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title, style: CT.headline(18, w: FontWeight.w800)),
                if (accent != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Text(accent!, style: CT.headline(18, w: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Text painted in the brand gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: CT.brand.createShader,
    child: Text(text, style: style),
  );
}

/// Primary actions use the brand gradient; secondary ones are frosted outlines.
class TButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final IconData? icon;
  final bool secondary;
  final Color? color;
  final double height;
  const TButton(
    this.label, {
    super.key,
    this.onTap,
    this.busy = false,
    this.icon,
    this.secondary = false,
    this.color,
    this.height = 52,
  });

  const TButton.secondary(
    this.label, {
    super.key,
    this.onTap,
    this.busy = false,
    this.icon,
    this.color,
    this.height = 52,
  }) : secondary = true;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final fg = secondary ? (color ?? CT.onSurface) : Colors.white;
    final content = busy
        ? const AppLinearLoader.button()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CT.headline(15, color: fg, w: FontWeight.w800),
                ),
              ),
            ],
          );
    final radius = BorderRadius.circular(height / 2);
    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: secondary
                ? null
                : color == null
                    ? CT.brand
                    : LinearGradient(colors: [color!, Color.lerp(color, Colors.black, 0.25)!]),
            color: secondary ? Colors.white.withValues(alpha: 0.05) : null,
            border: secondary
                ? Border.all(color: (color ?? Colors.white).withValues(alpha: color == null ? 0.16 : 0.55))
                : null,
            boxShadow: secondary || !enabled
                ? null
                : [
                    BoxShadow(
                      color: (color ?? CT.pink).withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onTap : null,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented filter with a gradient thumb, used for list views.
class TSegments extends StatelessWidget {
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  const TSegments({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: CT.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: CT.outline),
    ),
    child: Row(
      children: [
        for (final e in options.entries)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: e.key == value ? Colors.white.withValues(alpha: 0.14) : null,
                ),
                child: Text(
                  e.value,
                  style: CT.headline(13.5,
                      color: e.key == value ? Colors.white : CT.onSurfaceVariant,
                      w: e.key == value ? FontWeight.w800 : FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class TLoading extends StatelessWidget {
  const TLoading({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: AppLinearLoader.screen(),
  );
}

class TMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const TMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  factory TMessage.error(Object error, VoidCallback retry) => TMessage(
    icon: Icons.wifi_off_rounded,
    title: 'Could not load',
    subtitle: TournamentApiException.from(error).message,
    actionLabel: 'Retry',
    onAction: retry,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: Icon(icon, size: 34, color: CT.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: CT.headline(17, w: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, textAlign: TextAlign.center, style: CT.body(13.5)),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 18),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: TButton(actionLabel!, onTap: onAction, height: 46),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Tournament banner with a bundled fallback image.
class TBanner extends StatelessWidget {
  final String? url;
  final double? height;
  final BorderRadius radius;
  const TBanner(
    this.url, {
    super.key,
    this.height,
    this.radius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    // Branded placeholder: the bundled stock art did not fit every game.
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2130), Color(0xFF13161E), Color(0xFF0B0D12)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(Icons.emoji_events_rounded, size: 170, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            left: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent]),
              ),
            ),
          ),
        ],
      ),
    );
    final u = url ?? '';
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: u.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: u,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => fallback,
                placeholder: (_, _) => Container(color: CT.surfaceHigh),
              )
            : fallback,
      ),
    );
  }
}

class TFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const TFact(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: CT.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: CT.primary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: CT.body(13.5))),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: CT.headline(14, w: FontWeight.w700),
        ),
      ),
    ],
  );
}

/// The list card used by discovery and "my tournaments": a full-bleed banner
/// with the title over it, a prize badge, and a slots meter.
class TournamentCard extends StatelessWidget {
  final Tournament t;
  final VoidCallback onTap;
  final Widget? badge;
  const TournamentCard(this.t, {super.key, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final s = t.status;
    final fill = t.maxPlayers <= 0 ? 0.0 : (t.registeredCount / t.maxPlayers).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: CT.card(borderColor: CT.outline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 168,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TBanner(
                        t.bannerUrl,
                        radius: const BorderRadius.vertical(top: Radius.circular(21)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66000000), Colors.transparent, Color(0xF00B0D12)],
                            stops: [0, 0.35, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _glassPill(
                          s.label.toUpperCase(),
                          statusColor(s),
                          dot: s == TStatus.live || s == TStatus.registrationOpen,
                        ),
                      ),
                      if (t.prizePool > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: CT.gold.withValues(alpha: 0.5)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.emoji_events_rounded, size: 14, color: CT.gold),
                              const SizedBox(width: 4),
                              Text(money(t.prizePool, t.currency),
                                  style: CT.headline(12.5, color: Colors.white, w: FontWeight.w800)),
                            ]),
                          ),
                        ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [t.game, t.modeLabel].where((e) => e.isNotEmpty).join(' · ').toUpperCase(),
                              style: CT.mono(10.5, color: CT.primaryBright, w: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CT.display(19),
                                  ),
                                ),
                                if (t.isPrivate) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.lock_rounded, size: 16, color: CT.verifiedBlue),
                                ],
                                if (badge != null) ...[const SizedBox(width: 6), badge!],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      _stat('Entry', fee(t)),
                      _stat('Starts', fmtDate(t.startAt)),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.registeredCount}/${t.maxPlayers} ${t.isSolo ? 'players' : 'teams'}',
                                style: CT.headline(13.5, w: FontWeight.w700)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: Stack(children: [
                                Container(height: 5, color: Colors.white.withValues(alpha: 0.08)),
                                FractionallySizedBox(
                                  widthFactor: fill,
                                  child: Container(height: 5, color: CT.primary),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String v) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: CT.headline(13.5, w: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: CT.body(11.5, color: CT.muted)),
      ],
    ),
  );
}

Widget _glassPill(String label, Color color, {bool dot = false}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.55),
    borderRadius: BorderRadius.circular(99),
    border: Border.all(color: color.withValues(alpha: 0.5)),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    if (dot) ...[
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
    ],
    Text(label, style: CT.mono(10, color: Colors.white, w: FontWeight.w800)),
  ]),
);


Future<bool> confirmAction(
  String title,
  String message, {
  String confirm = 'Confirm',
  bool destructive = false,
}) async =>
    await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: CT.surfaceHigh,
        title: Text(title, style: CT.headline(17)),
        content: Text(message, style: CT.body(14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: CT.body(14, color: CT.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirm,
              style: CT.headline(
                14,
                color: destructive ? CT.error : CT.primary,
              ),
            ),
          ),
        ],
      ),
    ) ??
    false;

/// A one-field (or multi-line) text prompt. Returns null when dismissed.
Future<String?> promptText(
  String title, {
  String? hint,
  String? initial,
  bool multiline = false,
  bool required = true,
  TextInputType? keyboard,
  String confirm = 'Save',
}) async {
  final c = TextEditingController(text: initial);
  final result = await Get.dialog<String>(
    AlertDialog(
      backgroundColor: CT.surfaceHigh,
      title: Text(title, style: CT.headline(17)),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLines: multiline ? 4 : 1,
        keyboardType: keyboard,
        style: CT.body(14, color: CT.onSurface),
        decoration: tInput(hint ?? ''),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel', style: CT.body(14)),
        ),
        TextButton(
          onPressed: () {
            final v = c.text.trim();
            if (required && v.isEmpty) return;
            Get.back(result: v);
          },
          child: Text(confirm, style: CT.headline(14, color: CT.primary)),
        ),
      ],
    ),
  );
  return result;
}

InputDecoration tInput(String hint, {String? label}) => InputDecoration(
  hintText: hint,
  labelText: label,
  hintStyle: CT.body(14, color: CT.muted),
  labelStyle: CT.body(13),
  filled: true,
  fillColor: CT.surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: CT.outline),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: CT.outline),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: CT.primary),
  ),
);

Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    toast('Could not open link', error: true);
  }
}

PreferredSizeWidget tAppBar(
  String title, {
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) => AppBar(
  backgroundColor: CT.bg,
  surfaceTintColor: Colors.transparent,
  foregroundColor: CT.onSurface,
  elevation: 0,
  title: Text(title, style: CT.headline(17)),
  actions: actions,
  bottom: bottom,
);

TabBar tTabs(List<String> labels, {bool scrollable = false}) => TabBar(
  isScrollable: scrollable,
  tabAlignment: scrollable ? TabAlignment.start : null,
  indicatorColor: CT.primary,
  labelColor: CT.onSurface,
  unselectedLabelColor: CT.muted,
  dividerColor: CT.hairline,
  labelStyle: CT.headline(13.5),
  unselectedLabelStyle: CT.body(13.5),
  tabs: [for (final l in labels) Tab(text: l)],
);
