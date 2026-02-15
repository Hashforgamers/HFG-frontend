import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/game_pass/cubit/game_pass_cubit.dart';
import 'package:hash/app/modules/game_pass/cubit/get_game_pass_cubit.dart';
import 'package:hash/app/modules/game_pass/view/cafe_specific_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/global_pass_view.dart';
import 'package:hash/app/modules/game_pass/view/hash_pass_history_view.dart';

class GamePassViewPage extends StatelessWidget {
  const GamePassViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GamePassCubit()),
        BlocProvider(create: (context) => GetGamePassCubit()),
      ],
      child: const _GamePassViewPage(),
    );
  }
}

class _GamePassViewPage extends StatefulWidget {
  const _GamePassViewPage();

  @override
  State<_GamePassViewPage> createState() => __GamePassViewPageState();
}

class __GamePassViewPageState extends State<_GamePassViewPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const GamePassView();
  }
}

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
        // Trigger API call based on selected tab
        if (tabController.index == 0) {
          // Global tab
          context.read<GamePassCubit>().getGamePass(type: 'hash');
        } else if (tabController.index == 1) {
          // Cafe-Specific tab
          context.read<GamePassCubit>().getGamePass(type: 'vendor');
        } else if (tabController.index == 2) {
          // History tab
          context.read<GetGamePassCubit>().getGamePassHistory();
        }
      }
    });

    // Initial load for Global tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamePassCubit>().getGamePass(type: 'hash');
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBarView(
            controller: tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GlobalPassView(tabController: tabController, type: 'hash'),
              CafeSpecificPassView(
                tabController: tabController,
                type: 'vendor',
              ),
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
        icon: const Icon(Icons.arrow_back, color: Color(0xff00DC00)),
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
        labelColor: const Color(0xff00DC00),
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
