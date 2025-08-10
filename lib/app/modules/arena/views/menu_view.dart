import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/cubit/get_food_menu_cubit.dart';
import 'package:hash/core/repositories/model/food_menu_model.dart';

class MenuViewPage extends StatelessWidget {
  final String vendorId;
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;
  const MenuViewPage({
    super.key,
    required this.vendorId,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetFoodMenuCubit(),
      child: _MenuViewPage(vendorId: vendorId, onContinue: onContinue),
    );
  }
}

class _MenuViewPage extends StatefulWidget {
  final String vendorId;
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;
  const _MenuViewPage({required this.vendorId, required this.onContinue});

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
          return const Center(child: CircularProgressIndicator());
        }
        if (state is GetFoodMenuError) {
          return Center(child: Text(state.message));
        }
        if (state is GetFoodMenuLoaded) {
          return MenuView(
            foodMenuList: state.foodMenu,
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
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;

  const MenuView({
    super.key,
    required this.foodMenuList,
    required this.onContinue,
  });

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  bool isClicked = false;
  List<Map<String, dynamic>> cartItems = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Food & Beverages Offered',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          itemCount: widget.foodMenuList
              .expand((category) => category.menus ?? [])
              .length,
          itemBuilder: (context, itemIndex) {
            // Flatten all menu items from all categories
            final allMenuItems = widget.foodMenuList
                .expand((category) => category.menus ?? [])
                .toList();

            final menuItem = allMenuItems[itemIndex];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ListTile(
                leading: SizedBox(
                  width: 70,
                  height: 50,
                  child: menuItem.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            menuItem.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                ),
                title: Text(
                  menuItem.name ?? 'Unknown Item',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  menuItem.description ?? 'No description available',
                  style: GoogleFonts.inter(
                    color: Color(0xFFC9C9C9),
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Rs. ${menuItem.price?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.inter(
                        color: Color(0xFF6DFB60),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isItemInCart(menuItem.name ?? ''))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => removeFromCart({
                              'name': menuItem.name,
                              'description': menuItem.description,
                              'price': menuItem.price,
                              'imageUrl': menuItem.imageUrl,
                              'id': menuItem.id,
                              'qty': 1,
                            }),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFF6A6969),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${getItemQuantity(menuItem.name ?? '')}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => addToCart({
                              'name': menuItem.name,
                              'description': menuItem.description,
                              'price': menuItem.price,
                              'imageUrl': menuItem.imageUrl,
                              'id': menuItem.id,
                              'qty': 1,
                            }),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFF6DFB60),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => addToCart({
                          'name': menuItem.name,
                          'description': menuItem.description,
                          'price': menuItem.price,
                          'imageUrl': menuItem.imageUrl,
                          'id': menuItem.id,
                          'qty': 1,
                        }),
                        child: Text(
                          '+ Add',
                          style: GoogleFonts.inter(
                            color: Color(0xFF6A6969),
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? _buildBottomCart()
          : const SizedBox(),
    );
  }

  GestureDetector _buildBottomCart() {
    return GestureDetector(
      onTap: () => setState(() {
        isClicked = !isClicked;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: isClicked
            ? (min(cartItems.length, 3) == 3)
                  ? (3 * 95).toDouble()
                  : (min(cartItems.length, 3) == 2)
                  ? (2 * 115).toDouble()
                  : (1 * 170).toDouble()
            : (min(cartItems.length, 3) == 3)
            ? (3 * 75).toDouble()
            : (min(cartItems.length, 3) == 2)
            ? (2 * 80).toDouble()
            : (1 * 100).toDouble(),

        decoration: BoxDecoration(
          color: Color(0xFF1D1D1F),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 60),
              child: Row(
                children: [
                  Text(
                    'Selected:',
                    style: GoogleFonts.inter(
                      color: Color(0xFFA09F9F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rs. ${getTotalPrice().toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: Color(0xFF6DFB60),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Color(0xFFB3B3B3),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: min(cartItems.length, 3),
                itemBuilder: (context, index) {
                  final cartItem = cartItems[index];
                  return Row(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: cartItem['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  cartItem['imageUrl']!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${cartItem['name']}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(${cartItem['qty'] ?? 0})',
                        style: GoogleFonts.inter(
                          color: Color(0xFF6DFB60),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rs. ${((cartItem['price'] ?? 0.0) * (cartItem['qty'] ?? 1)).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: Color(0xFF6DFB60),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            isClicked == true ? _buildBottomButton() : const SizedBox(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onContinue(cartItems);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF00DC00), width: 1.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            'Continue Booking',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF75F94C),
            ),
          ),
        ),
      ),
    );
  }
}
