import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_coin/cubit/create_offer_cubit.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class HashCoinWidget extends StatefulWidget {
  final int hashCoin;
  final CreateOfferCubit createOfferCubit;
  
  const HashCoinWidget({
    super.key, 
    required this.hashCoin,
    required this.createOfferCubit,
  });

  @override
  State<HashCoinWidget> createState() => _HashCoinWidgetState();
}

class _HashCoinWidgetState extends State<HashCoinWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _coinRotationController;
  late AnimationController _floatController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _particleAnimation;

  // Helper method to format hash coin numbers
  String _formatHashCoins(int coins) {
    if (coins >= 1000) {
      double kValue = coins / 1000.0;
      return kValue.toStringAsFixed(kValue.truncateToDouble() == kValue ? 0 : 1) + 'K';
    }
    return coins.toString();
  }

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the main container
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Glow animation for the neon effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Coin rotation animation
    _coinRotationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _coinRotationController, curve: Curves.linear),
    );
    
    // Floating animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _coinRotationController.repeat();
    _floatController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _coinRotationController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hash Coins',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            child: Column(
              children: [
                _buildMainCoinCard(),
                const SizedBox(height: 30),
                _buildStatsCard(),
                const SizedBox(height: 30),
                _buildHowToEarnCard(),
                const SizedBox(height: 30),
                _buildRedeemCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            animation: _particleAnimation,
            hashCoins: widget.hashCoin,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainCoinCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffDE3A3A).withOpacity(_glowAnimation.value * 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      // Animated coin icon with 3D effect
                      _build3DCoinIcon(),
                      const SizedBox(height: 24),
                      _buildCoinAmount(),
                      const SizedBox(height: 16),
                      _buildStatusBadge(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build3DCoinIcon() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xffDE3A3A),
                  Color(0xffF4C342),
                  Color(0xff37ebf3),
                  Color(0xffcb1dcd),
                  Color(0xffDE3A3A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffDE3A3A).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Color(0xffDE3A3A),
                size: 50,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinAmount() {
    return Column(
      children: [
        Text(
          _formatHashCoins(widget.hashCoin),
          style: GoogleFonts.play(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: const Color(0xffDE3A3A).withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'HASH COINS',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xffDE3A3A),
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xffDE3A3A).withOpacity(0.3),
            const Color(0xffF4C342).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xffDE3A3A).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xffDE3A3A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffDE3A3A).withOpacity(0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Available for Redemption',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffDE3A3A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Color(0xffDE3A3A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Stats',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatItem(
                      icon: Icons.trending_up,
                      label: 'Total Earned',
                      value: _formatHashCoins((widget.hashCoin * 1.5).toInt()),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildModernStatItem(
                      icon: Icons.redeem,
                      label: 'Redeemed',
                      value: _formatHashCoins((widget.hashCoin * 0.3).toInt()),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.play(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffF4C342).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: Color(0xffF4C342),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'How to Earn',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildModernEarnItem(
                icon: Icons.games,
                title: 'Play Games',
                description: 'Earn coins for every gaming session',
                coins: _formatHashCoins(50),
                gradient: const LinearGradient(
                  colors: [Color(0xffDE3A3A), Color(0xffcb1dcd)],
                ),
              ),
              const SizedBox(height: 16),
              _buildModernEarnItem(
                icon: Icons.share,
                title: 'Refer Friends',
                description: 'Get bonus coins for successful referrals',
                coins: _formatHashCoins(100),
                gradient: const LinearGradient(
                  colors: [Color(0xffF4C342), Color(0xffDE3A3A)],
                ),
              ),
              const SizedBox(height: 16),
              _buildModernEarnItem(
                icon: Icons.star,
                title: 'Daily Login',
                description: 'Collect daily rewards',
                coins: _formatHashCoins(25),
                gradient: const LinearGradient(
                  colors: [Color(0xff37ebf3), Color(0xffF4C342)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernEarnItem({
    required IconData icon,
    required String title,
    required String description,
    required String coins,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$coins',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffDE3A3A).withOpacity(0.15),
            const Color(0xffF4C342).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xffDE3A3A).withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffDE3A3A).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffDE3A3A), Color(0xffF4C342)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to Redeem?',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your hash coins to get exclusive rewards and discounts',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  _showRedeemBottomSheet(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffDE3A3A), Color(0xffF4C342)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffDE3A3A).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    'Redeem Now',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemBottomSheet(BuildContext context) {
    int? selectedVoucher;
    final vouchers = [
      {
        'discount': 10,
        'requiredCoins': 10000,
        'code': 'Hash10',
        'desc': 'Redeem for just 10,000 HashCoins.'
      },
      {
        'discount': 20,
        'requiredCoins': 20000,
        'code': 'Hash20',
        'desc': 'Redeem for just 20,000 HashCoins.'
      },
      {
        'discount': 30,
        'requiredCoins': 30000,
        'code': 'Hash30',
        'desc': 'Redeem for just 30,000 HashCoins.'
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BlocProvider.value(
          value: widget.createOfferCubit,
          child: BlocListener<CreateOfferCubit, CreateOfferState>(
            listener: (context, state) {
              if (state is CreateOfferLoading) {
                _showLoadingSnackbar();
              } else if (state is CreateOfferSuccess) {
                Navigator.pop(context);
                _showSuccessSnackbar('Successfully redeemed! Your voucher has been created.');
              } else if (state is CreateOfferFailure) {
                Navigator.pop(context);
                _showErrorSnackbar(state.message);
              }
            },
            child: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Close button
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // HashCoins Balance
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.hexagon, color: Colors.green, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HashCoins Balance',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatHashCoins(widget.hashCoin),
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use your HashCoins to unlock exclusive discounts on your bookings',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Vouchers',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: vouchers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final voucher = vouchers[i];
                                  final int requiredCoins = voucher['requiredCoins'] as int;
                                  final int discount = voucher['discount'] as int;
                                  final String code = voucher['code'] as String;
                                  final String desc = voucher['desc'] as String;
                                  final bool hasEnough = widget.hashCoin >= requiredCoins;
                                  final bool isSelected = selectedVoucher == i;
                                  final int coinsNeeded = requiredCoins - widget.hashCoin;
                                  return GestureDetector(
                                    onTap: hasEnough
                                        ? () {
                                            setState(() {
                                              selectedVoucher = i;
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.01),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.green
                                              : hasEnough
                                                  ? Colors.white.withOpacity(0.2)
                                                  : Colors.grey.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.card_giftcard,
                                            color: hasEnough ? Colors.white : Colors.grey,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Flat $discount% OFF',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w700,
                                                        color: hasEnough ? Colors.white : Colors.grey,
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 8.0),
                                                        child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: hasEnough ? Colors.white70 : Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: hasEnough ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: hasEnough ? Colors.green : Colors.grey,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (!hasEnough)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Text(
                                                      'You need \'${_formatHashCoins(coinsNeeded)}\' more HashCoins to redeem this voucher.',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Radio<int>(
                                            value: i,
                                            groupValue: selectedVoucher,
                                            onChanged: hasEnough
                                                ? (val) {
                                                    setState(() {
                                                      selectedVoucher = val;
                                                    });
                                                  }
                                                : null,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<CreateOfferCubit, CreateOfferState>(
                              builder: (context, state) {
                                final isLoading = state is CreateOfferLoading;
                                return GestureDetector(
                                  onTap: (selectedVoucher != null && !isLoading)
                                      ? () {
                                          final voucher = vouchers[selectedVoucher!];
                                          final int discount = voucher['discount'] as int;
                                          _processRedemption(discount);
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    decoration: BoxDecoration(
                                      color: (selectedVoucher != null && !isLoading)
                                          ? Colors.green
                                          : Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Processing...',
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Redeem',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _processRedemption(int percentage) async {
    // Calculate required coins based on percentage
    int requiredCoins;
    switch (percentage) {
      case 10:
        requiredCoins = 10000;
        break;
      case 20:
        requiredCoins = 20000;
        break;
      case 30:
        requiredCoins = 30000;
        break;
      default:
        requiredCoins = 10000;
    }
    
    // Check if user has enough coins
    if (widget.hashCoin >= requiredCoins) {
      try {
        final remoteRepo = locator<RemoteRepoInterface>();
        final userData = await remoteRepo.getUserFromPreferences();
        
        if (userData != null) {
          final userId = userData['id']?.toString() ?? '';
          if (userId.isNotEmpty) {
            // Use the CreateOfferCubit to process the redemption
            widget.createOfferCubit.createOffer(percentage, userId);
          } else {
            _showErrorSnackbar('User ID not found');
          }
        } else {
          _showErrorSnackbar('User data not found');
        }
      } catch (e) {
        _showErrorSnackbar('Error processing redemption: $e');
      }
    } else {
      _showErrorSnackbar('Insufficient coins. You need ${_formatHashCoins(requiredCoins)} coins for $percentage% redemption.');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLoadingSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Processing redemption...',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xffDE3A3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final int hashCoins;

  ParticlePainter({required this.animation, required this.hashCoins});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    final particleCount = math.min(hashCoins ~/ 10, 50);

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;
      final opacity = random.nextDouble() * 0.3 + 0.1;
      
      paint.color = const Color(0xffDE3A3A).withOpacity(opacity);
      
      final offset = Offset(
        x + math.sin(animation.value * 2 * math.pi + i) * 20,
        y + math.cos(animation.value * 2 * math.pi + i) * 20,
      );
      
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
