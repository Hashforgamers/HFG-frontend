import 'package:flutter/material.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_play_api.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_qr_scanner_view.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_session_view.dart';
import 'package:hash/core/localization/app_region.dart';
import 'package:intl/intl.dart';

/// Cafe wallet amounts are INR paise regardless of the app's region.
String cafeMoney(int paise) => Money.format(
  paise / 100,
  currency: 'INR',
  decimals: paise % 100 == 0 ? 0 : 2,
);

/// Scan a PC QR, then let the gamer start a paid booking or buy time from
/// their balance at that cafe. The backend deducts the wallet on PC ack.
Future<void> startCafeScanFlow(BuildContext context) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final raw = await navigator.push<String>(
    MaterialPageRoute(builder: (_) => const CafeQrScannerView()),
  );
  if (raw == null) return;
  final qr = CafePlayApi.extractQrToken(raw);
  if (qr == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'That isn\'t a Hash PC code. Scan the QR on the PC screen.',
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  final session = await showModalBottomSheet<CafeSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CafeCheckoutSheet(qr: qr),
  );
  if (session == null) return;
  navigator.push(
    MaterialPageRoute(builder: (_) => CafeSessionView(initial: session)),
  );
}

class CafeCheckoutSheet extends StatefulWidget {
  const CafeCheckoutSheet({super.key, required this.qr});

  final String qr;

  @override
  State<CafeCheckoutSheet> createState() => _CafeCheckoutSheetState();
}

class _CafeCheckoutSheetState extends State<CafeCheckoutSheet> {
  final _api = CafePlayApi.instance;

  CafeCheckout? _checkout;
  String? _error;
  String? _notice;
  bool _loading = true;
  bool _submitting = false;
  CafeDuration? _selected;

  // An idempotency key is reused for retries of the same intent (e.g. after a
  // timeout) and regenerated only when the intent changes.
  String? _intent;
  String? _intentKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? notice}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final checkout = await _api.getCheckout(widget.qr);
      if (!mounted) return;
      final durations = checkout.policy.durations;
      setState(() {
        _checkout = checkout;
        _notice = notice;
        _selected = durations.isEmpty
            ? null
            : durations.firstWhere(
                (d) =>
                    d.minutes == _selected?.minutes &&
                    d.amount == _selected?.amount,
                orElse: () => durations.first,
              );
        _loading = false;
      });
    } on CafePlayException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _keyFor(String intent) {
    if (_intent != intent || _intentKey == null) {
      _intent = intent;
      _intentKey = CafePlayApi.newIdempotencyKey();
    }
    return _intentKey!;
  }

  Future<void> _submit(
    Future<CafeSession> Function(String key) call,
    String intent,
  ) async {
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      final session = await call(_keyFor(intent));
      if (mounted) Navigator.of(context).pop(session);
    } on CafePlayException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.isUnknownOutcome) {
        // Keep the key: tapping again safely replays the same request.
        setState(() => _notice = '${e.message} Tap again to retry.');
        return;
      }
      _intent = null;
      _intentKey = null;
      if (e.statusCode == 409) {
        // Price change, busy PC or low balance — refresh so the user sees
        // the current state before confirming again.
        await _load(notice: e.message);
      } else {
        setState(() => _notice = e.message);
      }
    }
  }

  Future<void> _openActive(String sessionId) async {
    setState(() => _submitting = true);
    try {
      final session = await _api.getSession(sessionId);
      if (mounted) Navigator.of(context).pop(session);
    } on CafePlayException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _notice = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: BookingColors.bgElevated,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BookingRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BookingSpacing.lg,
            BookingSpacing.md,
            BookingSpacing.lg,
            BookingSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BookingColors.borderStrong,
                    borderRadius: BorderRadius.circular(BookingRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: BookingSpacing.lg),
              Flexible(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _checkout == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: BookingColors.accent),
        ),
      );
    }
    final checkout = _checkout;
    if (checkout == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline,
            color: BookingColors.danger,
            size: 40,
          ),
          const SizedBox(height: BookingSpacing.md),
          Text(
            _error ?? 'Could not load this PC.',
            textAlign: TextAlign.center,
            style: BookingText.body(context),
          ),
          const SizedBox(height: BookingSpacing.xl),
          BookingSecondaryButton(label: 'Try again', onPressed: _load),
        ],
      );
    }

    final policy = checkout.policy;
    final selected = _selected;
    final canAfford =
        selected != null && checkout.availableBalance >= selected.amount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(checkout.cafeName, style: BookingText.title(context)),
          const SizedBox(height: BookingSpacing.xs),
          Text(
            'PC ${checkout.consoleNumber}',
            style: BookingText.secondary(context),
          ),
          const SizedBox(height: BookingSpacing.lg),
          _WalletBalanceCard(balance: checkout.availableBalance),
          if (_notice != null) ...[
            const SizedBox(height: BookingSpacing.md),
            _Notice(text: _notice!),
          ],
          if (checkout.activeSessionId != null) ...[
            const SizedBox(height: BookingSpacing.xl),
            BookingPrimaryButton(
              label: 'View running session',
              icon: Icons.play_circle_fill_rounded,
              loading: _submitting,
              onPressed: () => _openActive(checkout.activeSessionId!),
            ),
          ] else ...[
            if (!policy.selfService) ...[
              const SizedBox(height: BookingSpacing.md),
              const _Notice(
                text:
                    'Self check-in is turned off at this cafe. Please ask at the desk.',
              ),
            ],
            if (checkout.bookings.isNotEmpty) ...[
              const SizedBox(height: BookingSpacing.xl),
              Text('YOUR BOOKINGS', style: BookingText.sectionLabel(context)),
              const SizedBox(height: BookingSpacing.sm),
              for (final b in checkout.bookings)
                _BookingTile(
                  booking: b,
                  enabled: policy.selfService && !_submitting,
                  onStart: () => _submit(
                    (key) => _api.startBooking(
                      qr: widget.qr,
                      bookingId: b.bookingId,
                      idempotencyKey: key,
                    ),
                    'booking:${b.bookingId}',
                  ),
                ),
            ],
            if (policy.durations.isNotEmpty) ...[
              const SizedBox(height: BookingSpacing.xl),
              Text(
                checkout.bookings.isEmpty
                    ? 'BUY PLAY TIME'
                    : 'OR BUY A NEW SESSION',
                style: BookingText.sectionLabel(context),
              ),
              const SizedBox(height: BookingSpacing.sm),
              Wrap(
                spacing: BookingSpacing.sm,
                runSpacing: BookingSpacing.sm,
                children: [
                  for (final d in policy.durations)
                    _DurationChip(
                      duration: d,
                      selected: identical(d, selected),
                      onTap: _submitting
                          ? null
                          : () => setState(() => _selected = d),
                    ),
                ],
              ),
              const SizedBox(height: BookingSpacing.lg),
              if (selected != null && !canAfford)
                Padding(
                  padding: const EdgeInsets.only(bottom: BookingSpacing.md),
                  child: _Notice(
                    text:
                        'Not enough cafe balance. Top up ${cafeMoney(selected.amount - checkout.availableBalance)} at the cafe desk.',
                  ),
                ),
              BookingPrimaryButton(
                label: selected == null
                    ? 'Select a duration'
                    : 'Pay ${cafeMoney(selected.amount)} from cafe wallet',
                icon: Icons.account_balance_wallet_rounded,
                loading: _submitting,
                enabled: policy.selfService && canAfford,
                onPressed: selected == null
                    ? null
                    : () => _submit(
                        (key) => _api.buyWalletTime(
                          qr: widget.qr,
                          duration: selected,
                          idempotencyKey: key,
                        ),
                        'wallet:${selected.minutes}:${selected.amount}',
                      ),
              ),
              const SizedBox(height: BookingSpacing.sm),
              Text(
                'Amount is held now and charged only when the PC unlocks.',
                textAlign: TextAlign.center,
                style: BookingText.muted(context),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      highlight: true,
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: BookingColors.accent,
          ),
          const SizedBox(width: BookingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cafe wallet balance',
                  style: BookingText.secondary(context),
                ),
                Text(
                  'Only usable at this cafe',
                  style: BookingText.muted(context),
                ),
              ],
            ),
          ),
          Text(cafeMoney(balance), style: BookingText.title(context)),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.enabled,
    required this.onStart,
  });

  final CafeBookingOption booking;
  final bool enabled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');
    final time = (booking.startsAt != null && booking.endsAt != null)
        ? '${fmt.format(booking.startsAt!)} – ${fmt.format(booking.endsAt!)}'
        : '';
    return BookingCard(
      margin: const EdgeInsets.only(bottom: BookingSpacing.sm),
      padding: const EdgeInsets.all(BookingSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.gameName, style: BookingText.body(context)),
                if (time.isNotEmpty)
                  Text(time, style: BookingText.secondary(context)),
                if (!booking.canStart && (booking.reason ?? '').isNotEmpty)
                  Text(
                    booking.reason!,
                    style: BookingText.muted(
                      context,
                    ).copyWith(color: BookingColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BookingSpacing.sm),
          SizedBox(
            width: 96,
            child: BookingPrimaryButton(
              label: 'Start',
              height: 40,
              enabled: enabled && booking.canStart,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final CafeDuration duration;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(BookingRadius.chip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? BookingColors.accentDim : BookingColors.surface,
          borderRadius: BorderRadius.circular(BookingRadius.chip),
          border: Border.all(
            color: selected ? BookingColors.accent : BookingColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(duration.label, style: BookingText.body(context)),
            Text(
              cafeMoney(duration.amount),
              style: BookingText.secondary(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BookingSpacing.md),
      decoration: BoxDecoration(
        color: BookingColors.warningDim,
        borderRadius: BorderRadius.circular(BookingRadius.chip),
      ),
      child: Text(
        text,
        style: BookingText.secondary(
          context,
        ).copyWith(color: BookingColors.warning),
      ),
    );
  }
}
