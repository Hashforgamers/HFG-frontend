import 'package:animated_emoji/animated_emoji.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/haptics.dart';

/// A single gamified reaction: a stable [key] persisted over the wire, the
/// animated [emoji] we render, and a plain-unicode [fallback] for logging or
/// older clients.
class LudoReactionOption {
  const LudoReactionOption(this.key, this.emoji, this.fallback);

  final String key;
  final AnimatedEmojiData emoji;
  final String fallback;
}

/// The Ludo reaction palette — Google's animated (Noto) emojis via
/// `animated_emoji`, curated for a gaming table vibe.
const List<LudoReactionOption> kLudoReactions = [
  LudoReactionOption('fire', AnimatedEmojis.fire, '🔥'),
  LudoReactionOption('joy', AnimatedEmojis.joy, '😂'),
  LudoReactionOption('rofl', AnimatedEmojis.rofl, '🤣'),
  LudoReactionOption('cool', AnimatedEmojis.sunglassesFace, '😎'),
  LudoReactionOption('party', AnimatedEmojis.partyingFace, '🥳'),
  LudoReactionOption('hundred', AnimatedEmojis.oneHundred, '💯'),
  LudoReactionOption('trophy', AnimatedEmojis.trophy, '🏆'),
  LudoReactionOption('scream', AnimatedEmojis.screaming, '😱'),
  LudoReactionOption('rage', AnimatedEmojis.rage, '😡'),
  LudoReactionOption('bomb', AnimatedEmojis.bomb, '💣'),
  LudoReactionOption('thumbsup', AnimatedEmojis.thumbsUp, '👍'),
];

/// Resolve a reaction from its stored key, tolerating a raw unicode fallback.
LudoReactionOption? ludoReactionByKey(String key) {
  for (final r in kLudoReactions) {
    if (r.key == key) return r;
  }
  for (final r in kLudoReactions) {
    if (r.fallback == key) return r;
  }
  return null;
}

/// One reaction to float on screen. [id] must change per emission so the layer
/// knows to replay even when the same emoji is sent twice in a row.
class LudoReactionEvent {
  const LudoReactionEvent({
    required this.option,
    required this.id,
    this.label = '',
  });

  final LudoReactionOption option;
  final int id;
  final String label;
}

/// The horizontal quick-tap strip of animated reactions.
class LudoReactionBar extends StatelessWidget {
  const LudoReactionBar({
    super.key,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final ValueChanged<LudoReactionOption> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: kLudoReactions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = kLudoReactions[i];
          return GestureDetector(
            onTap: () {
              Haptics.selection();
              onSelected(option);
            },
            // Chunky socket to match the game panels.
            child: Container(
              width: 48,
              height: 50,
              padding: const EdgeInsets.fromLTRB(2.5, 2.5, 2.5, 5),
              decoration: BoxDecoration(
                color: GameColors.outline,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11.5),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [GameColors.bodyTop, GameColors.bodyBottom],
                  ),
                ),
                child: AnimatedEmoji(option.emoji, size: 28, repeat: false),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A full-screen, tap-through layer that pops the most recent reaction: it
/// scales in, drifts upward and fades out. Drive it by pushing
/// [LudoReactionEvent]s into [listenable].
class LudoReactionLayer extends StatefulWidget {
  const LudoReactionLayer({super.key, required this.listenable});

  final ValueListenable<LudoReactionEvent?> listenable;

  @override
  State<LudoReactionLayer> createState() => _LudoReactionLayerState();
}

class _LudoReactionLayerState extends State<LudoReactionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  LudoReactionEvent? _current;
  int _shownId = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    widget.listenable.addListener(_onEvent);
  }

  void _onEvent() {
    final event = widget.listenable.value;
    if (event == null || event.id == _shownId) return;
    _shownId = event.id;
    setState(() => _current = event);
    _ctrl.forward(from: 0).whenComplete(() {
      if (mounted && _current?.id == event.id) {
        setState(() => _current = null);
      }
    });
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onEvent);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = _current;
    if (event == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            final scale = (t < 0.2 ? t / 0.2 : 1.0).clamp(0.0, 1.0) * 1.1;
            final opacity = (t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25)).clamp(
              0.0,
              1.0,
            );
            final dy = -160.0 * Curves.easeOut.transform(t);
            return Align(
              alignment: const Alignment(0, 0.32),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedEmoji(event.option.emoji, size: 84),
                        if (event.label.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              event.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
