import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/game_pass/cubit/get_vendor_passes_cubit.dart';
import 'package:hash/app/modules/game_pass/widgets/game_pass_widget.dart';

class VendorPassesPage extends StatelessWidget {
  final String vendorId;
  const VendorPassesPage({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetVendorPassesCubit(),
      child: _GamePassPage(vendorId: vendorId),
    );
  }
}

class _GamePassPage extends StatefulWidget {
  final String vendorId;
  const _GamePassPage({required this.vendorId});

  @override
  State<_GamePassPage> createState() => __GamePassPageState();
}

class __GamePassPageState extends State<_GamePassPage> {
  @override
  void initState() {
    BlocProvider.of<GetVendorPassesCubit>(context).getVendorPasses(vendorId: widget.vendorId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetVendorPassesCubit, GetVendorPassesState>(
      builder: (context, state) {
        if (state is GetVendorPassesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GetVendorPassesError) {
          return Center(child: Text(state.message));
        } else if (state is GetVendorPassesLoaded) {
          if (state.vendorPasses.isEmpty) {
            return const Center(child: Text('No game passes available'));
          }
          return VendorPassesWidget(vendorPasses: state.vendorPasses);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
