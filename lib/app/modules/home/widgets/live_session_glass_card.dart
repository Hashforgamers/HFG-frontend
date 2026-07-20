import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/controllers/session_progress_controller.dart';

class LiveSessionGlassCard extends StatefulWidget {
  const LiveSessionGlassCard({
    super.key,
    required this.controller,
    this.margin = const EdgeInsets.symmetric(horizontal: 8),
    this.forceVisible = false,
    this.onChatTap,
    this.onOrderFoodTap,
    this.unreadCount = 0,
  });

  final SessionProgressController controller;
  final EdgeInsets margin;
  final bool forceVisible;
  final VoidCallback? onChatTap;
  final VoidCallback? onOrderFoodTap;
  final int unreadCount;

  @override
  State<LiveSessionGlassCard> createState() => _LiveSessionGlassCardState();
}

class _LiveSessionGlassCardState extends State<LiveSessionGlassCard>
    with SingleTickerProviderStateMixin {
  static const Color _brandGreen = Color(0xFF00DC00);
  late final AnimationController _pulseController;

  ({String start, String end}) _extractTimes(String timeRange) {
    final normalized = timeRange.replaceAll('->', '-');
    final parts = normalized
        .split('-')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return (start: parts.first, end: parts.last);
    }
    return (start: '--:--', end: '--:--');
  }

  String _statusFromProgress(double progress) {
    if (progress >= 0.98) return 'Wrapping up';
    if (progress >= 0.70) return 'Final stretch';
    if (progress >= 0.35) return 'In progress';
    return 'Session active';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.75,
      upperBound: 1.25,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final booking = widget.controller.currentBooking.value;
      final demoMode = widget.forceVisible && booking == null;
      final progress = demoMode ? 0.62 : widget.controller.progress.value;
      final countdown = demoMode
          ? 'Ends in 1h 12m'
          : widget.controller.countdownText.value;
      final timeRange = demoMode
          ? '7:00 PM -> 9:00 PM'
          : widget.controller.timeRangeText.value;
      final arenaName = demoMode ? 'PC Arena - Mira Road' : booking?.arenaName;
      final times = _extractTimes(timeRange);
      final status = _statusFromProgress(progress.clamp(0.0, 1.0));

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: (!widget.forceVisible && booking == null)
            ? const SizedBox.shrink(key: ValueKey('live_session_empty'))
            : Container(
                key: ValueKey(
                  demoMode
                      ? 'live_session_demo'
                      : 'live_session_${booking?.bookingId ?? 'unknown'}',
                ),
                margin: widget.margin,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF050506).withValues(alpha: 0.98),
                            const Color(0xFF0B0C10).withValues(alpha: 0.97),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.42),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -44,
                            right: -42,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _brandGreen.withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -78,
                            left: -52,
                            child: Container(
                              width: 144,
                              height: 144,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFF7D43FF,
                                    ).withValues(alpha: 0.24),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.07,
                                      ),
                                      border: Border.all(
                                        color: _brandGreen.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.sports_esports_rounded,
                                      size: 9,
                                      color: _brandGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      arenaName ?? 'Arena Session',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'LIVE',
                                    style: GoogleFonts.inter(
                                      color: _brandGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'START',
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          times.start,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            height: 0.95,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Session start',
                                          style: GoogleFonts.inter(
                                            color: _brandGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'END',
                                        style: GoogleFonts.inter(
                                          color: Colors.white38,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        times.end,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: _brandGreen,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 0.95,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        countdown,
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.spaceGrotesk(
                                            color: _brandGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                                          style: GoogleFonts.inter(
                                            color: Colors.white60,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        height: 6,
                                        width: double.infinity,
                                        color: Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: AnimatedFractionallySizedBox(
                                            duration: const Duration(
                                              milliseconds: 850,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            widthFactor: progress.clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    _brandGreen,
                                                    _brandGreen,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _brandGreen
                                                        .withValues(
                                                          alpha: 0.45,
                                                        ),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              ScaleTransition(
                                                scale: _pulseController,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: _brandGreen,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  status,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color: _brandGreen,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.onOrderFoodTap != null) ...[
                                          const SizedBox(width: 6),
                                          _ActionBubble(
                                            icon: Icons.fastfood_rounded,
                                            onTap: widget.onOrderFoodTap,
                                          ),
                                        ],
                                        const SizedBox(width: 6),
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            _ActionBubble(
                                              icon: Icons.chat_bubble_rounded,
                                              onTap: widget.onChatTap,
                                              highlighted:
                                                  widget.unreadCount > 0,
                                            ),
                                            if (widget.unreadCount > 0)
                                              Positioned(
                                                right: -3,
                                                top: -3,
                                                child: Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFF496C,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF090909,
                                                      ),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    widget.unreadCount > 9
                                                        ? '9+'
                                                        : '${widget.unreadCount}',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      height: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    });
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({
    required this.icon,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted
                ? const Color(0xFF132A22)
                : Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: highlighted
                  ? _LiveSessionGlassCardState._brandGreen.withValues(
                      alpha: 0.72,
                    )
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: _LiveSessionGlassCardState._brandGreen.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: highlighted
                ? _LiveSessionGlassCardState._brandGreen
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
