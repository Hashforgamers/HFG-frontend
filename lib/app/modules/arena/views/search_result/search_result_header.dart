import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultHeader extends StatelessWidget {
  final String? location;
  final VoidCallback onBack;

  const SearchResultHeader({
    super.key,
    required this.location,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Material(
            color: const Color(0x3D767680),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF30D158),
                  size: 19,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find a gaming cafe',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -.5,
                  ),
                ),
                if (location != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFF30D158),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0x99EBEBF5),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
