import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/cubit/get_food_menu_cubit.dart';
import 'package:hash/core/repositories/model/food_menu_model.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class MenuViewPage extends StatelessWidget {
  final String vendorId;
  final String email;
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;
  const MenuViewPage({
    super.key,
    required this.vendorId,
    required this.email,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetFoodMenuCubit(),
      child: _MenuViewPage(
        vendorId: vendorId,
        email: email,
        onContinue: onContinue,
      ),
    );
  }
}

class _MenuViewPage extends StatefulWidget {
  final String vendorId;
  final String email;
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;
  const _MenuViewPage({
    required this.vendorId,
    required this.email,
    required this.onContinue,
  });

  @override
  State<_MenuViewPage> createState() => __MenuViewPageState();
}

class __MenuViewPageState extends State<_MenuViewPage> {
  @override
  void initState() {
    super.initState();
    context.read<GetFoodMenuCubit>().getFoodMenu(widget.vendorId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetFoodMenuCubit, GetFoodMenuState>(
      builder: (context, state) {
        if (state is GetFoodMenuLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RainbowGlowingLoader(size: 40),
                  const SizedBox(height: 20),
                  Text(
                    'Loading Menu...',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is GetFoodMenuError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 60),
                  const SizedBox(height: 20),
                  Text(
                    'Error loading menu',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.message,
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        if (state is GetFoodMenuLoaded) {
          return MenuView(
            foodMenuList: state.foodMenu,
            email: widget.email,
            onContinue: widget.onContinue,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class MenuView extends StatefulWidget {
  final List<FoodMenuModel> foodMenuList;
  final String email;
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;

  const MenuView({
    super.key,
    required this.foodMenuList,
    required this.email,
    required this.onContinue,
  });

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> with TickerProviderStateMixin {
  bool isCartExpanded = false;
  List<Map<String, dynamic>> cartItems = [];
  late AnimationController _cartAnimationController;
  late AnimationController _itemAnimationController;
  late Animation<double> _cartHeightAnimation;
  late Animation<double> _cartOpacityAnimation;
  final segmentService = locator<SegmentSdkService>();

  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _itemAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _cartHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cartAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _cartOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cartAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    _itemAnimationController.dispose();
    super.dispose();
  }

  void addToCart(Map<String, dynamic> item) {
    int index = cartItems.indexWhere(
      (cartItem) => cartItem['name'] == item['name'],
    );

    setState(() {
      if (index != -1) {
        cartItems[index]['qty'] = (cartItems[index]['qty'] ?? 1) + 1;
      } else {
        cartItems.add(item);
      }
    });

    if (cartItems.length == 1) {
      _cartAnimationController.forward();
    }
    _itemAnimationController.forward().then((_) {
      _itemAnimationController.reset();
    });
  }

  void removeFromCart(Map<String, dynamic> item) {
    int index = cartItems.indexWhere(
      (cartItem) => cartItem['name'] == item['name'],
    );

    setState(() {
      if (index != -1) {
        if (cartItems[index]['qty'] > 1) {
          cartItems[index]['qty'] = cartItems[index]['qty'] - 1;
        } else {
          cartItems.removeAt(index);
        }
      }
    });

    if (cartItems.isEmpty) {
      _cartAnimationController.reverse();
    }
  }

  bool isItemInCart(String itemName) {
    return cartItems.any((cartItem) => cartItem['name'] == itemName);
  }

  int getItemQuantity(String itemName) {
    int index = cartItems.indexWhere(
      (cartItem) => cartItem['name'] == itemName,
    );
    return index != -1 ? (cartItems[index]['qty'] ?? 0) : 0;
  }

  double getTotalPrice() {
    double total = 0.0;
    for (var item in cartItems) {
      double price = (item['price'] ?? 0.0).toDouble();
      int qty = (item['qty'] ?? 1).toInt();
      total += price * qty;
    }
    return total;
  }

  void toggleCartExpansion() {
    setState(() {
      isCartExpanded = !isCartExpanded;
    });
  }

  List<Map<String, dynamic>> _getAllMenuItems() {
    List<Map<String, dynamic>> allItems = [];
    for (var category in widget.foodMenuList) {
      if (category.menus != null) {
        for (var menuItem in category.menus!) {
          allItems.add({'menuItem': menuItem, 'categoryId': category.id});
        }
      }
    }
    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Food & Beverages',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 180,
              ), // Increased space for cart + button
              itemCount: _getAllMenuItems().length,
              itemBuilder: (context, index) {
                final itemData = _getAllMenuItems()[index];
                final menuItem = itemData['menuItem'];
                final categoryId = itemData['categoryId'];
                return _buildMenuItem(menuItem, categoryId);
              },
            ),
          ),
          // Bottom cart
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _cartAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _cartHeightAnimation.value)),
                  child: Opacity(
                    opacity: _cartOpacityAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBottomCart(),
                        if (cartItems.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildContinueButton(widget.email),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(dynamic menuItem, dynamic categoryId) {
    final isInCart = isItemInCart(menuItem.name ?? '');
    final quantity = getItemQuantity(menuItem.name ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInCart
              ? const Color(0xFF338125).withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isInCart
                ? const Color(0xFF338125).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: menuItem.imageUrl ?? menuItem.image_url ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Center(child: RainbowGlowingLoader(size: 20)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Icon(
                      Icons.fastfood,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem.name ?? 'Unknown Item',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menuItem.description ?? 'No description available',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF338125).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rs. ${menuItem.price?.toStringAsFixed(0) ?? '0'}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF338125),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Quantity controls
            if (isInCart)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF338125).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF338125).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: () => removeFromCart({
                        'name': menuItem.name,
                        'description': menuItem.description,
                        'price': menuItem.price,
                        'imageUrl': menuItem.imageUrl ?? menuItem.image_url,
                        'id': menuItem.id,
                        'category_id': categoryId is int
                            ? categoryId
                            : int.tryParse(categoryId.toString()) ?? 0,
                        'qty': 1,
                      }),
                    ),
                    Container(
                      width: 40,
                      height: 32,
                      alignment: Alignment.center,
                      child: Text(
                        '$quantity',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () => addToCart({
                        'name': menuItem.name,
                        'description': menuItem.description,
                        'price': menuItem.price,
                        'imageUrl': menuItem.imageUrl ?? menuItem.image_url,
                        'id': menuItem.id,
                        'category_id': categoryId is int
                            ? categoryId
                            : int.tryParse(categoryId.toString()) ?? 0,
                        'qty': 1,
                      }),
                    ),
                  ],
                ),
              )
            else
              _buildAddButton(menuItem, categoryId),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF338125),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildAddButton(dynamic menuItem, dynamic categoryId) {
    return GestureDetector(
      onTap: () => addToCart({
        'name': menuItem.name,
        'description': menuItem.description,
        'price': menuItem.price,
        'imageUrl': menuItem.imageUrl ?? menuItem.image_url,
        'id': menuItem.id,
        'category_id': categoryId is int
            ? categoryId
            : int.tryParse(categoryId.toString()) ?? 0,
        'qty': 1,
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF338125), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF338125).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCart() {
    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF338125).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart header
          GestureDetector(
            onTap: toggleCartExpansion,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF338125).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Color(0xFF338125),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Items',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${cartItems.length} item${cartItems.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${getTotalPrice().toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF338125),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns: isCartExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Color(0xFF338125),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Cart items (expandable)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF333333), height: 1),
                  const SizedBox(height: 16),
                  ...cartItems.map((item) => _buildCartItem(item)).toList(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            crossFadeState: isCartExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Item image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item['imageUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['imageUrl']!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF3A3A3A),
                        child: const Center(
                          child: RainbowGlowingLoader(size: 16),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF3A3A3A),
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF3A3A3A),
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${item['price']?.toStringAsFixed(0) ?? '0'} each',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Quantity and total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Qty: ${item['qty'] ?? 0}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF338125),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs. ${((item['price'] ?? 0.0) * (item['qty'] ?? 1)).toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF338125),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(String email) {
    return GestureDetector(
      onTap: () {
        segmentService.onMealSelected(email: email, selectedMeal: cartItems);
        Navigator.pop(context);
        widget.onContinue(cartItems);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF338125), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF338125).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue Booking',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
