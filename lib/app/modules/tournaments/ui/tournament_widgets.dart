import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:get/get.dart';
import 'package:hash/core/localization/app_region.dart';
import 'package:hash/core/utils/app_snackbar.dart';
import 'package:hash/core/utils/share_origin.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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

/// Accent word in a heading. Plain white: the shop style uses no gradients.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) => Text(text, style: style);
}

/// Shop-style pill: solid green with black text for the main action,
/// a quiet outlined pill otherwise. [color] tints a danger action.
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
    final fill = color ?? CT.success;
    final fg = secondary ? (color ?? Colors.white) : (color == null ? Colors.black : Colors.white);
    final radius = BorderRadius.circular(height / 2);
    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: secondary ? Colors.white.withValues(alpha: 0.06) : fill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: secondary
                ? BorderSide(color: color?.withValues(alpha: 0.5) ?? CT.outline)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
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
                              style: CT.headline(15, color: fg, w: FontWeight.w700),
                            ),
                          ),
                        ],
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
                  color: e.key == value ? CT.purple : null,
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
    icon: PhosphorIconsBold.wifiSlash,
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
            child: Icon(PhosphorIconsBold.trophy, size: 170, color: Colors.white.withValues(alpha: 0.06)),
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
      Icon(icon, size: 18, color: CT.muted),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: CT.body(13.5, color: CT.onSurfaceVariant))),
      Flexible(
        child: Text(value, textAlign: TextAlign.right, style: CT.headline(14, w: FontWeight.w600)),
      ),
    ],
  );
}

/// The list card used by discovery and "my tournaments", built like the
/// shop's product cards: photo on top, details underneath.
class TournamentCard extends StatelessWidget {
  final Tournament t;
  final VoidCallback onTap;
  final Widget? badge;
  const TournamentCard(this.t, {super.key, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final s = t.status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: CT.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CT.outline),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 2.2, child: TBanner(t.bannerUrl)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TPill(s.label, color: statusColor(s)),
                        if (t.isPrivate) ...[
                          const SizedBox(width: 6),
                          const TPill('Private', color: CT.onSurfaceVariant, icon: PhosphorIconsBold.lock),
                        ],
                        const Spacer(),
                        ?badge,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CT.headline(16.5, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [t.game, t.modeLabel, 'Starts ${fmtDate(t.startAt)}']
                          .where((e) => e.isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CT.body(12.5, color: CT.muted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fee(t), style: CT.headline(18, w: FontWeight.w800)),
                        if (t.prizePool > 0) ...[
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '${money(t.prizePool, t.currency)} prize pool',
                              style: CT.body(12.5, color: CT.successBright, w: FontWeight.w600),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${t.registeredCount}/${t.maxPlayers} ${t.isSolo ? 'players' : 'teams'}',
                            style: CT.body(12.5, color: CT.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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
  iconTheme: const IconThemeData(color: Colors.white),
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

/// Shares a tournament's link (and invite code when private).
void shareTournament(Tournament t, BuildContext context) {
  SharePlus.instance.share(
    ShareParams(
      text:
          '${t.title} · ${t.game}\n${fee(t)} entry'
          '${t.prizePool > 0 ? ' · ${money(t.prizePool, t.currency)} prize pool' : ''}\n'
          'https://www.hashforgamers.com/tournament/${t.id}'
          '${t.isPrivate && t.inviteCode != null ? '\nInvite code: ${t.inviteCode}' : ''}',
      sharePositionOrigin: shareOriginRect(context),
    ),
  );
}
