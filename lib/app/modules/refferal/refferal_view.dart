import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hash/app/data/services/user_controller.dart';

class RefferalView extends StatelessWidget {
  RefferalView({Key? key}) : super(key: key);

  /* -------------------------------------------------------------------------- */
  /*  CONSTANTS & THEME                                                         */
  /* -------------------------------------------------------------------------- */
  final Color _accent      = const Color(0xffDE3A3A);          // brand red
  final Color _bannerGold  = const Color(0xffF4C342);          // yellow ribbon
  final Color _darkCard    = const Color(0xff0F0F0F);          // card bg
  final TextStyle _heading = GoogleFonts.inter(
      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18);

  /* -------------------------------------------------------------------------- */
  /*  WIDGET BUILDERS                                                           */
  /* -------------------------------------------------------------------------- */

  // 1️⃣ PROGRESS CARD (left phone in screenshot) ------------------------------
  Widget _tierProgressCard() {
    /// fake progress; replace with real values if you have them
    const currentReferrals = 5;
    const tier1 = 1; const tier2 = 5; const tier3 = 10;
    const amountEarnable = '₹25,000';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _darkCard, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount you will Earn', style: _heading.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(amountEarnable,
              style: GoogleFonts.inter(
                  fontSize: 32, fontWeight: FontWeight.w800, color: _accent)),
          const SizedBox(height: 16),
          Text('When you refer', style: _heading.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          _tierSlider(currentReferrals, [tier1, tier2, tier3]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xff008BFF), const Color(0xff0FEBFF)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('Refer Now',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(height: 24),
          Text('How it Works', style: _heading),
          const SizedBox(height: 14),
          _howItWorksStep('Share your referral link/code with your friends',
              Icons.share),
          _howItWorksStep(
              'Friend registers on HashforGamers using your link/code',
              Icons.person_add_alt_1),
          _howItWorksStep(
              'You both earn rewards when your friend makes a booking',
              Icons.card_giftcard),
        ],
      ),
    );
  }

  Widget _tierSlider(int current, List<int> tiers) {
    return Column(children: [
      SliderTheme(
        data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white12,
            thumbColor: _accent,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
        child: Slider(
          value: current.toDouble(),
          min: 0,
          max: tiers.last.toDouble(),
          onChanged: (_) {},
        ),
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tiers
              .map((t) => Text('TIER $t',
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 11,
                  fontWeight: FontWeight.w500)))
              .toList()),
    ]);
  }

  Widget _howItWorksStep(String text, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: _accent),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
      )
    ]),
  );

  // 2️⃣ REFERRAL CARD (center phone) ------------------------------------------
  Widget _centralReferralCard(BuildContext ctx) {
    final code =
        Get.find<UserController>().user.value.referralCode ?? 'HASH1234';

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1C1C1E), Color(0xff000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        // yellow banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 30),
          decoration: BoxDecoration(
              color: _bannerGold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: _bannerGold.withOpacity(.4),
                    spreadRadius: 1,
                    blurRadius: 8)
              ]),
          child: Text('Refer & Earn  ₹₹ Unlimited',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, color: Colors.black)),
        ),
        const SizedBox(height: 28),
        Text('Your Referral Code',
            style:
            GoogleFonts.inter(color: Colors.white60, letterSpacing: 0.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
              border: Border.all(color: _accent, width: 2),
              borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(code,
                style: GoogleFonts.play(
                    fontSize: 26,
                    color: _accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Share.share(
                    'Join HashforGamers with my code 👉 $code (unlimited rewards!)');
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Referral code ready to share!')));
              },
              child: const Icon(Icons.copy, color: Colors.white70, size: 20),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Text('REFER VIA',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: _shareBtns()),
        const SizedBox(height: 20),
        // mini progress inside the central card
        _miniProgressBar(),
      ]),
    );
  }

  List<Widget> _shareBtns() {
    List<(IconData, Color)> items = [
      (Icons.facebook_rounded, const Color(0xff1877F2)),
      (Icons.mail_outline, Colors.white),
      (Icons.share, _accent)
    ];
    return items
        .map((e) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: e.$2.withOpacity(.15),
        child: Icon(e.$1, color: e.$2, size: 20),
      ),
    ))
        .toList();
  }

  Widget _miniProgressBar() => Column(children: [
    Text('Earn More with our Tiered Rewards',
        style:
        GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
    const SizedBox(height: 14),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text('₹25,000',
            style: GoogleFonts.inter(
                color: _accent,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _tierSlider(5, [1, 5, 10]),
      ]),
    )
  ]);

  // 3️⃣ HOW-IT-WORKS + FAQ (right phone) --------------------------------------
  Widget _howItWorksFaqCard() {
    final faqs = [
      ('Who can register as a subscriber?', 'Anyone above 13 years old.'),
      ('Which games are available?', 'All major PC titles and in-café titles.'),
      ('What are Hash Coins?', 'Reward points redeemable in our store.'),
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _darkCard, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How it Works', style: _heading),
        const SizedBox(height: 18),
        _howItWorksStep('Share referral link/code with friends', Icons.share),
        _howItWorksStep('Friend registers with your code', Icons.person_add),
        _howItWorksStep('Both earn cash rewards', Icons.currency_rupee),
        const SizedBox(height: 24),
        Text('Frequently Asked Questions', style: _heading),
        const SizedBox(height: 12),
        ...faqs.map((f) => _faqItem(f.$1, f.$2))
      ]),
    );
  }

  Widget _faqItem(String q, String a) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.white60,
        iconColor: _accent,
        title: Text(q,
            style:
            GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(a,
                style: GoogleFonts.inter(
                    color: Colors.white60, fontSize: 13)),
          )
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*  SCAFFOLD                                                                  */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Text('Refer & Earn',
            style: GoogleFonts.inter(
                color: _accent, fontWeight: FontWeight.w700, fontSize: 22)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient:
          LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Colors.transparent,
            Color(0xff073A10),
          ]),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(children: [
            _tierProgressCard(),
            const SizedBox(height: 26),
            _centralReferralCard(context),
            const SizedBox(height: 26),
            _howItWorksFaqCard(),
          ]),
        ),
      ),
    );
  }
}
