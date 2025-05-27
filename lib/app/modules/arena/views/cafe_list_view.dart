import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/amplitude_service.dart';
import '../controllers/cafe_controller.dart';

class CafeListView extends GetView<CafeController> {
  final _amplitudeService = serviceLocator<AmplitudeService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sort and filter options
          Row(
            children: [
              DropdownButton<String>(
                value: controller.sortType.value,
                onChanged: (value) async {
                  if (value != null) {
                    await _amplitudeService.trackCafeListViewed(
                      sortType: value,
                      filterType: controller.filterType.value,
                    );
                    controller.updateSortType(value);
                  }
                },
                items: ['Rating', 'Distance', 'Price'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                value: controller.filterType.value,
                onChanged: (value) async {
                  if (value != null) {
                    await _amplitudeService.trackCafeListViewed(
                      sortType: controller.sortType.value,
                      filterType: value,
                    );
                    controller.updateFilterType(value);
                  }
                },
                items: ['All', 'Open Now', 'Has Games'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
            ],
          ),
          // Cafe list
          Expanded(
            child: ListView.builder(
              itemCount: controller.cafes.length,
              itemBuilder: (context, index) {
                final cafe = controller.cafes[index];
                return ListTile(
                  onTap: () async {
                    await _amplitudeService.trackGamingCafeViewed(
                      cafeId: cafe.id,
                      location: cafe.location,
                      availableGames: cafe.availableGames,
                    );
                    Get.to(() => CafeDetailView(cafe: cafe));
                  },
                  title: Text(cafe.name),
                  subtitle: Text(cafe.location),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 