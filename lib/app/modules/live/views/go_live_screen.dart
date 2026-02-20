import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/app_mode_segmented_toggle.dart';
import 'package:hash/app/modules/live/controllers/hash_live_controller.dart';
import 'package:hash/app/modules/live/views/live_stream_screen.dart';

class GoLiveScreen extends StatelessWidget {
  const GoLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HashLiveController>()
        ? Get.find<HashLiveController>()
        : Get.put(HashLiveController(), permanent: true);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Go Live', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: AppModeSegmentedToggle(compact: true),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _fieldLabel('Stream Title'),
          const SizedBox(height: 6),
          TextField(
            controller: controller.titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(hint: 'Enter stream title'),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Game'),
          const SizedBox(height: 6),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedGame.value.isEmpty ? null : controller.selectedGame.value,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(),
              items: controller.games.map((game) => DropdownMenuItem(value: game, child: Text(game))).toList(),
              onChanged: (value) => controller.setGame(value ?? ''),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel('YouTube Link'),
          const SizedBox(height: 6),
          TextField(
            controller: controller.youtubeController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(hint: 'Paste stream URL'),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SwitchListTile(
              value: controller.isStreamingFromCafe.value,
              activeThumbColor: const Color(0xFF00DC00),
              title: Text('Streaming from Café', style: GoogleFonts.inter(color: Colors.white)),
              onChanged: controller.setStreamingFromCafe,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () async {
                      final streamId = await controller.startLive();
                      if (streamId == null || streamId.isEmpty) return;
                      Get.off(() => LiveStreamScreen(streamId: streamId));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00DC00),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text('Start Live', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}
