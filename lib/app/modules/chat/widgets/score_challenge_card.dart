import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// What a `score_challenge` chat message says. Pure, so it can be tested.
({String title, String body, String action}) scoreChallengeCopy({
  required String challenger,
  required String gameName,
  required int score,
  required bool isMine,
}) {
  final who = challenger.trim().isEmpty ? 'A player' : challenger.trim();
  return (
    title: isMine ? 'You threw down a challenge' : '$who challenges you',
    body: 'Beat $score in $gameName',
    action: isMine ? 'Play again' : 'Beat it',
  );
}

/// A "beat my score" challenge posted in a leaderboard chat. Tapping the
/// button opens the game.
class ScoreChallengeCard extends StatelessWidget {
  const ScoreChallengeCard({
    required this.challenger,
    required this.gameName,
    required this.score,
    required this.isMine,
    required this.onPlay,
    this.icon,
    super.key,
  });

  final String challenger;
  final String gameName;
  final int score;
  final bool isMine;

  /// Null when the game is no longer in the arcade (old message).
  final VoidCallback? onPlay;

  /// Asset path of the game's icon, if known.
  final String? icon;

  static const _gold = Color(0xFFF4C342);

  @override
  Widget build(BuildContext context) {
    final copy = scoreChallengeCopy(
      challenger: challenger,
      gameName: gameName,
      score: score,
      isMine: isMine,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A210A), Color(0xFF14110A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: icon == null
                    ? _fallbackIcon()
                    : Image.asset(
                        icon!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackIcon(),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCORE CHALLENGE',
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      copy.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      copy.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD9D2BD),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onPlay != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                onPressed: onPlay,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF231A00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  copy.action,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
    width: 48,
    height: 48,
    color: const Color(0xFF3A2E0C),
    child: const Icon(Icons.emoji_events_rounded, color: _gold),
  );
}
