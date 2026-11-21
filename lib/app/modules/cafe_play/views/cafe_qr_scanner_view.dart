import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _green = Color(0xFF00DC00);
const _greenBright = Color(0xFF6BFF6B);
const _bg = Color(0xFF030A04);

/// Full-screen camera that pops with the first scanned raw value.
///
/// The camera shows through a glowing frame; everything around it is a
/// dark HUD overlay. A QR can also be decoded from a gallery image.
class CafeQrScannerView extends StatefulWidget {
  const CafeQrScannerView({super.key});

  @override
  State<CafeQrScannerView> createState() => _CafeQrScannerViewState();
}

class _CafeQrScannerViewState extends State<CafeQrScannerView>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  bool _done = false;
  bool _picking = false;

  @override
  void dispose() {
    _sweep.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final value = code.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  Future<void> _scanFromGallery() async {
    if (_picking || _done) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _picking = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      final capture = await _controller.analyzeImage(
        image.path,
        formats: const [BarcodeFormat.qrCode],
      );
      if (!mounted) return;
      if (capture == null || capture.barcodes.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No QR code found in that image.')),
        );
        return;
      }
      _onDetect(capture);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Couldn\'t read that image.')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = MediaQuery.paddingOf(context);
          final size = constraints.biggest;
          final frameW = (size.width - 64).clamp(0.0, 420.0);
          final frameH = frameW * 0.9;
          final frame = Rect.fromLTWH(
            (size.width - frameW) / 2,
            pad.top + (size.height * 0.24).clamp(170.0, 230.0),
            frameW,
            frameH,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _BackdropPainter(frame)),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, _) => CustomPaint(
                      painter: _FramePainter(frame, _sweep.value),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: pad.top + 18,
                child: const _Header(),
              ),
              Positioned(
                left: 8,
                top: pad.top + 8,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                left: frame.left,
                right: size.width - frame.right,
                top: frame.bottom + 36,
                child: const _HintPill(),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: pad.bottom + 28,
                child: Row(
                  children: [
                    Expanded(
                      child: _HexAction(
                        icon: Icons.image_outlined,
                        label: 'Scan from gallery',
                        busy: _picking,
                        onTap: _scanFromGallery,
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (_, state, _) {
                          final on = state.torchState == TorchState.on;
                          return _HexAction(
                            icon: on
                                ? Icons.flashlight_on_rounded
                                : Icons.flashlight_off_rounded,
                            label: on ? 'Flash on' : 'Flashlight',
                            active: on,
                            onTap: state.torchState == TorchState.unavailable
                                ? null
                                : _controller.toggleTorch,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderBar(),
        const SizedBox(height: 22),
        Text(
          'Scan QR',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(color: _green.withValues(alpha: 0.7), blurRadius: 18),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan the QR on the PC screen to play',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// The segmented glowing bar above the title.
class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    Widget seg(double w, double a) => Container(
      width: w,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: a),
        boxShadow: [
          BoxShadow(color: _green.withValues(alpha: a * 0.6), blurRadius: 6),
        ],
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) seg(5, 0.5),
        const SizedBox(width: 4),
        seg(110, 1),
        const SizedBox(width: 4),
        for (var i = 0; i < 4; i++) seg(5, 0.5),
      ],
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ChamferBoxPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: _greenBright, size: 30),
            Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: _green.withValues(alpha: 0.4),
            ),
            Expanded(
              child: Text(
                'Align the QR code within the frame',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexAction extends StatelessWidget {
  const _HexAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 132,
                height: 76,
                child: CustomPaint(
                  painter: _HexPainter(active: active),
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _greenBright,
                            ),
                          )
                        : Icon(
                            icon,
                            color: active ? _greenBright : Colors.white,
                            size: 34,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── painters ─────────────────────────

Paint _glow(Color color, double width, double blur) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

Paint _line(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Path _chamfer(Rect r, double c) => Path()
  ..moveTo(r.left + c, r.top)
  ..lineTo(r.right - c, r.top)
  ..lineTo(r.right, r.top + c)
  ..lineTo(r.right, r.bottom - c)
  ..lineTo(r.right - c, r.bottom)
  ..lineTo(r.left + c, r.bottom)
  ..lineTo(r.left, r.bottom - c)
  ..lineTo(r.left, r.top + c)
  ..close();

/// Dark HUD around the camera cutout, with diagonal light streaks and
/// side ticks.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final cutout = _chamfer(frame.deflate(6), 22);
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full)
      ..addPath(cutout, Offset.zero);

    canvas.drawPath(
      shade,
      Paint()
        ..shader = ui.Gradient.radial(frame.center, size.longestSide * 0.75, [
          const Color(0xF0062A0C),
          const Color(0xFA020803),
        ]),
    );

    // Diagonal streaks from the screen corners toward the frame.
    final streaks = [
      (Offset(0, size.height * 0.08), Offset(frame.left - 10, frame.top + 30)),
      (
        Offset(size.width, size.height * 0.08),
        Offset(frame.right + 10, frame.top + 30),
      ),
      (
        Offset(0, size.height * 0.78),
        Offset(frame.left - 10, frame.bottom - 30),
      ),
      (
        Offset(size.width, size.height * 0.78),
        Offset(frame.right + 10, frame.bottom - 30),
      ),
    ];
    for (final (a, b) in streaks) {
      final shader = ui.Gradient.linear(a, b, [
        _green.withValues(alpha: 0),
        _green.withValues(alpha: 0.55),
      ]);
      canvas.drawLine(a, b, _glow(_green, 3, 5)..shader = shader);
      canvas.drawLine(a, b, _line(_green, 1)..shader = shader);
    }

    // Short glowing slashes at the top corners.
    for (final dx in [size.width * 0.2, size.width * 0.8]) {
      for (var i = 0; i < 3; i++) {
        final x = dx + (dx < size.width / 2 ? i * 9.0 : -i * 9.0);
        final p1 = Offset(x, 8);
        final p2 = Offset(x + 10, -6);
        canvas.drawLine(p1, p2, _line(_green.withValues(alpha: 0.7), 3));
      }
    }

    // Vertical tick ladders beside the frame.
    final tick = _line(_green.withValues(alpha: 0.65), 2);
    for (final x in [frame.left - 18, frame.right + 18]) {
      for (var i = 0; i < 9; i++) {
        final y = frame.top + frame.height * 0.32 + i * 9;
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), tick);
      }
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.frame != frame;
}

/// Glowing frame, corner brackets, faint grid and the sweeping scan line.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.frame, this.t);

  final Rect frame;

  /// 0..1 scan line position.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = frame.deflate(6);
    final outline = _chamfer(inner, 22);

    // Grid + crosshair, clipped to the camera window.
    canvas.save();
    canvas.clipPath(outline);
    final grid = _line(_green.withValues(alpha: 0.09), 1);
    for (var x = inner.left + 24; x < inner.right; x += 24) {
      canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), grid);
    }
    for (var y = inner.top + 24; y < inner.bottom; y += 24) {
      canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), grid);
    }
    final c = inner.center;
    final cross = _line(_green.withValues(alpha: 0.45), 1.2);
    canvas.drawLine(c.translate(-9, 0), c.translate(9, 0), cross);
    canvas.drawLine(c.translate(0, -9), c.translate(0, 9), cross);

    // Scan line with a soft trail.
    final y = inner.top + 14 + (inner.height - 28) * t;
    final trail = Rect.fromLTRB(inner.left, y - 46, inner.right, y);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = ui.Gradient.linear(trail.topCenter, trail.bottomCenter, [
          _green.withValues(alpha: 0),
          _green.withValues(alpha: 0.16),
        ]),
    );
    final a = Offset(inner.left, y);
    final b = Offset(inner.right, y);
    final fade = ui.Gradient.linear(
      a,
      b,
      [
        _green.withValues(alpha: 0),
        _greenBright,
        _greenBright,
        _green.withValues(alpha: 0),
      ],
      [0, 0.2, 0.8, 1],
    );
    canvas.drawLine(a, b, _glow(_green, 8, 8)..shader = fade);
    canvas.drawLine(a, b, _line(Colors.white, 1.6)..shader = fade);
    canvas.restore();

    // Thin outer frame.
    canvas.drawPath(outline, _glow(_green.withValues(alpha: 0.5), 3, 4));
    canvas.drawPath(outline, _line(_green.withValues(alpha: 0.8), 1.2));
    canvas.drawPath(
      _chamfer(frame.inflate(8), 30),
      _line(_green.withValues(alpha: 0.25), 1),
    );

    // Thick glowing corner brackets.
    const len = 64.0;
    const cut = 22.0;
    final r = inner;
    final corners = [
      Path()
        ..moveTo(r.left, r.top + len)
        ..lineTo(r.left, r.top + cut)
        ..lineTo(r.left + cut, r.top)
        ..lineTo(r.left + len, r.top),
      Path()
        ..moveTo(r.right - len, r.top)
        ..lineTo(r.right - cut, r.top)
        ..lineTo(r.right, r.top + cut)
        ..lineTo(r.right, r.top + len),
      Path()
        ..moveTo(r.right, r.bottom - len)
        ..lineTo(r.right, r.bottom - cut)
        ..lineTo(r.right - cut, r.bottom)
        ..lineTo(r.right - len, r.bottom),
      Path()
        ..moveTo(r.left + len, r.bottom)
        ..lineTo(r.left + cut, r.bottom)
        ..lineTo(r.left, r.bottom - cut)
        ..lineTo(r.left, r.bottom - len),
    ];
    for (final p in corners) {
      canvas.drawPath(p, _glow(_green, 14, 10));
      canvas.drawPath(p, _line(_greenBright, 6));
    }

    // Small inner focus brackets.
    final f = inner.deflate(inner.width * 0.13);
    final thin = _line(_greenBright.withValues(alpha: 0.7), 1.4);
    const k = 22.0;
    for (final (o, dx, dy) in [
      (f.topLeft, 1.0, 1.0),
      (f.topRight, -1.0, 1.0),
      (f.bottomRight, -1.0, -1.0),
      (f.bottomLeft, 1.0, -1.0),
    ]) {
      canvas.drawLine(o, o.translate(k * dx, 0), thin);
      canvas.drawLine(o, o.translate(0, k * dy), thin);
    }

    // Slashes under the frame.
    for (var i = 0; i < 4; i++) {
      final x = frame.center.dx - 18 + i * 10;
      canvas.drawLine(
        Offset(x, frame.bottom + 18),
        Offset(x + 6, frame.bottom + 10),
        _line(_green, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.t != t || old.frame != frame;
}

class _ChamferBoxPainter extends CustomPainter {
  const _ChamferBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(1);
    final path = _chamfer(r, 16);
    canvas.drawPath(path, Paint()..color = const Color(0xCC06200A));
    canvas.drawPath(path, _glow(_green.withValues(alpha: 0.6), 4, 5));
    canvas.drawPath(path, _line(_green, 1.4));
    for (var i = 0; i < 4; i++) {
      final x = r.right - 40 + i * 7;
      canvas.drawLine(
        Offset(x, r.bottom - 7),
        Offset(x + 4, r.bottom - 13),
        _line(_green, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ChamferBoxPainter old) => false;
}

class _HexPainter extends CustomPainter {
  const _HexPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(4);
    final s = r.height / 2;
    final hex = Path()
      ..moveTo(r.left + s * 0.6, r.top)
      ..lineTo(r.right - s * 0.6, r.top)
      ..lineTo(r.right, r.center.dy)
      ..lineTo(r.right - s * 0.6, r.bottom)
      ..lineTo(r.left + s * 0.6, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..close();
    canvas.drawPath(
      hex,
      Paint()
        ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [
          const Color(0xFF0A3312),
          const Color(0xFF041506),
        ]),
    );
    canvas.drawPath(
      hex,
      _glow(active ? _greenBright : _green, active ? 8 : 5, active ? 9 : 6),
    );
    canvas.drawPath(hex, _line(_greenBright, 2));

    // Chevrons on either side.
    final chev = _line(_green.withValues(alpha: 0.8), 2);
    final cy = r.center.dy;
    canvas.drawPath(
      Path()
        ..moveTo(-4, cy - 8)
        ..lineTo(-10, cy)
        ..lineTo(-4, cy + 8),
      chev,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width + 4, cy - 8)
        ..lineTo(size.width + 10, cy)
        ..lineTo(size.width + 4, cy + 8),
      chev,
    );
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.active != active;
}
