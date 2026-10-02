import 'package:flutter/material.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_play_api.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_checkout_sheet.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:intl/intl.dart';

/// Read-only balance and ledger for the gamer's wallet at one cafe.
/// Money is only added at the cafe desk, so there is no top-up action.
class CafeWalletView extends StatefulWidget {
  const CafeWalletView({super.key, required this.vendorId, this.cafeName});

  final int vendorId;

  /// Shown until the wallet response provides the name.
  final String? cafeName;

  @override
  State<CafeWalletView> createState() => _CafeWalletViewState();
}

class _CafeWalletViewState extends State<CafeWalletView>
    with WidgetsBindingObserver {
  static const _pageSize = 20;

  final _api = CafePlayApi.instance;
  final _scroll = ScrollController();

  CafeWallet? _wallet;
  final List<CafeWalletEntry> _entries = [];
  int? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  bool _notFound = false;

  // Drops responses from a load that a newer refresh superseded.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) _loadMore();
  }

  /// Balance and the first history page together; the history is not an
  /// atomic snapshot with the balance, so both are always refreshed as a pair.
  Future<void> _refresh() async {
    final gen = ++_generation;
    if (_wallet == null) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getWallet(widget.vendorId),
        _api.getWalletHistory(widget.vendorId, limit: _pageSize),
      ]);
      if (!mounted || gen != _generation) return;
      final history = results[1] as CafePage<CafeWalletEntry>;
      setState(() {
        _wallet = results[0] as CafeWallet;
        _entries
          ..clear()
          ..addAll(history.items);
        _nextCursor = history.nextCursor;
        _error = null;
        _moreError = null;
        _notFound = false;
        _loading = false;
        _loadingMore = false;
      });
    } on CafePlayException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _notFound = e.statusCode == 404;
        _error = e.statusCode == 404
            ? 'This cafe is no longer available.'
            : e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore || _loading) return;
    final gen = _generation;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await _api.getWalletHistory(
        widget.vendorId,
        limit: _pageSize,
        before: cursor,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _entries.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on CafePlayException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _moreError = e.message;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _wallet?.cafeName ?? widget.cafeName ?? 'Cafe wallet';
    return Scaffold(
      backgroundColor: HomeTokens.ink,
      appBar: AppBar(
        backgroundColor: HomeTokens.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(name, style: HomeTokens.title(17)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading && _wallet == null) {
      return const Center(
        child: CircularProgressIndicator(color: HomeTokens.gold),
      );
    }
    final wallet = _wallet;
    if (wallet == null) {
      return _ErrorState(
        message: _error ?? 'Could not load this cafe wallet.',
        onRetry: _notFound ? null : _refresh,
      );
    }
    return RefreshIndicator(
      color: HomeTokens.gold,
      backgroundColor: HomeTokens.surface,
      onRefresh: _refresh,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          CafeWalletBalanceCard(wallet: wallet),
          const SizedBox(height: 24),
          const HomeEyebrow('History'),
          const SizedBox(height: 10),
          if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No wallet activity at this cafe yet.',
                textAlign: TextAlign.center,
                style: HomeTokens.body(HomeTokens.textTertiary),
              ),
            )
          else
            ..._entries.map((e) => _EntryTile(entry: e)),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HomeTokens.gold,
                  ),
                ),
              ),
            )
          else if (_moreError != null)
            TextButton(
              onPressed: _loadMore,
              child: Text(
                '$_moreError Tap to retry.',
                textAlign: TextAlign.center,
                style: HomeTokens.body(HomeTokens.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Available funds, any pending reservation, and the desk top-up note.
class CafeWalletBalanceCard extends StatelessWidget {
  const CafeWalletBalanceCard({super.key, required this.wallet});

  final CafeWallet wallet;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      accent: HomeTokens.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeEyebrow('Available balance', color: HomeTokens.gold),
          const SizedBox(height: 6),
          Text(
            cafeMoney(wallet.availableBalance),
            style: HomeTokens.title(30).copyWith(color: HomeTokens.goldLight),
          ),
          if (wallet.reserved != 0) ...[
            const SizedBox(height: 6),
            Text(
              'Pending reservation ${cafeMoney(wallet.reserved)}',
              style: HomeTokens.body(HomeTokens.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 16,
                color: HomeTokens.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Top up at this cafe\'s reception. Only usable at this cafe.',
                  style: HomeTokens.body(HomeTokens.textTertiary, size: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final CafeWalletEntry entry;

  static final _dateFormat = DateFormat('d MMM yyyy, h:mm a');

  @override
  Widget build(BuildContext context) {
    final hold = entry.isHold;
    final credit = entry.amount > 0;
    final color = hold
        ? HomeTokens.textSecondary
        : credit
        ? HomeTokens.green
        : Colors.redAccent;
    final icon = hold
        ? Icons.lock_clock_rounded
        : credit
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;

    final subtitle = [
      if (entry.createdAt != null) _dateFormat.format(entry.createdAt!),
      if (entry.methodLabel != null) entry.methodLabel!,
    ].join(' · ');

    final String amountText;
    if (hold) {
      amountText = entry.kind == CafeWalletEntryKind.reserve
          ? 'Held ${cafeMoney(entry.reservedAfter)}'
          : 'Released';
    } else {
      final sign = entry.amount > 0 ? '+' : (entry.amount < 0 ? '−' : '');
      amountText = '$sign${cafeMoney(entry.amount.abs())}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeTokens.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label, style: HomeTokens.title(14)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: HomeTokens.body(HomeTokens.textTertiary, size: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: HomeTokens.title(hold ? 13 : 15).copyWith(color: color),
              ),
              const SizedBox(height: 3),
              Text(
                'Bal ${cafeMoney(entry.balanceAfter)}',
                style: HomeTokens.body(HomeTokens.textTertiary, size: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: HomeTokens.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HomeTokens.body(HomeTokens.textSecondary, size: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: HomeTokens.title(14).copyWith(color: HomeTokens.gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
