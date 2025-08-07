import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/view/cafe_specific_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/global_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/hash_pass_history_view.dart';

class GamePassView extends StatefulWidget {
  const GamePassView({super.key});

  @override
  State<GamePassView> createState() => _GamePassViewState();
}

class _GamePassViewState extends State<GamePassView>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final ValueNotifier<int> tabIndexNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (tabController.indexIsChanging == false) {
        tabIndexNotifier.value = tabController.index;
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [_buildAppBar()],
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TabBarView(
            controller: tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GlobalPassView(tabController: tabController),
              CafeSpecificPassView(tabController: tabController),
              HashPassHistoryView(tabController: tabController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: false,
      elevation: 0,
      toolbarHeight: 70,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xff00D701)),
        onPressed: () {
          Get.back();
        },
      ),
      title: AnimatedBuilder(
        animation: tabController,
        builder: (_, __) {
          return Text(
            tabController.index == 0
                ? 'Global Pass'
                : tabController.index == 1
                ? 'Cafe-Specific Pass'
                : 'Hash Pass History',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
          );
        },
      ),
      bottom: TabBar(
        controller: tabController,
        isScrollable: true,
        indicator: const BoxDecoration(),
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF338125),
        unselectedLabelColor: const Color(0xFF505050),
        labelStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        tabAlignment: TabAlignment.center,
        tabs: const [
          Tab(text: 'Global'),
          Tab(text: 'Cafe-Specific'),
          Tab(text: 'History'),
        ],
      ),
    );
  }
}
