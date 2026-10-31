import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';

class VendorPassesResponse {
  final List<GetVendorPassesModel> hourBasedPasses;
  final List<GetVendorPassesModel> dateBasedPasses;
  final List<GetVendorPassesModel> passes;
  final List<GetVendorPassesModel> allPasses;
  final Map<String, int> counts;

  const VendorPassesResponse({
    this.hourBasedPasses = const <GetVendorPassesModel>[],
    this.dateBasedPasses = const <GetVendorPassesModel>[],
    this.passes = const <GetVendorPassesModel>[],
    this.allPasses = const <GetVendorPassesModel>[],
    this.counts = const <String, int>{},
  });

  List<GetVendorPassesModel> get visiblePasses {
    if (passes.isNotEmpty) return passes;
    if (hourBasedPasses.isNotEmpty || dateBasedPasses.isNotEmpty) {
      return <GetVendorPassesModel>[...hourBasedPasses, ...dateBasedPasses];
    }
    if (allPasses.isNotEmpty) return allPasses;

    return const <GetVendorPassesModel>[];
  }

  int countFor(String key, List<GetVendorPassesModel> fallback) {
    return counts[key] ?? fallback.length;
  }
}
