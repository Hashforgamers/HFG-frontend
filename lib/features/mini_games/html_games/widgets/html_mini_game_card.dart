import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';

class HtmlMiniGameCard extends StatelessWidget {
  const HtmlMiniGameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.bestScore,
    this.compact = false,
  });

  final HtmlMiniGame game;
  final VoidCallback onTap;
  final int? bestScore;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForGame(game.gameId);
    if (compact) {
      return _CompactHtmlMiniGameCard(
        game: game,
        palette: palette,
        bestScore: bestScore,
        onTap: onTap,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                palette.shadow.withValues(alpha: 0.24),
                const Color(0xFF121212),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _GameThumbnail(
                      game: game,
                      palette: palette,
                      compact: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    game.isRemoteUrl ? 'URL Game' : 'Local Game',
                    style: GoogleFonts.inter(
                      color: palette.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  game.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  game.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bestScore == null
                            ? 'Tap to play'
                            : 'Best score: $bestScore',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.accent.withValues(alpha: 0.18),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactHtmlMiniGameCard extends StatelessWidget {
  const _CompactHtmlMiniGameCard({
    required this.game,
    required this.palette,
    required this.bestScore,
    required this.onTap,
  });

  final HtmlMiniGame game;
  final _GamePalette palette;
  final int? bestScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 92,
          height: 130,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = constraints.maxWidth - 8;
              return Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow.withValues(alpha: 0.34),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _GameThumbnail(
                          game: game,
                          palette: palette,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          game.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bestScore == null ? 'HTML5 Game' : 'Best: $bestScore',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.accent.withValues(alpha: 0.92),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameThumbnail extends StatelessWidget {
  const _GameThumbnail({
    required this.game,
    required this.palette,
    required this.compact,
  });

  final HtmlMiniGame game;
  final _GamePalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (game.hasThumbnail && game.isRemoteThumbnail) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: game.thumbnail,
            fit: BoxFit.cover,
            placeholder: (context, url) => _fallbackThumb(),
            errorWidget: (context, url, error) => _fallbackThumb(),
          ),
          Positioned(
            top: compact ? 8 : 10,
            left: compact ? 8 : 10,
            child: _htmlBadge(compact),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: compact ? 0.32 : 0.48),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _fallbackThumb();
  }

  Widget _fallbackThumb() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: compact ? 8 : -12,
            right: compact ? 8 : -8,
            child: Icon(
              Icons.language_rounded,
              size: compact ? 42 : 58,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _htmlBadge(compact),
                  const Spacer(),
                  Text(
                    _initials(game.name),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: compact ? 22 : 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _htmlBadge(bool compact) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 6 : 8,
      vertical: compact ? 3 : 4,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'HTML5',
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: compact ? 8 : 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _GamePalette {
  const _GamePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.shadow,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color shadow;
}

_GamePalette _paletteForGame(String gameId) {
  switch (gameId) {
    case 'racing_limits':
      return const _GamePalette(
        primary: Color(0xFF234E96),
        secondary: Color(0xFF0D1630),
        accent: Color(0xFF9BC4FF),
        shadow: Color(0xFF163767),
      );
    case 'tap_blitz':
      return const _GamePalette(
        primary: Color(0xFF167B74),
        secondary: Color(0xFF0F2A2C),
        accent: Color(0xFF7EF1D0),
        shadow: Color(0xFF0C5F58),
      );
    case 'orbit_smash':
      return const _GamePalette(
        primary: Color(0xFFB15B1E),
        secondary: Color(0xFF2B140B),
        accent: Color(0xFFFFC57B),
        shadow: Color(0xFF6D320B),
      );
    case 'reactor_rush':
      return const _GamePalette(
        primary: Color(0xFF2856A6),
        secondary: Color(0xFF131D3B),
        accent: Color(0xFF8BB9FF),
        shadow: Color(0xFF183A73),
      );
    default:
      return const _GamePalette(
        primary: Color(0xFF5A4CD6),
        secondary: Color(0xFF18142B),
        accent: Color(0xFFC6BEFF),
        shadow: Color(0xFF2C2378),
      );
  }
}

String _initials(String name) {
  final parts = name
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part.trim())
      .toList();
  if (parts.isEmpty) return 'HG';
  if (parts.length == 1) {
    final word = parts.first;
    final length = word.length >= 2 ? 2 : 1;
    return word.substring(0, length).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
