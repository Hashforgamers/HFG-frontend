import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Page hierarchy shared by the shop, without changing its navigation chrome.
class StorePageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const StorePageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFB38CFF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFFAAAAAF),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

@Preview(name: 'Shop heading · mobile', size: Size(390, 210))
Widget shopHeadingPreview() => const Material(
  color: Color(0xFF050506),
  child: StorePageIntro(
    eyebrow: 'Hash Shop',
    title: 'Upgrade your game.',
    subtitle: 'Explore gear and gaming sessions from Hash partners.',
  ),
);
