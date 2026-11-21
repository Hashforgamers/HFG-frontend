import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_order_page.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// `★★★★½ 4.6 (1.2K)` from a `rating_summary`; nothing when there are no reviews.
class StoreRatingLine extends StatelessWidget {
  final Object? summary;
  final double size;
  const StoreRatingLine(this.summary, {super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final s = summary is Map ? summary as Map : const {};
    final count = storeNum(s['count']).toInt();
    if (count <= 0) return const SizedBox.shrink();
    final average = storeNum(s['average']);
    return Semantics(
      label:
          'Rated ${storeNum(s['average']).toStringAsFixed(1)} out of 5 from $count reviews',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                average >= i
                    ? Icons.star_rounded
                    : average >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: size + 3,
                color: Colors.amber,
              ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${average.toStringAsFixed(1)} (${NumberFormat.compact().format(count)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: storeBody(size: size, color: StoreColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onTap;
  const _Stars(this.rating, {this.size = 14, this.onTap});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        onTap == null
            ? Icon(
                i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: Colors.amber,
              )
            : IconButton(
                tooltip: '$i star${i == 1 ? '' : 's'}',
                onPressed: () => onTap!(i),
                icon: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: Colors.amber,
                ),
              ),
    ],
  );
}

/// Published reviews and rating breakdown for the product page.
class StoreProductReviews extends StatefulWidget {
  final String productId;
  final MedusaStoreService? store;
  const StoreProductReviews({super.key, required this.productId, this.store});

  @override
  State<StoreProductReviews> createState() => _StoreProductReviewsState();
}

class _StoreProductReviewsState extends State<StoreProductReviews> {
  MedusaStoreService get _store => widget.store ?? MedusaStoreService.instance;
  final List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _summary;
  int _count = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _more() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _store.productReviews(
        widget.productId,
        offset: _reviews.length,
      );
      if (!mounted) return;
      setState(() {
        _reviews.addAll(
          (data['reviews'] as List? ?? []).map(
            (r) => Map<String, dynamic>.from(r as Map),
          ),
        );
        _count = storeNum(data['count']).toInt();
        if (data['rating_summary'] is Map) {
          _summary = Map<String, dynamic>.from(data['rating_summary']);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = storeNum(_summary?['count']).toInt();
    final breakdown = _summary?['breakdown'] is Map
        ? _summary!['breakdown'] as Map
        : const {};
    return StoreSection(
      title: 'Reviews',
      child: StorePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_summary == null && _loading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (_summary == null && _error != null)
              Text(_error!, style: storeBody(color: Colors.orangeAccent))
            else if (total == 0)
              Text('No reviews yet', style: storeBody(color: StoreColors.muted))
            else ...[
              Row(
                children: [
                  Text(
                    storeNum(_summary!['average']).toStringAsFixed(1),
                    style: storeTitle(34),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stars(storeNum(_summary!['average']).round(), size: 16),
                      Text(
                        '$total review${total == 1 ? '' : 's'}',
                        style: storeBody(size: 12, color: StoreColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (var star = 5; star >= 1; star--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        child: Text('$star', style: storeBody(size: 11)),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: storeNum(breakdown['$star']) / total,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.amber,
                          backgroundColor: StoreColors.border,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final r in _reviews) ...[
                const Divider(color: StoreColors.border, height: 28),
                Row(
                  children: [
                    _Stars(storeNum(r['rating']).toInt(), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          '${r['author'] ?? 'Verified buyer'}',
                          storeDate(r['created_at'], 'd MMM yyyy'),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: storeBody(size: 11, color: StoreColors.muted),
                      ),
                    ),
                  ],
                ),
                if ('${r['title'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${r['title']}',
                    style: storeBody(weight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${r['body'] ?? ''}',
                  style: storeBody(color: Colors.white70, height: 1.45),
                ),
              ],
              if (_reviews.length < _count)
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _more,
                    child: Text(_error != null ? 'Retry' : 'Show more'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

const _statusLabels = {
  'pending': 'Awaiting moderation; not public yet.',
  'approved': 'Published.',
  'rejected': 'Not published.',
  'withdrawn': 'Removed by you.',
};

/// Write / edit / withdraw controls for one purchased item on a completed
/// order. Eligibility and the existing review both come from the server.
class StoreReviewAction extends StatefulWidget {
  final String orderId;
  final String productId;
  final MedusaStoreService? store;
  const StoreReviewAction({
    super.key,
    required this.orderId,
    required this.productId,
    this.store,
  });

  @override
  State<StoreReviewAction> createState() => _StoreReviewActionState();
}

class _StoreReviewActionState extends State<StoreReviewAction> {
  MedusaStoreService get _store => widget.store ?? MedusaStoreService.instance;
  Map<String, dynamic>? _review;
  bool _eligible = false;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await _store.myReviews(productId: widget.productId);
      final review = mine.firstOrNull;
      // An existing review is edited instead; only check eligibility to write.
      final eligible =
          review != null ||
          (await _store.reviewEligibility(
                widget.orderId,
                widget.productId,
              ))['eligible'] ==
              true;
      if (!mounted) return;
      setState(() {
        _review = review;
        _eligible = eligible;
        _loaded = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _edit() async {
    final saved = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StoreColors.bg,
      builder: (_) => _ReviewForm(
        store: _store,
        orderId: widget.orderId,
        productId: widget.productId,
        review: _review,
      ),
    );
    if (saved != null && mounted) {
      setState(() => _review = saved);
    } else if (mounted) {
      // A 409 inside the form means our copy is stale.
      _load();
    }
  }

  Future<void> _withdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Withdraw review?'),
        content: const Text(
          'It is removed from the product page right away. You can resubmit it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final review = await _store.withdrawReview(
        _review!['id'] as String,
        storeNum(_review!['revision']).toInt(),
      );
      if (mounted) setState(() => _review = review);
    } on StoreException catch (e) {
      storeToast(
        e.statusCode == 409
            ? 'This review changed elsewhere. Showing the latest version.'
            : e.message,
        error: true,
      );
      if (e.statusCode == 409) await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    if (_error != null) {
      return TextButton(onPressed: _load, child: const Text('Retry review'));
    }
    if (!_eligible) return const SizedBox.shrink();
    final r = _review;
    final status = '${r?['status'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r != null) ...[
            Row(
              children: [
                _Stars(storeNum(r['rating']).toInt(), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusLabels[status] ?? status,
                    style: storeBody(size: 11, color: StoreColors.muted),
                  ),
                ),
              ],
            ),
            if (status == 'rejected' &&
                '${r['moderation_note'] ?? ''}'.isNotEmpty)
              Text(
                'Reason: ${r['moderation_note']}',
                style: storeBody(size: 11, color: Colors.orangeAccent),
              ),
          ],
          Row(
            children: [
              TextButton.icon(
                onPressed: _busy ? null : _edit,
                icon: Icon(
                  r == null ? Icons.rate_review_outlined : Icons.edit_outlined,
                  size: 16,
                ),
                label: Text(
                  r == null
                      ? 'Write a review'
                      : status == 'withdrawn'
                      ? 'Resubmit review'
                      : 'Edit review',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: StoreColors.greenSoft,
                ),
              ),
              if (r != null && status != 'withdrawn')
                TextButton(
                  onPressed: _busy ? null : _withdraw,
                  style: TextButton.styleFrom(
                    foregroundColor: StoreColors.muted,
                  ),
                  child: const Text('Withdraw'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  final MedusaStoreService store;
  final String orderId;
  final String productId;
  final Map<String, dynamic>? review;
  const _ReviewForm({
    required this.store,
    required this.orderId,
    required this.productId,
    this.review,
  });

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _form = GlobalKey<FormState>();
  late int _rating = storeNum(widget.review?['rating']).toInt();
  late final _title = TextEditingController(
    text: '${widget.review?['title'] ?? ''}',
  );
  late final _body = TextEditingController(
    text: '${widget.review?['body'] ?? ''}',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating < 1) {
      setState(() => _error = 'Choose a rating from 1 to 5 stars.');
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final review = await widget.store.saveReview(
        productId: widget.productId,
        orderId: widget.orderId,
        rating: _rating,
        title: _title.text,
        body: _body.text,
        revision: widget.review == null
            ? null
            : storeNum(widget.review!['revision']).toInt(),
      );
      if (mounted) Navigator.pop(context, review);
    } on StoreException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        // Never overwrite a newer version: close so the caller reloads.
        storeToast(
          'This review changed elsewhere. Reopen it to see the latest version.',
          error: true,
        );
        Navigator.pop(context);
        return;
      }
      setState(
        () => _error = e.statusCode == 401
            ? 'Your session expired. Sign in again to save your review.'
            : e.message,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.review == null ? 'Write a review' : 'Edit review',
            style: storeTitle(20),
          ),
          if (widget.review?['status'] == 'approved')
            Text(
              'Saving hides the published version until it is approved again.',
              style: storeBody(size: 12, color: StoreColors.muted),
            ),
          const SizedBox(height: 8),
          _Stars(_rating, size: 30, onTap: (v) => setState(() => _rating = v)),
          TextFormField(
            controller: _title,
            maxLength: 120,
            style: storeBody(size: 15),
            decoration: const InputDecoration(labelText: 'Title (optional)'),
          ),
          TextFormField(
            controller: _body,
            maxLength: 3000,
            minLines: 3,
            maxLines: 6,
            style: storeBody(size: 15),
            decoration: const InputDecoration(labelText: 'Your review'),
            validator: (v) => (v?.trim().length ?? 0) < 10
                ? 'Write at least 10 characters'
                : null,
          ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: storeBody(size: 12, color: StoreColors.danger),
              ),
            ),
          const SizedBox(height: 12),
          StoreButton(
            label: 'Submit for review',
            loading: _saving,
            onTap: _saving ? null : _save,
          ),
        ],
      ),
    ),
  );
}
