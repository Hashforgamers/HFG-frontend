import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmering placeholder cards shown while the first cafe list loads.
class CafeSearchSkeleton extends StatelessWidget {
  const CafeSearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: 3,
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1C1C1E),
          highlightColor: const Color(0xFF2C2C2E),
          child: Container(
            decoration: const ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(44)),
              ),
              color: Color(0xFF1C1C1E),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 156, color: const Color(0xFF2C2C2E)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: 170, height: 18),
                      const SizedBox(height: 10),
                      _bar(width: double.infinity, height: 12),
                      const SizedBox(height: 6),
                      _bar(width: 120, height: 12),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final w in [70.0, 84.0, 64.0]) ...[
                            _bar(width: w, height: 26, radius: 13),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _bar(width: double.infinity, height: 44, radius: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    double radius = 6,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
