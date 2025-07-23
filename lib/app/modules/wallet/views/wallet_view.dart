import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; // <-- free neon-style icon set
import '../controllers/razorpay_wallet_controller.dart';
import '../controllers/wallet_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final walletCtr = Get.find<WalletController>();
  final razorpayCtr = Get.put(RazorpayWalletController());
  final TextEditingController amountController = TextEditingController();
  final segmentService = locator<SegmentSdkService>();

  @override
  void initState() {
    super.initState();
    // Track wallet viewed event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        segmentService.onWalletViewed(userId: currentUser.uid);
      }
    });
  }

  // ───────────────────────── UI BUILD ──────────────────────────
  @override
  Widget build(BuildContext context) {
    walletCtr.fetchWallet();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar:
          true, // Important for gradient to cover AppBar too
      appBar: AppBar(
        title: const Text("Wallet"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (walletCtr.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          );
        }

        return Stack(
          children: [
            // ─────── Fullscreen Gradient Background ───────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF001b11).withOpacity(0.2), // Deep greenish-black
                      Color(0xFF020a1f).withOpacity(0.2), // Bluish-black
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.5,
                      colors: [
                        Color(0x4400FFAA).withOpacity(0.2),
                        Colors.transparent,
                      ],
                      center: Alignment.topLeft,
                    ),
                  ),
                ),
              ),
            ),

            // ─────── Scrollable Foreground ───────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 100, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _balanceCard(),
                  const SizedBox(height: 28),
                  _topUpPanel(context),
                  const SizedBox(height: 30),
                  _quickTopUp(),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ────────────────────────── WIDGETS ──────────────────────────
  Widget _balanceCard() {
    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
            ),
            padding: const EdgeInsets.all(12),
            child:
                const Icon(PhosphorIconsFill.wallet, color: Colors.greenAccent),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WALLET BALANCE",
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "₹ ${walletCtr.balance}",
                style: GoogleFonts.orbitron(
                  fontSize: 30,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topUpPanel(BuildContext ctx) {
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Top-up Wallet",
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter amount (Min ₹50)",
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              prefixIcon: Icon(PhosphorIcons.currencyInr(),
                  color: Colors.greenAccent, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: _border(),
              focusedBorder: _border(color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flash_on, color: Colors.black),
              label: Text("TOP-UP NOW",
                  style: GoogleFonts.inter(
                      color: Colors.black, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final amt = int.tryParse(amountController.text.trim());
                if (amt == null || amt < 50) {
                  Get.snackbar("Invalid", "Minimum top-up is ₹50",
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }
                razorpayCtr.pay(amt);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickTopUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Top-up",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [100, 250, 500, 1000].map((int amt) {
            return GestureDetector(
              onTap: () => razorpayCtr.pay(amt),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00ff90), Color(0xFF00c56b)],
                  ),
                ),
                child: Text(
                  "₹$amt",
                  style: GoogleFonts.orbitron(
                      fontSize: 14, color: Colors.black, letterSpacing: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ────────────────────────── HELPERS ──────────────────────────
  OutlineInputBorder _border({Color color = Colors.white24}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1),
      );

  /// glass-morphic reusable card
  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 0,
          )
        ],
      ),
      child: child,
    );
  }
}
