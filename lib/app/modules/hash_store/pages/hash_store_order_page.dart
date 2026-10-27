import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/core/utils/haptics.dart';

String storeDate(Object? iso, [String pattern = 'd MMM yyyy, h:mm a']) {
  final d = DateTime.tryParse('${iso ?? ''}');
  return d == null ? '' : DateFormat(pattern).format(d.toLocal());
}

class HashStoreOrderPage extends StatefulWidget {
  final String orderId;
  final bool justPlaced;
  final MedusaStoreService? store;
  const HashStoreOrderPage({
    super.key,
    required this.orderId,
    this.justPlaced = false,
    this.store,
  });

  @override
  State<HashStoreOrderPage> createState() => _HashStoreOrderPageState();
}

class _HashStoreOrderPageState extends State<HashStoreOrderPage>
    with WidgetsBindingObserver {
  MedusaStoreService get _store => widget.store ?? MedusaStoreService.instance;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _completion;
  String? _error;
  String? _trackingError;
  Map<String, dynamic>? _tracking;
  Timer? _poll;
  bool _loading = false;
  bool _foreground = true;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _poll?.cancel();
    if (_foreground) _load();
  }

  Future<void> _load() async {
    if (_loading || !mounted) return;
    _poll?.cancel();
    _loading = true;
    try {
      final order = await _store.order(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
      });
      try {
        final result = await _store.tracking(widget.orderId);
        if (!mounted) return;
        setState(() {
          _completion = result['order'] is Map
              ? Map<String, dynamic>.from(result['order'])
              : null;
          _tracking = result['tracking'] is Map
              ? Map<String, dynamic>.from(result['tracking'])
              : null;
          if (_completion != null) {
            _completion!['on_hold'] =
                _tracking?['on_hold'] ?? _completion!['on_hold'];
            if (_tracking?['status'] == 'canceled') {
              _completion!['completion_eligible'] = false;
            }
          }
          _trackingError = null;
        });
        _failures = 0;
      } catch (e) {
        _failures++;
        if (mounted) {
          setState(
            () => _trackingError = e is StoreException && e.statusCode == 404
                ? 'Tracking is being prepared. Pull to refresh or check again shortly.'
                : 'Could not refresh tracking. Showing the last available update.',
          );
        }
      }
    } catch (e) {
      _failures++;
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _loading = false;
      if (mounted && _foreground) {
        final seconds = 30 * (1 << _failures.clamp(0, 3));
        _poll = Timer.periodic(Duration(seconds: seconds), (_) {
          if (_foreground && (ModalRoute.of(context)?.isCurrent ?? false)) {
            _load();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: StoreColors.bg,
      body: RefreshIndicator(
        color: StoreColors.green,
        backgroundColor: StoreColors.surface,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            StoreHeader(
              title: order == null
                  ? 'Order'
                  : 'Order #${order['display_id'] ?? ''}',
              eyebrow: order == null
                  ? 'HASH STORE'
                  : storeDate(order['created_at']).toUpperCase(),
              showBack: true,
              showCart: false,
            ),
            if (order == null)
              SliverToBoxAdapter(
                child: _error == null
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            StoreSkeleton(height: 90, radius: 20),
                            SizedBox(height: 12),
                            StoreSkeleton(height: 220, radius: 20),
                          ],
                        ),
                      )
                    : StoreMessage(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load this order',
                        body: _error,
                        actionLabel: 'Try again',
                        onAction: _load,
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverList.list(
                  children: [
                    if (widget.justPlaced) ...[
                      const _PlacedBanner(),
                      const SizedBox(height: 16),
                    ],
                    if (_trackingError != null || _error != null) ...[
                      Text(
                        _trackingError ?? _error!,
                        style: storeBody(color: Colors.orangeAccent),
                      ),
                      const SizedBox(height: 12),
                    ],
                    StoreOrderTracker(status: _tracking),
                    const SizedBox(height: 16),
                    _CompletionCard(
                      orderId: widget.orderId,
                      status: _trackingError == null && _error == null
                          ? _completion
                          : null,
                      onRefresh: _load,
                    ),
                    const SizedBox(height: 24),
                    StoreSection(
                      title: 'Items',
                      child: StorePanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            for (final item in (order['items'] as List? ?? []))
                              _ItemRow(
                                item: Map<String, dynamic>.from(item as Map),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (order['shipping_address'] is Map) ...[
                      const SizedBox(height: 20),
                      StoreSection(
                        title: 'Delivery to',
                        child: _AddressBlock(
                          Map<String, dynamic>.from(
                            order['shipping_address'] as Map,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    StoreSection(
                      title: 'Payment summary',
                      child: StoreTotals(cart: order),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlacedBanner extends StatefulWidget {
  const _PlacedBanner();

  @override
  State<_PlacedBanner> createState() => _PlacedBannerState();
}

class _PlacedBannerState extends State<_PlacedBanner> {
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Haptic and confetti on the same frame, so they read as one event.
      Haptics.success();
      if (!storeReduceMotion(context)) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform(
          alignment: Alignment.center,
          transform: storePerspective(rotateX: (1 - t) * 1.2)
            ..scaleByDouble(0.8 + 0.2 * t, 0.8 + 0.2 * t, 1, 1),
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        ),
        child: StorePanel(
          borderColor: StoreColors.green.withValues(alpha: 0.6),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              StoreColors.green.withValues(alpha: 0.18),
              StoreColors.surface,
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StoreColors.green,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order placed', style: storeDisplay(18)),
                    const SizedBox(height: 4),
                    Text(
                      'The partner has it. Track it here any time.',
                      style: storeBody(size: 12, color: StoreColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ConfettiWidget(
        confettiController: _confetti,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        emissionFrequency: 0.08,
        numberOfParticles: 22,
        maxBlastForce: 22,
        minBlastForce: 8,
        gravity: 0.25,
        colors: const [
          StoreColors.green,
          StoreColors.greenSoft,
          StoreColors.purpleSoft,
          Colors.white,
        ],
      ),
    ],
  );
}

/// One code digit that flips down into place, staggered by [index].
class _FlipDigit extends StatelessWidget {
  final String digit;
  final int index;
  const _FlipDigit({super.key, required this.digit, required this.index});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 42,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StoreColors.green.withValues(alpha: 0.5)),
      ),
      child: Text(
        digit,
        style: storeDisplay(24).copyWith(color: StoreColors.greenSoft),
      ),
    );
    if (storeReduceMotion(context)) return box;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Interval(index * 0.12, 1, curve: Curves.easeOutBack),
      builder: (_, t, child) => Transform(
        alignment: Alignment.topCenter,
        transform: storePerspective(rotateX: (1 - t) * -1.5),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: box,
    );
  }
}

/// Placed → Paid → Completed.
String storeTrackingLabel(Object? status) =>
    const {
      'placed': 'Order placed',
      'payment_confirmed': 'Payment confirmed',
      'preparing': 'Preparing your order',
      'shipped': 'Shipped',
      'out_for_delivery': 'Out for delivery',
      'delivery_attempted': 'Delivery attempted',
      'delivered': 'Delivery confirmed',
      'ready_for_service': 'Ready for service',
      'in_progress': 'Service in progress',
      'completed': 'Service completed',
      'canceled': 'Order canceled',
      'carrier_delivered': 'Courier reports delivered — awaiting OTP',
      'return_in_progress': 'Return in progress',
      'carrier_update': 'Carrier update',
    }[status] ??
    'Order update';

Uri? storeTrackingUri(Object? value) {
  final uri = Uri.tryParse('$value');
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

List<Map<String, dynamic>> storeTimeline(Map<String, dynamic>? tracking) {
  final entries = (tracking?['timeline'] as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  // Stable ordering keeps repeated notes, even when their timestamps match.
  final indexed = entries.indexed.toList();
  indexed.sort((a, b) {
    final ad = DateTime.tryParse('${a.$2['at']}');
    final bd = DateTime.tryParse('${b.$2['at']}');
    final result = ad == null
        ? (bd == null ? 0 : 1)
        : bd == null
        ? -1
        : ad.compareTo(bd);
    return result == 0 ? a.$1.compareTo(b.$1) : result;
  });
  return indexed.map((e) => e.$2).toList();
}

class StoreOrderTracker extends StatelessWidget {
  final Map<String, dynamic>? status;
  const StoreOrderTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final entries = storeTimeline(status);
    Widget details(Map<String, dynamic> data) {
      final uri = storeTrackingUri(data['tracking_url']);
      final expected = data['expected_delivery'];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['courier'] != null)
            Text('${data['courier']}', style: storeBody()),
          if (data['tracking_number'] != null)
            Text('Tracking: ${data['tracking_number']}', style: storeBody()),
          if (expected != null)
            Text(
              'Estimated delivery: $expected',
              style: storeBody(color: StoreColors.muted),
            ),
          if (uri != null)
            TextButton.icon(
              onPressed: () async {
                try {
                  if (!await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  )) {
                    storeToast('Could not open tracking link.', error: true);
                  }
                } catch (_) {
                  storeToast('Could not open tracking link.', error: true);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Track with courier'),
            ),
        ],
      );
    }

    return StorePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status == null
                ? 'Tracking is being prepared'
                : storeTrackingLabel(status!['status']),
            style: storeTitle(17),
          ),
          if (status?['on_hold'] == true)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Order on hold — under review',
                style: storeBody(color: Colors.orangeAccent),
              ),
            ),
          if (status != null) details(status!),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 12, color: StoreColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeTrackingLabel(entry['status']),
                          style: storeBody(weight: FontWeight.w600),
                        ),
                        if (entry['at'] != null)
                          Text(
                            storeDate(entry['at']),
                            style: storeBody(
                              size: 11,
                              color: StoreColors.muted,
                            ),
                          ),
                        if (entry['note'] != null)
                          Text(
                            '${entry['note']}',
                            style: storeBody(color: StoreColors.muted),
                          ),
                        details(entry),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Updates refresh automatically. Courier sync can take about 15 minutes.',
            style: storeBody(size: 11, color: StoreColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Delivery/service completion: the shopper asks for an in-app code and
/// shares it with the partner only after delivery or the session.
class _CompletionCard extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? status;
  final Future<void> Function() onRefresh;
  const _CompletionCard({
    required this.orderId,
    required this.status,
    required this.onRefresh,
  });

  @override
  State<_CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends State<_CompletionCard> {
  Map<String, dynamic>? _otp;
  bool _requesting = false;
  DateTime? _resendAt;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      final otp = await MedusaStoreService.instance.requestCompletionOtp(
        widget.orderId,
      );
      if (!mounted) return;
      _tick?.cancel();
      // Server enforces the 60 s cooldown; this only keeps the button honest.
      _resendAt = DateTime.now().add(const Duration(seconds: 60));
      _tick = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() {});
        final expires = DateTime.tryParse('${_otp?['expires_at']}');
        if (expires != null && !DateTime.now().isBefore(expires)) {
          setState(() => _otp = null);
          t.cancel();
        }
      });
      Haptics.medium();
      setState(() => _otp = otp);
    } catch (e) {
      storeToast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final completedAt = s?['completed_at'];
    final paid = s?['paid'] == true;
    final eligible = s?['completion_eligible'] == true;
    final refresh = StoreButton(
      label: 'Refresh status',
      icon: Icons.refresh_rounded,
      filled: false,
      height: 46,
      onTap: widget.onRefresh,
    );

    if (completedAt != null) {
      return _info(
        icon: Icons.task_alt_rounded,
        title: 'All done',
        body: 'Confirmed by the partner on ${storeDate(completedAt)}.',
      );
    }
    if (s == null) {
      return _info(
        icon: Icons.hourglass_top_rounded,
        title: 'Confirming your order',
        body: 'This can take a moment after checkout.',
        action: refresh,
      );
    }
    if (s['on_hold'] == true || !paid || !eligible) {
      return _info(
        icon: Icons.schedule_rounded,
        title: s['on_hold'] == true
            ? 'Order under review'
            : paid
            ? 'Completion not available yet'
            : 'Waiting for payment confirmation',
        body: 'Your completion code unlocks once the order is ready.',
        action: refresh,
      );
    }

    final otp = _otp;
    final secondsLeft = _resendAt == null
        ? 0
        : _resendAt!.difference(DateTime.now()).inSeconds.clamp(0, 60);
    final code = otp?['code']?.toString();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StoreColors.purple.withValues(alpha: 0.35),
            StoreColors.surface,
          ],
        ),
        border: Border.all(color: StoreColors.purple.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMPLETION CODE', style: storeEyebrow()),
                const SizedBox(height: 8),
                Text(
                  code == null
                      ? 'Get your code only when the delivery or session is '
                            'done, then share it with the partner.'
                      : '${otp!['instruction'] ?? 'Share this code with the partner after delivery or service completion.'}',
                  style: storeBody(
                    size: 13,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const _Perforation(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                if (code != null) ...[
                  Semantics(
                    label: 'Completion code ${code.split('').join(' ')}',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final (i, digit) in code.split('').indexed)
                          _FlipDigit(
                            key: ValueKey('$code$i'),
                            digit: digit,
                            index: i,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Expires ${storeDate(otp!['expires_at'], 'h:mm a')}',
                    style: storeBody(size: 12, color: StoreColors.muted),
                  ),
                  const SizedBox(height: 16),
                ],
                StoreButton(
                  label: code == null
                      ? 'Show completion OTP'
                      : secondsLeft > 0
                      ? 'New code in ${secondsLeft}s'
                      : 'Get a new code',
                  icon: code == null ? Icons.key_rounded : null,
                  filled: code == null,
                  height: code == null ? 54 : 46,
                  loading: _requesting,
                  onTap: secondsLeft > 0 ? null : _request,
                ),
                if (code != null)
                  TextButton(
                    onPressed: widget.onRefresh,
                    child: Text(
                      'Partner confirmed? Refresh status',
                      style: storeBody(size: 12, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info({
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) => StorePanel(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StoreColors.green.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: StoreColors.greenSoft, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: storeTitle(15)),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: storeBody(size: 12, color: StoreColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );
}

/// Ticket tear line with notches.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -10,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: StoreColors.bg,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: StoreColors.bg,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: LayoutBuilder(
              builder: (_, c) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  (c.maxWidth / 10).floor(),
                  (_) =>
                      Container(width: 5, height: 1.5, color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        StoreImage(
          url: item['thumbnail'] as String?,
          width: 52,
          height: 52,
          radius: 12,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['product_title'] ?? item['title'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: storeBody(weight: FontWeight.w600),
              ),
              Text(
                'Qty ${item['quantity'] ?? 1}',
                style: storeBody(size: 12, color: StoreColors.muted),
              ),
            ],
          ),
        ),
        Text(
          storeMoney(
            item['total'] ??
                storeNum(item['unit_price']) * storeNum(item['quantity']),
          ),
          style: storeBody(weight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _AddressBlock extends StatelessWidget {
  final Map<String, dynamic> a;
  const _AddressBlock(this.a);

  @override
  Widget build(BuildContext context) {
    final name = '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
    final lines = [
      a['address_1'],
      a['address_2'],
      [
        a['city'],
        a['province'],
        a['postal_code'],
      ].where((v) => '${v ?? ''}'.isNotEmpty).join(', '),
      a['phone'],
    ].where((v) => '${v ?? ''}'.isNotEmpty).join('\n');
    return StorePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.place_outlined,
            size: 20,
            color: StoreColors.greenSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(name, style: storeBody(weight: FontWeight.w600)),
                Text(
                  lines,
                  style: storeBody(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
