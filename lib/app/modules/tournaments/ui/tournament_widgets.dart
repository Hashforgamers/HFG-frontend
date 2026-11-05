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
  final Widget? trailing;
  const TSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(title, style: CT.headline(16))),
        ?trailing,
      ],
    ),
  );
}

class TButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final IconData? icon;
  final bool secondary;
  final Color? color;
  const TButton(
    this.label, {
    super.key,
    this.onTap,
    this.busy = false,
    this.icon,
    this.secondary = false,
    this.color,
  });

  const TButton.secondary(
    this.label, {
    super.key,
    this.onTap,
    this.busy = false,
    this.icon,
    this.color,
  }) : secondary = true;

  @override
  Widget build(BuildContext context) {
    final c = color ?? CT.primary;
    final enabled = onTap != null && !busy;
    final content = busy
        ? const AppLinearLoader.button()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: secondary ? c : Colors.black),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: CT.headline(14.5, color: secondary ? c : Colors.black),
                ),
              ),
            ],
          );
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: secondary
          ? OutlinedButton(
              onPressed: enabled ? onTap : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: c.withValues(alpha: enabled ? 0.7 : 0.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: c,
                disabledBackgroundColor: c.withValues(alpha: busy ? 0.6 : 0.25),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: content,
            ),
    );
  }
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
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: CT.muted),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: CT.headline(16)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, textAlign: TextAlign.center, style: CT.body(13)),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: TButton.secondary(actionLabel!, onTap: onAction),
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
    const fallback = Image(
      image: AssetImage('assets/hash_store_images/tournament_banner.png'),
      fit: BoxFit.cover,
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
      Icon(icon, size: 18, color: CT.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: CT.body(13))),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: CT.headline(13.5),
        ),
      ),
    ],
  );
}

/// The list card used by discovery and "my tournaments".
class TournamentCard extends StatelessWidget {
  final Tournament t;
  final VoidCallback onTap;
  final Widget? badge;
  const TournamentCard(this.t, {super.key, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final s = t.status;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: CT.card(borderColor: CT.outline),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                TBanner(t.bannerUrl, height: 132),
                Positioned(
                  left: 12,
                  top: 12,
                  child: TPill(
                    s.label,
                    color: statusColor(s),
                    icon: s == TStatus.live ? Icons.circle : null,
                  ),
                ),
                if (t.isPrivate)
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: TPill(
                      'Private',
                      color: CT.verifiedBlue,
                      icon: Icons.lock_rounded,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CT.headline(16),
                        ),
                      ),
                      ?badge,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      t.game,
                      t.modeLabel,
                      t.formatLabel,
                    ].where((e) => e.isNotEmpty).join(' · '),
                    style: CT.body(12.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat(
                        Icons.emoji_events_rounded,
                        t.prizePool > 0
                            ? money(t.prizePool, t.currency)
                            : 'No prize',
                      ),
                      _stat(Icons.confirmation_number_rounded, fee(t)),
                      _stat(
                        Icons.groups_rounded,
                        '${t.registeredCount}/${t.maxPlayers}',
                      ),
                      _stat(Icons.event_rounded, fmtDate(t.startAt)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData i, String v) => Expanded(
    child: Row(
      children: [
        Icon(i, size: 14, color: CT.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CT.body(12, color: CT.onSurface, w: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
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
