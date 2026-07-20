import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/loader.dart';

class TournamentFinalizingRegistrationDialog extends StatelessWidget {
  const TournamentFinalizingRegistrationDialog({
    super.key,
    required this.tournamentTitle,
  });

  final String tournamentTitle;

  @override
  Widget build(BuildContext context) {
    final title = tournamentTitle.trim();
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1B1B), Color(0xFF0D0D0D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00DC00).withValues(alpha: .10),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF171717),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Securing your spot',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00DC00),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Please keep the app open while we confirm your registration.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                const AppLinearLoader.button(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(
  name: 'Finalizing tournament registration',
  group: 'Tournaments',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget tournamentFinalizingRegistrationPreview() {
  return const ColoredBox(
    color: Colors.black,
    child: TournamentFinalizingRegistrationDialog(
      tournamentTitle: 'Hash Weekend Championship',
    ),
  );
}
