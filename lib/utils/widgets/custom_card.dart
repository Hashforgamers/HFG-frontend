// early_access_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EarlyAccessCard extends StatefulWidget {
  final String title;
  final String subTitle;
  final String siteUrl;
  const EarlyAccessCard(
      {super.key,
      required this.title,
      required this.subTitle,
      required this.siteUrl});
  @override
  State<EarlyAccessCard> createState() => _EarlyAccessCardState();
}

class _EarlyAccessCardState extends State<EarlyAccessCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(widget.siteUrl))) {
          await launchUrl(Uri.parse(widget.siteUrl),
              mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar('Error', 'Could not launch article');
        }
      }, // mobile “hover”
      child: Container(
        width: Get.width * 0.85,
        child: CustomPaint(
          painter: _CardPainter(hover: _hover),
          child: Padding(
            // ignore: prefer_const_constructors
            padding: EdgeInsets.fromLTRB(30, 20, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 20, // text-lg
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ), // ⚡️
                const SizedBox(height: 12),
                Text(
                  widget.subTitle,
                  style: GoogleFonts.inter(
                    fontSize: 12, // text-lg
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  ' Read Article',
                  style: GoogleFonts.inter(
                    fontSize: 12, // text-base
                    height: 1.45,
                    color: const Color(0xFF9CA3AF), // gray-400
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*────────────────────────  Painter & clipper  ────────────────────────*/

class _CardPainter extends CustomPainter {
  _CardPainter({required this.hover});
  final bool hover;

  static Path _polygon(Size size) {
    final double w = size.width;
    final double h = size.height;

    const slantW = 0.08; // 6% horizontal slant
    const midH = 0.35; // how steep the left side cuts (reduce if needed)
    const rightH =
        0.55; // where the right side slants inward (reduce to make shorter)

    return Path()
      ..moveTo(w * (slantW * 1.5), 0) // top-left small slant
      ..lineTo(0, h * midH) // left-mid inwards
      ..lineTo(0, h * 0.85) // ↓ instead of full h (shorter height)
      ..lineTo(w * (1 - slantW * 1.5), h * 0.85) // bottom-left inward
      ..lineTo(w, h * rightH) // right-mid inward
      ..lineTo(w, 0) // top-right
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _polygon(size);

    if (hover) {
      // green glow identical to Tailwind shadow-[0_0_20px_#1fff96]
      canvas.drawShadow(
          path, const Color(0xFF1FFF96).withOpacity(.6), 12, false);
    }

    // background fill
    final fillPaint = Paint()..color = const Color(0xFF121C16); // #121c16
    canvas.drawPath(path, fillPaint);

    // 1-pixel border
    final borderPaint = Paint()
      ..color = const Color(0xFF1E2A24) // #1e2a24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);

    // clip **after** drawing border so child widgets stay inside shape
    canvas.clipPath(path);
  }

  @override
  bool shouldRepaint(covariant _CardPainter old) => old.hover != hover;
}
