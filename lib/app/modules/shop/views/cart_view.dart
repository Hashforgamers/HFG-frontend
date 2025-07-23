import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/widgets/glow_neon_loader.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/address_controller.dart';

class CartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    final CheckoutController checkoutController = Get.put(CheckoutController());
    final AddressController addressController = Get.put(AddressController());

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: GestureDetector(
          onTap: () {
            checkoutController.checkout();
          },
          child: Container(
            height: 45,
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color(0xffDE3A3A),
            ),
            child: Center(
              child: Obx(() {
                if (checkoutController.isLoading.value) {
                  return RainbowGlowingLoader(size: 50);
                } else {
                  return Text(
                    'Checkout',
                    style: GoogleFonts.inter(color: Colors.black),
                  );
                }
              }),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: false,
        title: Text('Cart', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xffDE3A3A),
          ),
        ),
      ),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return const Center(
            child: RainbowGlowingLoader(size: 50),
          );
        } else if (cartController.cartItems.isEmpty) {
          return Center(
              child: Text(
            'Cart is empty',
            style: GoogleFonts.inter(color: Colors.white),
          ));
        } else {
          return Column(
            children: [
              Expanded(child: buildCartItemList(cartController)),
              buildPaymentOptionSection(checkoutController),
              const SizedBox(height: 10),
              buildDeliveryAddressSection(addressController),
            ],
          );
        }
      }),
    );
  }

  Widget buildCartItemList(CartController cartController) {
    return ListView.builder(
      itemCount: cartController.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartController.cartItems[index];
        return ListTile(
          leading: Container(
            width: 60,
            decoration: ShapeDecoration(
              shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Color(0xff121212),
            ),
          ),
          title: Text('Product ID: ${item.productId}',
              style: GoogleFonts.inter(color: Colors.white)),
          subtitle: Text('Quantity: ${item.quantity}',
              style: GoogleFonts.inter(color: Colors.white70)),
          trailing: IconButton(
            icon: const Icon(CupertinoIcons.delete, color: Colors.red),
            onPressed: () {
              cartController.deleteCartItem(item.productId);
            },
          ),
        );
      },
    );
  }

  Widget buildPaymentOptionSection(CheckoutController checkoutController) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xff121212),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Option',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          Obx(() {
            return Column(
              children: [
                RadioListTile(
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  activeColor: Color(0xffDE3A3A),
                  title: Text('Wallet',
                      style: GoogleFonts.inter(color: Colors.white)),
                  value: 'wallet',
                  groupValue: checkoutController.paymentMethod.value,
                  onChanged: (value) {
                    checkoutController.paymentMethod.value = value!;
                  },
                ),
                RadioListTile(
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  activeColor: Color(0xffDE3A3A),
                  title: Text('Other',
                      style: GoogleFonts.inter(color: Colors.white)),
                  value: 'other',
                  groupValue: checkoutController.paymentMethod.value,
                  onChanged: (value) {
                    checkoutController.paymentMethod.value = value!;
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget buildDeliveryAddressSection(AddressController addressController) {
    return Container(
      margin: EdgeInsets.all(10),
      width: Get.width,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xff121212),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          Obx(() {
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: addressController.activeAddress.value['addressLine1'],
                dropdownColor: Colors.black,
                icon: const Icon(
                  Icons.arrow_drop_down_outlined,
                  color: Color(0xffDE3A3A),
                ),
                iconSize: 24,
                elevation: 16,
                style: GoogleFonts.inter(color: Colors.white),
                isDense: true, // Remove the underline
                isExpanded: true, // Use full width
                onChanged: (String? newValue) {
                  var selectedAddress = addressController.addresses.firstWhere(
                      (address) => address['addressLine1'] == newValue);
                  addressController.activeAddress.value = selectedAddress;
                },
                items: addressController.addresses
                    .map<DropdownMenuItem<String>>((address) {
                  return DropdownMenuItem<String>(
                    value: address['addressLine1'],
                    child: Text(address['addressLine1']),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
