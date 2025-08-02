import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  List<Map<String, String>> menuItems = [
    {
      'name': 'Crispy Fries',
      'image': 'assets/images/menu1.png',
      'desc':
          'Cooked in pure olive oil, garnished with a himalayan salt and served with garlic sauce',
      'price': '125',
    },
    {
      'name': 'Veggie Burger',
      'image': 'assets/images/menu2.png',
      'desc':
          'Plant-based burger with a hearty veggie patty, fresh lettuce, tomato, pickles, and creamy sauce on a toasted bun.',
      'price': '155',
    },
    {
      'name': 'Red Sauce Pasta',
      'image': 'assets/images/menu3.png',
      'desc':
          'Pasta with red tomato sauce, made from blended tomatoes, garlic, onions, and herbs.',
      'price': '175',
    },
    {
      'name': 'Protein Sandwich',
      'image': 'assets/images/menu4.png',
      'desc':
          'Freshly baked bread filled with sliced vegetables, cheese, sauces, and your choice of deli-style meats.',
      'price': '225',
    },
    {
      'name': 'Hot Coffee',
      'image': 'assets/images/menu5.png',
      'desc':
          'Hot brewed coffee made from roasted ground beans, served fresh in a cup with milk or sugar.',
      'price': '225',
    },
    {
      'name': 'Coca Cola with Ice',
      'image': 'assets/images/menu6.png',
      'desc':
          'Chilled Coca-Cola served cold in a glass or bottle, fizzy, dark, and carbonated with a sweet taste.',
      'price': '55',
    },
    {
      'name': 'Blue Lagoon',
      'image': 'assets/images/menu7.png',
      'desc':
          'Bright blue mocktail made with lemon juice, blue curaçao syrup, and soda, served chilled over ice.',
      'price': '125',
    },
    {
      'name': 'Choco Pastry',
      'image': 'assets/images/menu8.png',
      'desc':
          'Flaky, baked pastry filled with rich chocolate, topped with a glossy glaze & dusting of cocoa powder.',
      'price': '125',
    },
    {
      'name': 'Classic Donut',
      'image': 'assets/images/menu9.png',
      'desc':
          'Soft, round donut coated in chocolate glaze, sometimes filled with chocolate cream, topped with sprinkles.',
      'price': '125',
    },
    {
      'name': 'Crispy Fries',
      'image': 'assets/images/menu1.png',
      'desc':
          'Cooked in pure olive oil, garnished with a himalayan salt and served with garlic sauce',
      'price': '125',
    },
    {
      'name': 'Veggie Burger',
      'image': 'assets/images/menu2.png',
      'desc':
          'Plant-based burger with a hearty veggie patty, fresh lettuce, tomato, pickles, and creamy sauce on a toasted bun.',
      'price': '155',
    },
    {
      'name': 'Red Sauce Pasta',
      'image': 'assets/images/menu3.png',
      'desc':
          'Pasta with red tomato sauce, made from blended tomatoes, garlic, onions, and herbs.',
      'price': '175',
    },
    {
      'name': 'Protein Sandwich',
      'image': 'assets/images/menu4.png',
      'desc':
          'Freshly baked bread filled with sliced vegetables, cheese, sauces, and your choice of deli-style meats.',
      'price': '225',
    },
    {
      'name': 'Hot Coffee',
      'image': 'assets/images/menu5.png',
      'desc':
          'Hot brewed coffee made from roasted ground beans, served fresh in a cup with milk or sugar.',
      'price': '225',
    },
    {
      'name': 'Coca Cola with Ice',
      'image': 'assets/images/menu6.png',
      'desc':
          'Chilled Coca-Cola served cold in a glass or bottle, fizzy, dark, and carbonated with a sweet taste.',
      'price': '55',
    },
    {
      'name': 'Blue Lagoon',
      'image': 'assets/images/menu7.png',
      'desc':
          'Bright blue mocktail made with lemon juice, blue curaçao syrup, and soda, served chilled over ice.',
      'price': '125',
    },
    {
      'name': 'Choco Pastry',
      'image': 'assets/images/menu8.png',
      'desc':
          'Flaky, baked pastry filled with rich chocolate, topped with a glossy glaze & dusting of cocoa powder.',
      'price': '125',
    },
    {
      'name': 'Classic Donut',
      'image': 'assets/images/menu9.png',
      'desc':
          'Soft, round donut coated in chocolate glaze, sometimes filled with chocolate cream, topped with sprinkles.',
      'price': '125',
    },
  ];

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final menuItem = menuItems[index];
              return ListTile(
                leading: Image.asset(
                  menuItem['image']!,
                  width: 46,
                  height: 46,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
