import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
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

/// The only payment provider the app can complete today. Others need their
/// SDK wired to `payment_sessions[].data` first.
const _manualProvider = 'pp_system_default';

class HashStoreCheckoutPage extends StatefulWidget {
  const HashStoreCheckoutPage({super.key});

  @override
  State<HashStoreCheckoutPage> createState() => _HashStoreCheckoutPageState();
}

class _HashStoreCheckoutPageState extends State<HashStoreCheckoutPage> {
  final _store = MedusaStoreService.instance;
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
  bool _placing = false;

  bool get _ready => _options != null;

  @override
  void initState() {
    super.initState();
    _cart = context.read<HashStoreCartCubit>().state.cart!;
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
    setState(() => _saving = true);
    try {
      final id = _cart['id'] as String;
      final cart = await _store.updateCart(
        id,
        email: _f['email']!.text.trim(),
        address: _address,
      );
      final results = await Future.wait([
        _store.shippingOptions(id),
        _store.paymentProviders(),
      ]);
      if (!mounted) return;
      context.read<HashStoreCartCubit>().replace(cart);
      setState(() {
        _cart = cart;
        _options = results[0];
        _providers = results[1];
        _optionId = _options!.isEmpty ? null : _options!.first['id'] as String;
        _providerId = _providers.any((p) => p['id'] == _manualProvider)
            ? _manualProvider
            : null;
      });
    } catch (e) {
      storeToast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectOption(String id) async {
    setState(() => _optionId = id);
    // Refresh totals so the bar shows the delivery price straight away.
    try {
      final cart = await _store.selectShipping(_cart['id'] as String, id);
      if (!mounted) return;
      context.read<HashStoreCartCubit>().replace(cart);
      setState(() => _cart = cart);
    } catch (_) {
      // Re-applied when the order is placed.
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    final cubit = context.read<HashStoreCartCubit>();
    try {
      final id = _cart['id'] as String;
      final cart = await _store.selectShipping(id, _optionId!);
      cubit.replace(cart);
      setState(() => _cart = cart);
      await _store.startPayment(cart, _providerId!);
      final order = await _store.completeCart(id);
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
      storeToast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cart['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    return Scaffold(
      backgroundColor: StoreColors.bg,
      bottomNavigationBar: StoreBottomBar(
        child: _ready
            ? Row(
                children: [
                  StoreTotalLabel(amount: _cart['total']),
                  const SizedBox(width: 20),
                  Expanded(
                    child: StoreButton(
                      label: 'Place order',
                      icon: Icons.lock_rounded,
                      loading: _placing,
                      onTap: _optionId == null || _providerId == null || _saving
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
      ),
      body: Form(
        key: _form,
        // Inline validation: a field reports its problem once touched.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: CustomScrollView(
          slivers: [
            const StoreHeader(
              title: 'Checkout',
              eyebrow: 'SECURE CHECKOUT',
              showBack: true,
              showCart: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList.list(
                children: [
                  _Progress(step: _ready ? 2 : 1),
                  const SizedBox(height: 20),
                  _ItemStrip(items: items),
                  const SizedBox(height: 28),
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
                            Expanded(child: _field('first_name', 'First name')),
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
                                    v.replaceAll(RegExp(r'\D'), '').length >= 10
                                    ? null
                                    : 'Valid phone',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_ready) ...[
                    const SizedBox(height: 16),
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
                                    title: '${o['name'] ?? 'Delivery'}',
                                    trailing: () {
                                      final amount =
                                          o['amount'] ??
                                          (o['calculated_price']
                                              as Map?)?['calculated_amount'];
                                      return storeNum(amount) == 0
                                          ? 'Free'
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
                                    title: p['id'] == _manualProvider
                                        ? 'Manual payment (test)'
                                        : '${p['id']}',
                                    subtitle: p['id'] == _manualProvider
                                        ? 'Demo provider. No money is taken.'
                                        : 'Not available in the app yet',
                                    selected: _providerId == p['id'],
                                    onTap: p['id'] == _manualProvider
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
        textInputAction: TextInputAction.next,
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
