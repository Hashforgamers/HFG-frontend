import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_coin/cubit/create_offer_cubit.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/app/modules/hash_coin/widgets/hash_coin_widget.dart';

class HashCoinPage extends StatelessWidget {
  const HashCoinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HashCoinCubit(),
        ),
        BlocProvider(
          create: (context) => CreateOfferCubit(),
        ),
      ],
      child: const _HashCoinPage(),
    );
  }
}

class _HashCoinPage extends StatefulWidget {
  const _HashCoinPage();

  @override
  State<_HashCoinPage> createState() => __HashCoinPageState();
}

class __HashCoinPageState extends State<_HashCoinPage> {
  @override
  void initState() {
    super.initState();
    context.read<HashCoinCubit>().getHashCoin();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HashCoinCubit, HashCoinState>(
      builder: (context, state) {
        if (state is HashCoinLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is HashCoinLoaded) {
          return HashCoinWidget(
            hashCoin: state.hashCoin,
            createOfferCubit: context.read<CreateOfferCubit>(),
          );
        } else {
          return const Scaffold(
            body: Center(child: Text('Error')),
          );
        }
      },
    );
  }
}
