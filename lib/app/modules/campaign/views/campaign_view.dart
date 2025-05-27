import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/amplitude_service.dart';
import '../controllers/campaign_controller.dart';

class CampaignView extends GetView<CampaignController> {
  final _amplitudeService = serviceLocator<AmplitudeService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: controller.campaigns.length,
        itemBuilder: (context, index) {
          final campaign = controller.campaigns[index];
          return GestureDetector(
            onTap: () async {
              await _amplitudeService.trackCampaignViewed(
                source: 'campaign_list',
                campaignId: campaign.id,
              );
              Get.to(() => CampaignDetailView(campaign: campaign));
            },
            child: Card(
              child: Column(
                children: [
                  Image.network(campaign.imageUrl),
                  Text(campaign.title),
                  Text(campaign.description),
                  ElevatedButton(
                    onPressed: () async {
                      await _amplitudeService.trackCampaignConversion(
                        campaignId: campaign.id,
                        action: 'participate',
                      );
                      // Handle campaign participation
                    },
                    child: Text('Participate'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 