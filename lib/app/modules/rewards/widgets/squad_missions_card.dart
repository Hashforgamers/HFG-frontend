import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/rewards/models/squad_weekly_progress.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';

class SquadMissionsCard extends StatefulWidget {
  const SquadMissionsCard({super.key});

  @override
  State<SquadMissionsCard> createState() => _SquadMissionsCardState();
}

class _SquadMissionsCardState extends State<SquadMissionsCard>
    with SingleTickerProviderStateMixin {
  final SquadMissionsService _service = locator<SquadMissionsService>();
  final Set<String> _claiming = <String>{};
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  // Created once: calling watchCurrentWeekProgress() in build opened a new
  // Firestore listener on every rebuild.
  late final Stream<SquadWeeklyProgress?> _progress = _service
      .watchCurrentWeekProgress();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _service.ensureAndFetchCurrentWeek();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _claim(String missionKey) async {
    if (_claiming.contains(missionKey)) return;
    setState(() => _claiming.add(missionKey));
    final ok = await _service.claimMission(missionKey);
    if (!mounted) return;
    setState(() => _claiming.remove(missionKey));
    Get.snackbar(
      ok ? 'Mission Claimed' : 'Cannot Claim Yet',
      ok
          ? 'Reward claimed successfully.'
          : 'Complete this mission target before claiming.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ok ? const Color(0xFF0F5D26) : const Color(0xFF6A1212),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SquadWeeklyProgress?>(
      stream: _progress,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            data == null) {
          return const SizedBox.shrink();
        }
        if (data == null) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final todayIndex = now.weekday - 1;
        final dayLabels = const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ];
        final checkedCount = data.currentStreak <= 0
            ? 0
            : data.currentStreak - 1;
        final encouragement = data.currentStreak >= 5
            ? "You're unstoppable, keep the fire alive!"
            : "You're doing really great, stay on fire!";

        final done = data.missions
            .where((m) => m.claimed || m.progress >= m.target)
            .length;
        final total = data.missions.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(48)),
                side: BorderSide(color: Color(0x5900DC00), width: 0.8),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF242427), Color(0xFF161618)],
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: -110,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x2600DC00), Color(0x0000DC00)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -90,
                  left: -60,
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _Sys.orange.withValues(alpha: 0.2),
                            _Sys.orange.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'WEEKLY STREAK',
                            style: _text(
                              12,
                              _Sys.secondary,
                              weight: FontWeight.w600,
                            ).copyWith(letterSpacing: 0.6),
                          ),
                          const Spacer(),
                          Text(
                            'Best ${data.bestStreak}',
                            style: _text(
                              13,
                              _Sys.secondary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, child) => Transform.scale(
                              scale: _pulseScale.value,
                              child: child,
                            ),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: ShapeDecoration(
                                shape: const ContinuousRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(26),
                                  ),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _Sys.orange.withValues(alpha: 0.4),
                                    _Sys.orange.withValues(alpha: 0.14),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: _Sys.orange,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${data.currentStreak}',
                                      style: _text(
                                        30,
                                        Colors.white,
                                        weight: FontWeight.w800,
                                      ).copyWith(height: 1),
                                    ),
                                    const SizedBox(width: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        data.currentStreak == 1
                                            ? 'Day Streak'
                                            : 'Days Streak',
                                        style: _text(
                                          17,
                                          Colors.white,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  encouragement,
                                  style: _text(14, _Sys.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(dayLabels.length, (index) {
                          final distance = todayIndex - index;
                          return _dayNode(
                            label: dayLabels[index],
                            checked: distance > 0 && distance <= checkedCount,
                            fire: index == todayIndex && data.currentStreak > 0,
                            today: index == todayIndex,
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 0.5, color: _Sys.separator),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showMissionsSheet(context, data.missions),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flag_rounded,
                                size: 18,
                                color: _Sys.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Weekly missions',
                                style: _text(
                                  15,
                                  Colors.white,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$done of $total',
                                style: _text(15, _Sys.secondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'See Details',
                                style: _text(
                                  15,
                                  _Sys.orange,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: _Sys.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 20 ? -0.5 : (size >= 15 ? -0.3 : -0.1),
        height: 1.25,
      );

  /// Apple Fitness–style day ring.
  Widget _dayNode({
    required String label,
    required bool checked,
    required bool fire,
    required bool today,
  }) {
    final lit = checked || fire;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit ? _Sys.orange : _Sys.fill,
            border: today && !lit
                ? Border.all(color: _Sys.orange, width: 1.5)
                : null,
            boxShadow: lit
                ? [
                    BoxShadow(
                      color: _Sys.orange.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: lit
              ? Icon(
                  fire
                      ? Icons.local_fire_department_rounded
                      : Icons.check_rounded,
                  color: Colors.black,
                  size: 18,
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label.substring(0, 1),
          style: _text(
            12,
            today ? _Sys.orange : _Sys.secondary,
            weight: today ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _showMissionsSheet(
    BuildContext context,
    List<SquadMissionProgress> missions,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2B1308),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            child: SizedBox(
              height: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Weekly Missions',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: missions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final mission = missions[index];
                        return SizedBox(
                          width: 248,
                          child: _missionTile(mission, compact: true),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _missionTile(SquadMissionProgress mission, {bool compact = false}) {
    final canClaim = mission.isCompleted && !mission.claimed;
    final isClaiming = _claiming.contains(mission.key);
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${mission.progress}/${mission.target}',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFCFAB),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: mission.ratio,
              backgroundColor: const Color(0x66A35A34),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF8A3D),
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: [
              Text(
                'Reward: ${mission.reward} HC',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFE0C4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (mission.claimed)
                _statusPill(
                  'Claimed',
                  const Color(0xFF0F5D26),
                  Colors.greenAccent,
                )
              else if (canClaim)
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: isClaiming ? null : () => _claim(mission.key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE55A11),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: isClaiming
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            'Claim',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                )
              else
                _statusPill('In Progress', Colors.white12, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// iOS dark-mode system colours used by the card.
class _Sys {
  static const orange = Color(0xFFFF9F0A);
  static const secondary = Color(0x99EBEBF5);
  static const fill = Color(0x29787880);
  static const separator = Color(0x33FFFFFF);
}
