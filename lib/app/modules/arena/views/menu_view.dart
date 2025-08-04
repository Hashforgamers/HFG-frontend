import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuView extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> cartItems) onContinue;

  const MenuView({super.key, required this.onContinue});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  bool isClicked = false;

  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Crispy Fries',
      'image': 'assets/images/menu1.png',
      'desc':
          'Cooked in pure olive oil, garnished with a himalayan salt and served with garlic sauce',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Veggie Burger',
      'image': 'assets/images/menu2.png',
      'desc':
          'Plant-based burger with a hearty veggie patty, fresh lettuce, tomato, pickles, and creamy sauce on a toasted bun.',
      'price': 155,
      'qty': 1,
    },
    {
      'name': 'Red Sauce Pasta',
      'image': 'assets/images/menu3.png',
      'desc':
          'Pasta with red tomato sauce, made from blended tomatoes, garlic, onions, and herbs.',
      'price': 175,
      'qty': 1,
    },
    {
      'name': 'Protein Sandwich',
      'image': 'assets/images/menu4.png',
      'desc':
          'Freshly baked bread filled with sliced vegetables, cheese, sauces, and your choice of deli-style meats.',
      'price': 225,
      'qty': 1,
    },
    {
      'name': 'Hot Coffee',
      'image': 'assets/images/menu5.png',
      'desc':
          'Hot brewed coffee made from roasted ground beans, served fresh in a cup with milk or sugar.',
      'price': 225,
      'qty': 1,
    },
    {
      'name': 'Coca Cola with Ice',
      'image': 'assets/images/menu6.png',
      'desc':
          'Chilled Coca-Cola served cold in a glass or bottle, fizzy, dark, and carbonated with a sweet taste.',
      'price': 55,
      'qty': 1,
    },
    {
      'name': 'Blue Lagoon',
      'image': 'assets/images/menu7.png',
      'desc':
          'Bright blue mocktail made with lemon juice, blue curaçao syrup, and soda, served chilled over ice.',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Choco Pastry',
      'image': 'assets/images/menu8.png',
      'desc':
          'Flaky, baked pastry filled with rich chocolate, topped with a glossy glaze & dusting of cocoa powder.',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Classic Donut',
      'image': 'assets/images/menu9.png',
      'desc':
          'Soft, round donut coated in chocolate glaze, sometimes filled with chocolate cream, topped with sprinkles.',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Crispy Fries',
      'image': 'assets/images/menu1.png',
      'desc':
          'Cooked in pure olive oil, garnished with a himalayan salt and served with garlic sauce',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Veggie Burger',
      'image': 'assets/images/menu2.png',
      'desc':
          'Plant-based burger with a hearty veggie patty, fresh lettuce, tomato, pickles, and creamy sauce on a toasted bun.',
      'price': 155,
      'qty': 1,
    },
    {
      'name': 'Red Sauce Pasta',
      'image': 'assets/images/menu3.png',
      'desc':
          'Pasta with red tomato sauce, made from blended tomatoes, garlic, onions, and herbs.',
      'price': 175,
      'qty': 1,
    },
    {
      'name': 'Protein Sandwich',
      'image': 'assets/images/menu4.png',
      'desc':
          'Freshly baked bread filled with sliced vegetables, cheese, sauces, and your choice of deli-style meats.',
      'price': 225,
      'qty': 1,
    },
    {
      'name': 'Hot Coffee',
      'image': 'assets/images/menu5.png',
      'desc':
          'Hot brewed coffee made from roasted ground beans, served fresh in a cup with milk or sugar.',
      'price': 225,
      'qty': 1,
    },
    {
      'name': 'Coca Cola with Ice',
      'image': 'assets/images/menu6.png',
      'desc':
          'Chilled Coca-Cola served cold in a glass or bottle, fizzy, dark, and carbonated with a sweet taste.',
      'price': 55,
      'qty': 1,
    },
    {
      'name': 'Blue Lagoon',
      'image': 'assets/images/menu7.png',
      'desc':
          'Bright blue mocktail made with lemon juice, blue curaçao syrup, and soda, served chilled over ice.',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Choco Pastry',
      'image': 'assets/images/menu8.png',
      'desc':
          'Flaky, baked pastry filled with rich chocolate, topped with a glossy glaze & dusting of cocoa powder.',
      'price': 125,
      'qty': 1,
    },
    {
      'name': 'Classic Donut',
      'image': 'assets/images/menu9.png',
      'desc':
          'Soft, round donut coated in chocolate glaze, sometimes filled with chocolate cream, topped with sprinkles.',
      'price': 125,
      'qty': 1,
    },
  ];

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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ListView.builder(
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final menuItem = menuItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ListTile(
                leading: SizedBox(
                  width: 70,
                  height: 50,
                  child: Image.asset(
                    menuItem['image']!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                title: Text(
                  menuItem['name']!,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  menuItem['desc']!,
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
                      'Rs. ${menuItem['price']!}',
                      style: GoogleFonts.inter(
                        color: Color(0xFF6DFB60),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => addToCart(menuItem),
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
                        child: Image.asset(
                          cartItem['image']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${cartItem['name']}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                      const Spacer(),
                      Text(
                        'Rs. ${cartItem['price']!}',
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
