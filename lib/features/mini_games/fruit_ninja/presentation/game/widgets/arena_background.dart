import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Resolution-independent backdrop for Fruit Cut: indigo gradient, a soft
/// spotlight, a faint diamond grid and blurred fruit-coloured bokeh.
///
/// Drawn with vector paint at the device's native resolution (always crisp),
/// then rasterised once to an [Image]: replaying the blurred picture every
/// frame was a big share of the frame cost.
class ArenaBackground extends PositionComponent with HasGameReference {
  ArenaBackground() : super(priority: -100);

  Picture? _picture;
  Image? _image;
  Vector2 _pictureSize = Vector2.zero();
  int _generation = 0;

  static const _bokehColors = [
    Color(0xFFFF5A5F), // watermelon
    Color(0xFFFFC21A), // banana
    Color(0xFF7CF06B), // kiwi
    Color(0xFFFF8A3C), // orange
    Color(0xFFB57BFF), // grape
  ];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    if (size != _pictureSize && size.x > 0 && size.y > 0) {
      _pictureSize = size.clone();
      _rebuild(size.clone());
    }
  }

  Future<void> _rebuild(Vector2 size) async {
    final generation = ++_generation;
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final picture = _paint(size, dpr);
    // Keep drawing the vector version until the raster is ready.
    _picture?.dispose();
    _picture = picture;
    final image = await picture.toImage(
      (size.x * dpr).ceil(),
      (size.y * dpr).ceil(),
    );
    if (generation != _generation || !isMounted) {
      image.dispose();
      return;
    }
    _image?.dispose();
    _image = image;
  }

  @override
  void render(Canvas canvas) {
    final image = _image;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, size.x, size.y),
        _imagePaint,
      );
      return;
    }
    final picture = _picture;
    if (picture != null) {
      canvas.save();
      final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
      canvas.scale(1 / dpr);
      canvas.drawPicture(picture);
      canvas.restore();
    }
  }

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.low;

  @override
  void onRemove() {
    _generation++;
    _picture?.dispose();
    _picture = null;
    _image?.dispose();
    _image = null;
    super.onRemove();
  }

  /// Records the backdrop at physical resolution ([dpr] × logical size).
  Picture _paint(Vector2 size, double dpr) {
    final recorder = PictureRecorder();
    final w = size.x, h = size.y;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w * dpr, h * dpr))
      ..scale(dpr);

    // Base gradient.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, 0),
          Offset(0, h),
          const [Color(0xFF2E1E86), Color(0xFF1A1058), Color(0xFF0B0628)],
          const [0, 0.55, 1],
        ),
    );

    // Spotlight where fruit arcs.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.radial(
          Offset(w / 2, h * 0.38),
          max(w, h) * 0.6,
          const [Color(0x806A4DF0), Color(0x006A4DF0)],
        ),
    );

    // Faint diamond grid.
    final grid = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1;
    const step = 52.0;
    for (double x = -h; x < w + h; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), grid);
      canvas.drawLine(Offset(x + h, 0), Offset(x, h), grid);
    }

    // Bokeh lights (fixed seed so the layout is stable).
    final random = Random(7);
    for (var i = 0; i < 16; i++) {
      final color = _bokehColors[i % _bokehColors.length];
      final r = 18 + random.nextDouble() * 46;
      canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h),
        r,
        Paint()
          ..color = color.withValues(alpha: 0.10 + random.nextDouble() * 0.10)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }

    // Vignette to keep the edges calm under the HUD.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.radial(
          Offset(w / 2, h / 2),
          max(w, h) * 0.75,
          const [Color(0x00000000), Color(0x99000000)],
          const [0.55, 1],
        ),
    );

    return recorder.endRecording();
  }
}
