import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/utils/haptics.dart';

/// Apple-style "nothing found" card. Copy adapts to the active search/filter;
/// offers to clear them, and to suggest a cafe we don't list yet.
class CafeSearchEmptyState extends StatelessWidget {
  const CafeSearchEmptyState({
    super.key,
    this.query = '',
    this.filter = 'All',
    this.onClear,
    this.onInvite,
  });

  final String query;
  final String filter;
  final VoidCallback? onClear;
  final VoidCallback? onInvite;

  static const _green = Color(0xFF30D158);
  static const _card = Color(0xFF1C1C1E);
  static const _secondary = Color(0x99EBEBF5);
  static const _fill = Color(0x3D767680);

  bool get _narrowed => query.trim().isNotEmpty || filter != 'All';

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 17 ? -0.4 : -0.1,
        height: 1.3,
      );

  String get _title {
    final q = query.trim();
    if (q.isNotEmpty) return 'No results for “$q”';
    return switch (filter) {
      'Open Now' => 'Nothing open right now',
      'Nearby' => 'No cafes near you yet',
      'All' => 'No cafes here yet',
      _ => 'No $filter spots found',
    };
  }

  String get _subtitle => _narrowed
      ? 'Try another name, area or city, or clear your filters.'
      : 'HASH is growing city by city. Know a great spot? '
            'Suggest it and we’ll bring it on board.';

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh still works when the list is empty.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                decoration: const ShapeDecoration(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(48)),
                    side: BorderSide(color: Color(0x5900DC00), width: 0.8),
                  ),
                  color: _card,
                  shadows: [
                    BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: ShapeDecoration(
                        shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF5CE07A), Color(0xFF1E9E3E)],
                        ),
                        shadows: [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.35),
                            blurRadius: 22,
                            spreadRadius: -6,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _narrowed
                            ? Icons.search_off_rounded
                            : Icons.storefront_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(21, Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: _text(14.5, _secondary),
                    ),
                    const SizedBox(height: 22),
                    if (_narrowed && onClear != null) ...[
                      _capsule(
                        label: 'Clear search & filters',
                        icon: Icons.filter_alt_off_rounded,
                        background: _green,
                        foreground: Colors.black,
                        onTap: onClear!,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (onInvite != null)
                      _capsule(
                        label: 'Suggest a cafe',
                        icon: Icons.add_business_rounded,
                        background: _narrowed ? _fill : _green,
                        foreground: _narrowed ? Colors.white : Colors.black,
                        onTap: onInvite!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _capsule({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: _text(15.5, foreground, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
