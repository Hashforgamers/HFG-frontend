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
    // Load history data when the view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetGamePassCubit>().getGamePassHistory();
    });
  }

  Map<String, List<GetPassModel>> getGroupedHistory(List<GetPassModel> passes) {
    Map<String, List<GetPassModel>> grouped = {};

    for (var pass in passes) {
      DateTime timestamp = pass.timestamp;
      String monthYear =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(pass);
    }

    return grouped;
  }

  String _formatMonthYear(String monthYear) {
    final now = DateTime.now();
    final currentMonthKey =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}";

    if (monthYear == currentMonthKey) {
      return "This Month";
    }

    final parts = monthYear.split("-");
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final date = DateTime(year, month);
    final formatter = DateFormat('MMMM yyyy');
    return formatter.format(date); // e.g., "July 2025"
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetGamePassCubit, GetGamePassState>(
      builder: (context, state) {
        if (state is GetGamePassLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is GetGamePassError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<GetGamePassCubit>().getGamePassHistory();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is GetGamePassLoaded) {
          final passes = state.gamePass;
          if (passes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Game Pass History',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t purchased any game passes yet.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groupedHistory = getGroupedHistory(passes);
          final flattenedList = <dynamic>[];

          groupedHistory.forEach((monthYear, items) {
            flattenedList.add({'isHeader': true, 'month': monthYear});
            flattenedList.addAll(
              items.map((item) => {'isHeader': false, 'data': item}),
            );
          });

          return ListView.separated(
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: flattenedList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = flattenedList[index];
              if (item['isHeader']) {
                final month = item['month'];
                final displayMonth = _formatMonthYear(month);
                return Text(
                  displayMonth,
                  style: GoogleFonts.inter(
                    color: Color(0xFF505050),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return _buildHistoryPassCard(context, item['data']);
              }
            },
          );
        }

        return const Center(
          child: Text('No data available'),
        );
      },
    );
  }

  Widget _buildHistoryPassCard(
    BuildContext context,
    GetPassModel pass,
  ) {
    final cardType = pass.id.hashCode % 2 == 0 
        ? HistoryPassCardType.rightImage 
        : HistoryPassCardType.leftImage;

    return GestureDetector(
      onTap: () {
        // Handle tap on pass card
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pass.name} - ${pass.vendorName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: Color(pass.statusColor), width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                pass.displayImage,
                height: 190,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 190,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.games,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment:
                    cardType == HistoryPassCardType.rightImage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/crown_mzzqhy.png',
                    height: 26,
                    width: 26,
                    placeholder: (_, _) =>
                        const Center(child: RainbowGlowingLoader(size: 20)),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pass.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pass.infoText,
                    style: GoogleFonts.inter(
                      color: Color(pass.statusColor),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 400,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: pass.progressValue,
                        minHeight: 4,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(pass.statusColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (() {
                        final now = DateTime.now();
                        final passDate = pass.timestamp;
                        bool isActive = (now.year == passDate.year) &&
                            (now.month == passDate.month) &&
                            pass.progressValue > 0.0 &&
                            pass.progressValue < 1.0;
                        return isActive
                            ? Text(
                                'Active',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              )
                            : SizedBox.shrink();
                      })(),
                      Text(
                        pass.expiryText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
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
    );
  }
}
