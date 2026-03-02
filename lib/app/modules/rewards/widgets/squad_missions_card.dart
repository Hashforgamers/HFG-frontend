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
  late final Animation<double> _pulseOpacity;

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
    _pulseOpacity = Tween<double>(begin: 0.32, end: 0.62).animate(
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
      stream: _service.watchCurrentWeekProgress(),
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF8A3C).withValues(alpha: 0.62),
                const Color(0xFFFF6A22).withValues(alpha: 0.52),
                const Color(0xFFE64A12).withValues(alpha: 0.46),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x66A82D00).withValues(alpha: 0.42),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Positioned(
              //   top: -28,
              //   left: 0,
              //   right: 0,
              //   child: Center(
              //     child: Container(
              //       width: 136,
              //       height: 82,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: const Color(0xFFFFF8D3).withValues(alpha: 0.1),
              //         boxShadow: [
              //           BoxShadow(
              //             color: const Color(0xFFFFF3BF).withValues(alpha: 0.8),
              //             blurRadius: 28,
              //             spreadRadius: 8,
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, child) {
                          return Transform.scale(
                            scale: _pulseScale.value,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFFFF8D2,
                                      ).withValues(alpha: _pulseOpacity.value),
                                      const Color(
                                        0xFFFFF8D2,
                                      ).withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.2, 1],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white.withValues(alpha: 0.98),
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${data.currentStreak} Days Streak',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    encouragement,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66A63A12), Color(0x8CC24116)],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(dayLabels.length, (index) {
                        final label = dayLabels[index];
                        final isToday = index == todayIndex;
                        final distance = (todayIndex - index);
                        final isChecked =
                            distance > 0 && distance <= checkedCount;
                        return _dayNode(
                          label: label,
                          checked: isChecked,
                          fire: isToday && data.currentStreak > 0,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showMissionsSheet(context, data.missions),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                          bottomLeft: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'See Details',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dayNode({
    required String label,
    required bool checked,
    required bool fire,
  }) {
    return Container(
      width: 36,
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: checked
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFFFB06A).withValues(alpha: 0.82),
                        const Color(0xFFFF7A33).withValues(alpha: 0.76),
                      ],
                    )
                  : null,
              border: checked
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.9,
                    ),
              boxShadow: [
                if (checked)
                  BoxShadow(
                    color: const Color(0xFFFFB97C).withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: 3.2,
                  )
                else
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06),
                    blurRadius: 14,
                    spreadRadius: 2.4,
                  ),
              ],
            ),
            child: checked
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : fire
                ? const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF8A00),
                    size: 15,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
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
