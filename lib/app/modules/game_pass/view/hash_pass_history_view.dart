import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/cubit/get_game_pass_cubit.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:intl/intl.dart';

enum HistoryPassCardType { rightImage, leftImage }

class HashPassHistoryView extends StatefulWidget {
  final TabController tabController;
  const HashPassHistoryView({super.key, required this.tabController});

  @override
  State<HashPassHistoryView> createState() => _HashPassHistoryViewState();
}

class _HashPassHistoryViewState extends State<HashPassHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetGamePassCubit>().getGamePassHistory();
    });
  }

  /// Group passes by "YYYY-MM" and return keys sorted desc (latest first)
  Map<String, List<GetPassModel>> _groupByMonth(List<GetPassModel> passes) {
    final map = <String, List<GetPassModel>>{};
    for (final p in passes) {
      final ts = p.timestamp;
      final key =
          '${ts.year.toString().padLeft(4, '0')}-${ts.month.toString().padLeft(2, '0')}';
      (map[key] ??= <GetPassModel>[]).add(p);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // desc
    return {for (final k in sortedKeys) k: map[k]!};
  }

  String _formatMonthLabel(String key) {
    final now = DateTime.now();
    final thisKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    if (key == thisKey) return 'This Month';
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateFormat('MMMM yyyy').format(DateTime(year, month));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetGamePassCubit, GetGamePassState>(
      builder: (context, state) {
        if (state is GetGamePassLoading) {
          return const _LoadingSkeleton();
        }

        if (state is GetGamePassError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<GetGamePassCubit>().getGamePassHistory(),
          );
        }

        if (state is GetGamePassLoaded) {
          final passes = state.gamePass;
          if (passes.isEmpty) return const _EmptyView();

          final grouped = _groupByMonth(passes);

          // Flatten into headers and items in display order
          final items = <_RowItem>[];
          grouped.forEach((monthKey, list) {
            items.add(_RowItem.header(monthKey));
            // Optional: sort each month by timestamp desc
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            for (final p in list) {
              items.add(_RowItem.item(p));
            }
          });

          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final row = items[index];
              if (row.isHeader) {
                return Text(
                  _formatMonthLabel(row.headerKey!),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }
              return _HistoryPassCard(pass: row.pass!);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Row model for list building
class _RowItem {
  final bool isHeader;
  final String? headerKey;
  final GetPassModel? pass;
  _RowItem.header(this.headerKey) : isHeader = true, pass = null;
  _RowItem.item(this.pass) : isHeader = false, headerKey = null;
}

/// Card
class _HistoryPassCard extends StatelessWidget {
  const _HistoryPassCard({required this.pass});
  final GetPassModel pass;

  @override
  Widget build(BuildContext context) {
    final cardType = pass.id.hashCode.isEven
        ? HistoryPassCardType.rightImage
        : HistoryPassCardType.leftImage;

    final statusColor = Color(pass.statusColor);
    final progress = pass.progressValue.clamp(0.0, 1.0);
    final alignEnd = cardType == HistoryPassCardType.rightImage;

    final borderRadius = BorderRadius.circular(24);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: statusColor, width: 1),
    );
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final main = alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pass.name} · ${pass.vendorName}'),
            duration: const Duration(seconds: 2),
          ),
        ),
        child: SizedBox(
          height: 196,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              _smartImage(
                urlOrAsset: (pass.vendorImages?.isNotEmpty == true)
                    ? pass.vendorImages!.first.url
                    : 'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075178/globalpass1_o2shqg.png',
                fit: BoxFit.cover,
                placeholder: const RainbowGlowingLoader(size: 28),
              ),

              // Subtle blur + gradient overlay
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: alignEnd
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.58),
                        Colors.black.withOpacity(0.28),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: cross,
                  children: [
                    Row(
                      mainAxisAlignment: main,
                      children: [
                        _smartImage(
                          urlOrAsset:
                              'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png',
                          height: 22,
                          width: 22,
                          placeholder: const RainbowGlowingLoader(size: 18),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            pass.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pass.infoText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusChip(
                          status: _deriveStatus(pass, progress),
                          color: statusColor,
                        ),
                        Text(
                          pass.expiryText,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deriveStatus(GetPassModel pass, double progress) {
    // More explicit than comparing month/year only

    final now = DateTime.now();
    final expiry = pass.expiryDate is DateTime
        ? pass.expiryDate as DateTime
        : now;
    if (progress >= 1.0) return 'Completed';
    if (expiry.isBefore(now)) return 'Expired';
    if (progress <= 0.0) return 'Not Started';
    return 'Active';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// States ————————————————————————————————————————

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: EdgeInsets.only(top: i == 0 ? 0 : 16),
          height: 196,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(child: RainbowGlowingLoader(size: 36)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            'No Game Pass History',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You haven’t purchased any game passes yet.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Image helper ———————————————————————————————————

Widget _smartImage({
  required String urlOrAsset,
  double? height,
  double? width,
  BoxFit? fit,
  Widget? placeholder,
}) {
  final isAsset = urlOrAsset.startsWith('assets/');
  if (isAsset) {
    return Image.asset(
      urlOrAsset,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade800,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.white54,
          size: 24,
        ),
      ),
    );
  }
  return CachedNetworkImage(
    imageUrl: urlOrAsset,
    height: height,
    width: width,
    fit: fit ?? BoxFit.cover,
    filterQuality: FilterQuality.high,
    placeholder: (_, __) =>
        Center(child: placeholder ?? const RainbowGlowingLoader(size: 24)),
    errorWidget: (_, __, ___) => Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.white54,
        size: 24,
      ),
    ),
  );
}
