import 'package:flutter/material.dart';
import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';

class VendorPassesWidget extends StatefulWidget {
  final List<GetVendorPassesModel> vendorPasses;
  const VendorPassesWidget({super.key, required this.vendorPasses});

  @override
  State<VendorPassesWidget> createState() => _VendorPassesWidgetState();
}

class _VendorPassesWidgetState extends State<VendorPassesWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
