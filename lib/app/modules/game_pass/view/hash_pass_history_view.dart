import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/view/game_pass_view.dart';
import 'package:hash/app/modules/game_pass/widgets/game_pass_tab_bar.dart';
import 'package:intl/intl.dart';

enum HistoryPassCardType { rightImage, leftImage }

class HashPassHistoryView extends StatefulWidget {
  const HashPassHistoryView({super.key});

  @override
  State<HashPassHistoryView> createState() => _HashPassHistoryViewState();
}

class _HashPassHistoryViewState extends State<HashPassHistoryView> {
  final List<Map<String, dynamic>> historyList = [
    {
      'image': 'assets/images/globalpass2.png',
      'title': 'Monthly Hash Pass',
      'info': '30 Days @ Rs.1500',
      'progress': 0.6,
      'subtitle': 'Expires 5/08/25',
      'color': Color(0xFF6DFB60),
      'type': HistoryPassCardType.rightImage,
      'timestamp': DateTime(2025, 8, 5),
    },
    {
      'image': 'assets/images/historypass1.png',
      'title': 'Dragon Cafe Hash Pass',
      'info': '24 Hours @ Rs.500',
      'progress': 0.4,
      'subtitle': 'Expires 5/08/25',
      'color': Color(0xFF6DFB60),
      'type': HistoryPassCardType.leftImage,
      'timestamp': DateTime(2025, 8, 5),
    },
    {
      'image': 'assets/images/historypass2.png',
      'title': 'Retro Gaming Studio Pass',
      'info': '24 Hours @ Rs.500',
      'progress': 1.0,
      'subtitle': 'Expired on 27/07/25',
      'color': Color(0xFFFBA544),
      'type': HistoryPassCardType.leftImage,
      'timestamp': DateTime(2025, 7, 27),
    },
    {
      'image': 'assets/images/historypass1.png',
      'title': 'Dragon Cafe Hash Pass',
      'info': '24 Hours @ Rs.500',
      'progress': 1.0,
      'subtitle': 'Expired on 27/07/25',
      'color': Color(0xFF6DFB60),
      'type': HistoryPassCardType.leftImage,
      'timestamp': DateTime(2025, 7, 27),
    },
    {
      'image': 'assets/images/globalpass1.png',
      'title': 'Daily Hash Pass',
      'info': '24 Hours @ Rs.500',
      'progress': 1.0,
      'subtitle': 'Expired on 27/07/25',
      'color': Color(0xFFE6D009),
      'type': HistoryPassCardType.leftImage,
      'timestamp': DateTime(2025, 7, 27),
    },
    {
      'image': 'assets/images/historypass1.png',
      'title': 'Dragon Cafe Hash Pass',
      'info': '24 Hours @ Rs.500',
      'progress': 0.0,
      'subtitle': 'Expired on 27/07/25',
      'color': Color(0xFF6DFB60),
      'type': HistoryPassCardType.leftImage,
      'timestamp': DateTime(2025, 7, 27),
    },
  ];

  Map<String, List<Map<String, dynamic>>> getGroupedHistory() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in historyList) {
      DateTime timestamp = item['timestamp'];
      String monthYear =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(item);
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
    final groupedHistory = getGroupedHistory();
    final flattenedList = <Map<String, dynamic>>[];

    groupedHistory.forEach((monthYear, items) {
      flattenedList.add({'isHeader': true, 'month': monthYear});
      flattenedList.addAll(
        items.map((item) => {'isHeader': false, 'data': item}),
      );
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GamePassTabBar(currentPage: 'history'),
                  ListView.separated(
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: historyList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final item = flattenedList[index];
                      if (item['isHeader']) {
                        final month = item['month'];
                        final displayMonth = _formatMonthYear(
                          month,
                        ); // e.g., "August 2025"
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            displayMonth,
                            style: GoogleFonts.inter(
                              color: Color(0xFF505050),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        return _buildHistoryPassCard(context, item['data']);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      pinned: false,
      leading: GestureDetector(
        onTap: () {
          Get.to(GamePassView());
        },
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        'Hash Pass History',
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
      ),
    );
  }

  GestureDetector _buildHistoryPassCard(
    BuildContext context,
    Map<String, dynamic> history,
  ) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 190,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: history['color'], width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                history['image'],
                height: 190,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 40,
              right: 40,
              child: Column(
                crossAxisAlignment:
                    history['type'] == HistoryPassCardType.rightImage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/icons/crown.png', height: 26, width: 26),
                  const SizedBox(height: 4),
                  Text(
                    history['title'],
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    history['info'],
                    style: GoogleFonts.inter(
                      color: history['color'],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: history['progress'],
                        minHeight: 4,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          history['color'],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (() {
                        DateTime now = DateTime.now();
                        bool isActive =
                            (now.year == history['timestamp'].year) &&
                            (now.month == history['timestamp'].month);
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
                        history['subtitle'],
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
