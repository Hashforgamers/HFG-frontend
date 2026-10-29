import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/data/store_razorpay.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_order_page.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

void openStoreCheckout(BuildContext context) {
  final cart = context.read<HashStoreCartCubit>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          BlocProvider.value(value: cart, child: const HashStoreCheckoutPage()),
    ),
  );
}

/// Demo provider for tests; Razorpay is the real one. Others need their SDK
/// wired to `payment_sessions[].data` first.
const _manualProvider = 'pp_system_default';

bool _supported(String? id) => id == _manualProvider || isRazorpayProvider(id);

class HashStoreCheckoutPage extends StatefulWidget {
  final MedusaStoreService? store;
  final Future<void> Function(Map<String, dynamic>)? pay;
  const HashStoreCheckoutPage({super.key, this.store, this.pay});

  @override
  State<HashStoreCheckoutPage> createState() => _HashStoreCheckoutPageState();
}

class _HashStoreCheckoutPageState extends State<HashStoreCheckoutPage> {
  MedusaStoreService get _store => widget.store ?? MedusaStoreService.instance;
  final _form = GlobalKey<FormState>();
  final _f = {
    for (final k in const [
      'email',
      'first_name',
      'last_name',
      'address_1',
      'address_2',
      'city',
      'province',
      'postal_code',
      'phone',
    ])
      k: TextEditingController(),
  };

  late Map<String, dynamic> _cart;
  List<Map<String, dynamic>> _saved = [];
  List<Map<String, dynamic>>? _options;
  List<Map<String, dynamic>> _providers = [];
  String? _optionId;
  String? _providerId;
  bool _saving = false;
  bool _paid = false;
  bool _shippingSelected = false;
  bool _sellerPaid = false;
  bool _placing = false;
  String? _checkoutError;

  bool get _ready => _options != null;

  @override
  void initState() {
    super.initState();
    _cart = context.read<HashStoreCartCubit>().state.cart!;
    _paid = _store.paymentAwaitingCompletion(_cart['id'] as String);
    if (_paid) _options = [];
    final address = _cart['shipping_address'];
    if (address is Map) _fill(Map<String, dynamic>.from(address));
    _f['email']!.text = '${_cart['email'] ?? _store.profileEmail ?? ''}';
    _store
        .savedAddresses()
        .then((a) {
          if (!mounted) return;
          setState(() => _saved = a);
          if (address is! Map && a.isNotEmpty) _fill(a.first);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in _f.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Map<String, dynamic> a) {
    for (final k in _f.keys) {
      if (k != 'email' && a[k] != null) _f[k]!.text = '${a[k]}';
    }
  }

  Map<String, dynamic> get _address => {
    for (final e in _f.entries)
      if (e.key != 'email' && e.value.text.trim().isNotEmpty)
        e.key: e.value.text.trim(),
    'country_code': 'in',
  };

  Future<void> _saveAddress() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _checkoutError = null;
    });
    try {
      final id = _cart['id'] as String;
      final cart = await _store.updateCart(
        id,
        email: _f['email']!.text.trim(),
        address: _address,
      );
      final delivery = await _store.deliveryOptions(id);
      final providers = await _store.paymentProviders();
      if (!mounted) return;
      context.read<HashStoreCartCubit>().replace(cart);
      setState(() {
        _cart = cart;
        _options = delivery.options;
        _sellerPaid = delivery.sellerPaid;
        _shippingSelected = false;
        _providers = providers;
        _optionId = null;
        final ids = _providers.map((p) => p['id'] as String?);
        _providerId =
            ids.where(isRazorpayProvider).firstOrNull ??
            ids.where(_supported).firstOrNull;
      });
    } catch (e) {
      if (mounted) setState(() => _checkoutError = e.toString());
      storeToast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectOption(String id) async {
    if (_saving || _placing || _paid) return;
    setState(() {
      _saving = true;
      _shippingSelected = false;
      _checkoutError = null;
    });
    try {
      final cart = await _store.selectShipping(_cart['id'] as String, id);
      if (!mounted) return;
      context.read<HashStoreCartCubit>().replace(cart);
      setState(() {
        _cart = cart;
        _optionId = id;
        _shippingSelected = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _optionId = null;
          _checkoutError = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_placing || _saving) return;
    if (kDebugMode) debugPrint('[HashStoreCheckout] Place order tapped');
    FocusScope.of(context).unfocus();
    setState(() {
      _placing = true;
      _checkoutError = null;
    });
    var paymentSetup = !_paid;
    final cubit = context.read<HashStoreCartCubit>();
    try {
      final id = _cart['id'] as String;
      if (!_paid) {
        final previousTotal = _cart['total'];
        final cart = await _store.selectShipping(id, _optionId!);
        cubit.replace(cart);
        if (!mounted) return;
        setState(() => _cart = cart);
        if (cart['total'] != previousTotal) {
          _checkoutError =
              'Your delivery total changed. Review the updated total and tap Place order to accept.';
          return;
        }
        if (isRazorpayProvider(_providerId) && storeNum(cart['total']) <= 0) {
          throw const StoreException(
            'This order total is ₹0, which online payment cannot process. Remove the offer or contact Hash support.',
          );
        }
        final collection = await _store.startPayment(cart, _providerId!);
        if (kDebugMode) debugPrint('[HashStoreCheckout] Payment session ready');
        paymentSetup = false;
        if (isRazorpayProvider(_providerId)) {
          final options = razorpayOptions(
            collection,
            _providerId!,
            email: _f['email']!.text.trim(),
            phone: _f['phone']!.text.trim(),
          );
          if (options == null) {
            throw const StoreException(
              'Razorpay is not set up for the store yet. Please try later.',
            );
          }
          final amount = options['amount'];
          final total = cart['total'];
          if (amount is! num ||
              total is! num ||
              amount != (total * 100).round() ||
              options['currency'] !=
                  '${cart['currency_code'] ?? 'inr'}'.toUpperCase()) {
            throw const StoreException(
              'Payment total does not match your order. Refresh delivery and try again.',
            );
          }
          await (widget.pay ?? payWithRazorpay)(options);
          if (kDebugMode) {
            debugPrint('[HashStoreCheckout] Razorpay success callback');
          }
        }
        _paid = true;
        await _store.rememberPaidCart(id);
      }
      final order = await _store.completeCart(id);
      if (kDebugMode) {
        debugPrint(
          '[HashStoreCheckout] Backend confirmed order ${order['id']}',
        );
      }
      cubit.replace(null);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HashStoreOrderPage(
            orderId: order['id'] as String,
            justPlaced: true,
          ),
        ),
      );
    } catch (e) {
      // The cart is kept so the shopper can retry.
      if (mounted) {
        setState(() {
          _checkoutError =
              paymentSetup && e is StoreException && (e.statusCode ?? 0) >= 500
              ? 'Could not start payment. Please try again later. Your cart is saved.'
              : e.toString();
        });
      }
      if (kDebugMode) {
        debugPrint(
          '[HashStoreCheckout] Failed: ${e.runtimeType}${e is StoreException ? ' status=${e.statusCode}' : ''}',
        );
      }
      storeToast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final items = (_cart['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    return Scaffold(
      backgroundColor: StoreColors.bg,
      bottomSheet: keyboardVisible
          ? Material(
              color: StoreColors.bg,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => FocusScope.of(context).unfocus(),
                      icon: const Icon(Icons.keyboard_hide_rounded),
                      label: const Text('Done'),
                      style: TextButton.styleFrom(
                        foregroundColor: StoreColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            )
          : null,
      bottomNavigationBar: StoreBottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_checkoutError != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _checkoutError!,
                  style: storeBody(color: StoreColors.danger),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _ready
                ? Row(
                    children: [
                      StoreTotalLabel(amount: _cart['total']),
                      const SizedBox(width: 20),
                      Expanded(
                        child: StoreButton(
                          label: _paid ? 'Confirm paid order' : 'Place order',
                          icon: Icons.lock_rounded,
                          loading: _placing,
                          onTap:
                              _saving ||
                                  (!_paid &&
                                      (!_shippingSelected ||
                                          _optionId == null ||
                                          _providerId == null))
                              ? null
                              : _placeOrder,
                        ),
                      ),
                    ],
                  )
                : StoreButton(
                    label: 'Continue to delivery',
                    icon: Icons.arrow_forward_rounded,
                    loading: _saving,
                    onTap: _saveAddress,
                  ),
          ],
        ),
      ),
      body: Form(
        key: _form,
        // Inline validation: a field reports its problem once touched.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const StoreHeader(
              title: 'Checkout',
              eyebrow: 'SECURE CHECKOUT',
              showBack: true,
              showCart: false,
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                keyboardVisible ? 80 : 32,
              ),
              sliver: SliverList.list(
                children: [
                  _Progress(step: _ready ? 2 : 1),
                  const SizedBox(height: 20),
                  _ItemStrip(items: items),
                  const SizedBox(height: 28),
                  if (!_ready) ...[
                    StoreSection(
                      title: 'Contact',
                      child: _field(
                        'email',
                        'Email for order updates',
                        icon: Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) => v.contains('@') && v.contains('.')
                            ? null
                            : 'Enter a valid email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    StoreSection(
                      title: 'Delivery address',
                      child: Column(
                        children: [
                          if (_saved.isNotEmpty) ...[
                            SizedBox(
                              height: 64,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _saved.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) => _SavedAddress(
                                  address: _saved[i],
                                  onTap: () => setState(() {
                                    _fill(_saved[i]);
                                    _options = null;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: _field('first_name', 'First name'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _field('last_name', 'Last name')),
                            ],
                          ),
                          _field(
                            'address_1',
                            'House, street',
                            icon: Icons.home_outlined,
                          ),
                          _field(
                            'address_2',
                            'Landmark (optional)',
                            required: false,
                          ),
                          Row(
                            children: [
                              Expanded(child: _field('city', 'City')),
                              const SizedBox(width: 10),
                              Expanded(child: _field('province', 'State')),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  'postal_code',
                                  'PIN code',
                                  keyboard: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  validator: (v) =>
                                      v.length == 6 ? null : '6-digit PIN',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _field(
                                  'phone',
                                  'Phone',
                                  keyboard: TextInputType.phone,
                                  validator: (v) =>
                                      v.replaceAll(RegExp(r'\D'), '').length >=
                                          10
                                      ? null
                                      : 'Valid phone',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    StoreSection(
                      title: 'Delivering to',
                      trailing: TextButton.icon(
                        onPressed: (_placing || _paid)
                            ? null
                            : () => setState(() {
                                _options = null;
                                _checkoutError = null;
                              }),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: StoreColors.purpleSoft,
                        ),
                      ),
                      child: StorePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_f['first_name']!.text} ${_f['last_name']!.text}',
                              style: storeTitle(15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [
                                _f['address_1']!.text,
                                _f['address_2']!.text,
                                '${_f['city']!.text}, ${_f['province']!.text} ${_f['postal_code']!.text}',
                              ].where((line) => line.trim().isNotEmpty).join('\n'),
                              style: storeBody(
                                color: StoreColors.muted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_f['phone']!.text} · ${_f['email']!.text}',
                              style: storeBody(
                                size: 12,
                                color: StoreColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_ready && !_paid) ...[
                    const SizedBox(height: 24),
                    StoreSection(
                      title: 'Delivery method',
                      child: _options!.isEmpty
                          ? const _Notice(
                              'No delivery options for this address yet.',
                            )
                          : Column(
                              children: [
                                for (final o in _options!)
                                  _Choice(
                                    icon: Icons.local_shipping_outlined,
                                    title: _sellerPaid
                                        ? 'Delivery paid by seller'
                                        : '${o['name'] ?? 'Delivery'}',
                                    trailing: () {
                                      final amount =
                                          o['amount'] ??
                                          (o['calculated_price']
                                              as Map?)?['calculated_amount'];
                                      return _sellerPaid ||
                                              storeNum(amount) == 0
                                          ? '₹0'
                                          : storeMoney(amount);
                                    }(),
                                    selected: _optionId == o['id'],
                                    onTap: () =>
                                        _selectOption(o['id'] as String),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    StoreSection(
                      title: 'Payment',
                      child: _providers.isEmpty
                          ? const _Notice(
                              'No payment method is set up for this region.',
                            )
                          : Column(
                              children: [
                                for (final p in _providers)
                                  _Choice(
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: isRazorpayProvider(p['id'])
                                        ? 'Razorpay'
                                        : p['id'] == _manualProvider
                                        ? 'Manual payment (test)'
                                        : '${p['id']}',
                                    subtitle: isRazorpayProvider(p['id'])
                                        ? 'UPI, cards, netbanking and wallets'
                                        : p['id'] == _manualProvider
                                        ? 'Demo provider. No money is taken.'
                                        : 'Not available in the app yet',
                                    selected: _providerId == p['id'],
                                    onTap:
                                        !_placing &&
                                            !_saving &&
                                            _supported(p['id'])
                                        ? () => setState(
                                            () =>
                                                _providerId = p['id'] as String,
                                          )
                                        : null,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    StoreSection(
                      title: 'Offers',
                      child: _Coupons(
                        store: _store,
                        cart: _cart,
                        enabled: !_placing && !_saving,
                        onCart: (cart) {
                          context.read<HashStoreCartCubit>().replace(cart);
                          setState(() => _cart = cart);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    StoreSection(
                      title: 'Summary',
                      child: StoreTotals(cart: _cart),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    bool required = true,
    IconData? icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String)? validator,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _f[key],
        keyboardType: keyboard,
        inputFormatters: formatters,
        textInputAction: key == 'phone'
            ? TextInputAction.done
            : TextInputAction.next,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        onFieldSubmitted: (_) {
          if (key == 'phone') FocusScope.of(context).unfocus();
        },
        style: storeBody(size: 15),
        cursorColor: StoreColors.green,
        // Editing after the address step invalidates the shown options.
        onChanged: (_) {
          if (_ready) setState(() => _options = null);
        },
        validator: (v) {
          final text = v?.trim() ?? '';
          if (text.isEmpty) return required ? 'Required' : null;
          return validator?.call(text);
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: storeBody(color: StoreColors.muted),
          floatingLabelStyle: storeBody(color: StoreColors.greenSoft),
          prefixIcon: icon == null
              ? null
              : Icon(icon, size: 20, color: StoreColors.faint),
          filled: true,
          fillColor: StoreColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: border(StoreColors.border),
          focusedBorder: border(StoreColors.green),
          errorBorder: border(StoreColors.danger),
          focusedErrorBorder: border(StoreColors.danger),
          errorStyle: storeBody(size: 11, color: StoreColors.danger),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int step;
  const _Progress({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Delivery & payment', 'Done'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < step ? StoreColors.green : StoreColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: storeBody(
                    size: 11,
                    color: i < step ? Colors.white : StoreColors.faint,
                    weight: i == step - 1 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ItemStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ItemStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final count = items.fold<int>(
      0,
      (s, i) => s + storeNum(i['quantity']).toInt(),
    );
    final first = items.isEmpty
        ? ''
        : '${items.first['product_title'] ?? items.first['title'] ?? ''}';
    return StorePanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 56 + (items.length.clamp(1, 3) - 1) * 22,
            height: 56,
            child: Stack(
              children: [
                for (var i = 0; i < items.length && i < 3; i++)
                  Positioned(
                    left: i * 22,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: StoreColors.surface,
                          width: 2,
                        ),
                      ),
                      child: StoreImage(
                        url: items[i]['thumbnail'] as String?,
                        width: 52,
                        height: 52,
                        radius: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first +
                      (items.length > 1 ? ' + ${items.length - 1} more' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: storeBody(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count item${count == 1 ? '' : 's'}',
                  style: storeBody(size: 12, color: StoreColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddress extends StatelessWidget {
  final Map<String, dynamic> address;
  final VoidCallback onTap;
  const _SavedAddress({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StoreColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_outlined,
            size: 18,
            color: StoreColors.greenSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${address['address_1'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: storeBody(size: 12, weight: FontWeight.w600),
                ),
                Text(
                  '${address['city'] ?? ''} ${address['postal_code'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: storeBody(size: 11, color: StoreColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Coupon entry plus the offers on the server cart. Totals always come from
/// the returned cart; nothing is computed here.
class _Coupons extends StatefulWidget {
  final MedusaStoreService store;
  final Map<String, dynamic> cart;
  final bool enabled;
  final ValueChanged<Map<String, dynamic>> onCart;
  const _Coupons({
    required this.store,
    required this.cart,
    required this.enabled,
    required this.onCart,
  });

  @override
  State<_Coupons> createState() => _CouponsState();
}

class _CouponsState extends State<_Coupons> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() call) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      widget.onCart(await call());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _apply() {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) return;
    _run(() async {
      final result = await widget.store.applyCoupon(
        widget.cart['id'] as String,
        code,
      );
      if (result.applied) {
        _code.clear();
      } else {
        _error = 'This code does not apply to this cart';
      }
      return result.cart;
    });
  }

  @override
  Widget build(BuildContext context) {
    final promotions = (widget.cart['promotions'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final enabled = widget.enabled && !_busy;
    return StorePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  enabled: enabled,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _apply(),
                  style: storeBody(size: 15),
                  cursorColor: StoreColors.green,
                  decoration: InputDecoration(
                    hintText: 'Coupon code',
                    hintStyle: storeBody(color: StoreColors.faint),
                    prefixIcon: const Icon(
                      Icons.local_offer_outlined,
                      size: 20,
                      color: StoreColors.faint,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                onPressed: enabled ? _apply : null,
                style: TextButton.styleFrom(
                  foregroundColor: StoreColors.greenSoft,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: storeBody(size: 12, color: StoreColors.danger),
              ),
            ),
          for (final p in promotions)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: StoreColors.greenSoft,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p['is_automatic'] == true
                        ? 'Offer applied automatically'
                        : '${p['code'] ?? ''} applied',
                    style: storeBody(size: 13, weight: FontWeight.w600),
                  ),
                ),
                if (p['is_automatic'] != true && p['code'] != null)
                  TextButton(
                    onPressed: enabled
                        ? () => _run(
                            () => widget.store.removeCoupon(
                              widget.cart['id'] as String,
                              '${p['code']}',
                            ),
                          )
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: StoreColors.muted,
                    ),
                    child: const Text('Remove'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);

  @override
  Widget build(BuildContext context) => StorePanel(
    borderColor: Colors.orangeAccent.withValues(alpha: 0.4),
    child: Text(text, style: storeBody(color: Colors.orangeAccent)),
  );
}

class _Choice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback? onTap;
  const _Choice({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      selected: selected,
      button: onTap != null,
      child: Opacity(
        opacity: onTap == null && !selected ? 0.45 : 1,
        child: BounceTap(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? StoreColors.green.withValues(alpha: 0.08)
                  : StoreColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? StoreColors.green : StoreColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? StoreColors.greenSoft : StoreColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: storeBody(size: 14, weight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: storeBody(size: 11, color: StoreColors.muted),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  Text(trailing!, style: storeBody(weight: FontWeight.w700)),
                  const SizedBox(width: 10),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? StoreColors.green : Colors.transparent,
                    border: Border.all(
                      color: selected ? StoreColors.green : StoreColors.faint,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
