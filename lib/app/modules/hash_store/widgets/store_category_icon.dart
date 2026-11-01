import 'package:flutter/material.dart';

/// Icon for a shop category from its words, since the backend sends none.
/// New categories pick up an icon automatically when their handle or name
/// uses a known word ("Gaming headsets", "rgb-fans"); anything else gets the
/// generic icon.
IconData storeCategoryIcon(String? handle, String? name) {
  final words = '${handle ?? ''} ${name ?? ''}'
      .toLowerCase()
      .split(RegExp('[^a-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  for (final (keys, icon) in _rules) {
    for (final w in words) {
      // Stems match plurals ("speaker" -> "speakers"); short words like
      // "pc" or "ram" match only themselves or a plural, so "frame" isn't RAM.
      if (keys.any(
        (k) => k.length <= 3 ? (w == k || w == '${k}s') : w.startsWith(k),
      )) {
        return icon;
      }
    }
  }
  return Icons.category_outlined;
}

// First match wins, so more specific words come before broader ones
// ("mousepad" before "mouse", "laptop" and "case" before "pc").
const _rules = <(List<String>, IconData)>[
  (['mousepad', 'deskmat', 'mat'], Icons.crop_landscape_rounded),
  (['mouse', 'mice'], Icons.mouse_outlined),
  (['keyboard', 'keycap'], Icons.keyboard_alt_outlined),
  (['headset', 'headphone', 'earphone', 'earbud'], Icons.headphones_rounded),
  (['mic', 'microphone'], Icons.mic_none_rounded),
  (['webcam', 'camera', 'capture', 'stream'], Icons.videocam_outlined),
  (['speaker', 'soundbar', 'audio'], Icons.speaker_outlined),
  (['monitor', 'display', 'screen'], Icons.monitor_rounded),
  (['chair', 'seat'], Icons.chair_outlined),
  (['desk', 'table'], Icons.table_restaurant_outlined),
  (
    ['controller', 'gamepad', 'joystick', 'console'],
    Icons.sports_esports_outlined,
  ),
  (['graphic', 'gpu'], Icons.developer_board_outlined),
  (['motherboard', 'mainboard'], Icons.dashboard_customize_outlined),
  (['processor', 'cpu'], Icons.memory_rounded),
  (['memory', 'ram'], Icons.view_week_outlined),
  (['storage', 'ssd', 'hdd', 'drive', 'nvme'], Icons.storage_rounded),
  (['power', 'psu', 'ups'], Icons.power_outlined),
  (['cooling', 'cooler', 'fan', 'liquid'], Icons.ac_unit_rounded),
  (['case', 'cabinet', 'chassis'], Icons.dns_outlined),
  (['laptop', 'notebook'], Icons.laptop_outlined),
  (['desktop', 'pc', 'rig', 'computer'], Icons.desktop_windows_outlined),
  (['cable', 'adapter', 'hub', 'charger'], Icons.cable_rounded),
  (['accessor', 'merch', 'gear'], Icons.headphones_rounded),
];
