import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/search_result/search_result_feature_chips.dart';
import 'package:hash/core/utils/haptics.dart';

/// Search result in the Home cafe-card style: photo with frosted status
/// pills, then name, rating, address, distance, features and one action.
class SearchResultCard extends StatelessWidget {
  final String title;
  final String type;
  final String imageUrl;
  final String address;
  final List<String> features;
  final bool isOpen;
  final String distanceLabel;
  final String? etaLabel;
  final double rating;
  final VoidCallback? onViewDetails;

  const SearchResultCard({
    super.key,
    required this.title,
    required this.type,
    required this.imageUrl,
    required this.address,
    required this.features,
    required this.isOpen,
    required this.distanceLabel,
    required this.etaLabel,
    required this.rating,
    required this.onViewDetails,
  });

  static const _green = Color(0xFF30D158);
  static const _red = Color(0xFFFF453A);
  static const _card = Color(0xFF1C1C1E);
  static const _secondary = Color(0x99EBEBF5);
  static const _fill = Color(0x3D767680);

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 16 ? -0.35 : -0.1,
        height: 1.25,
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const imgH = 156.0;
    final distance = etaLabel == null
        ? distanceLabel
        : '$distanceLabel · $etaLabel';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(44)),
        ),
        child: Ink(
          decoration: const ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(44)),
              side: BorderSide(color: Color(0x5900DC00), width: 0.8),
            ),
            color: _card,
          ),
          child: InkWell(
            onTap: isOpen
                ? () {
                    Haptics.selection();
                    onViewDetails?.call();
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imgH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isEmpty
                          ? const ColoredBox(color: Color(0xFF2C2C2E))
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: (width * dpr).round(),
                              placeholder: (_, _) =>
                                  const ColoredBox(color: Color(0xFF2C2C2E)),
                              errorWidget: (_, _, _) => const ColoredBox(
                                color: Color(0xFF2C2C2E),
                                child: Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white38,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ),
                      if (!isOpen) const ColoredBox(color: Color(0x66000000)),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x59000000),
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0x8C1C1C1E),
                            ],
                            stops: [0, 0.35, 0.6, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          children: [
                            _glassPill(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isOpen ? _green : _red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOpen ? 'Open' : 'Closed',
                                    style: _text(
                                      12,
                                      Colors.white,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (type.isNotEmpty)
                              _glassPill(
                                Text(
                                  type,
                                  style: _text(
                                    12,
                                    Colors.white,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _text(
                                18,
                                Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (rating > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
                              decoration: const ShapeDecoration(
                                shape: StadiumBorder(),
                                color: _fill,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFD60A),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: _text(
                                      13,
                                      Colors.white,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _text(13, _secondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: _green,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(13, _green, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (features.isNotEmpty) ...[
                        const SizedBox(height: 11),
                        SearchResultFeatureChips(features: features),
                      ],
                      const SizedBox(height: 13),
                      _action(),
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

  Widget _action() {
    if (!isOpen) {
      return Container(
        height: 44,
        alignment: Alignment.center,
        decoration: const ShapeDecoration(shape: StadiumBorder(), color: _fill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 16, color: _secondary),
            const SizedBox(width: 6),
            Text(
              'Closed right now',
              style: _text(14.5, _secondary, weight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return Material(
      color: _green,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          Haptics.selection();
          onViewDetails?.call();
        },
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              'Book Now',
              style: _text(15.5, Colors.black, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassPill(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
        ),
        child: child,
      ),
    ),
  );
}
