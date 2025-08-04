import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/game_pass/cubit/get_game_pass_cubit.dart';
import 'package:hash/app/modules/game_pass/widgets/game_pass_widget.dart';

class GamePassPage extends StatelessWidget {
  const GamePassPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetGamePassCubit(),
      child: const _GamePassPage(),
    );
  }
}

class _GamePassPage extends StatefulWidget {
  const _GamePassPage();

  @override
  State<_GamePassPage> createState() => __GamePassPageState();
}

class __GamePassPageState extends State<_GamePassPage> {
  @override
  void initState() {
    BlocProvider.of<GetGamePassCubit>(context).getGamePass();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GamePassWidget();
  }
}
