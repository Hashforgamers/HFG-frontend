import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/widgets/store_category_icon.dart';

void main() {
  test('every live category gets its own icon, none generic', () {
    // The 22 categories /store/hash/categories returned on 2026-11-01.
    const live = {
      'accessories': 'Accessories',
      'keyboards': 'Keyboards',
      'mouse': 'Mouse',
      'monitors': 'Monitors',
      'chairs': 'Chairs',
      'controller': 'Controller',
      'headsets': 'Headsets & headphones',
      'mousepads': 'Mousepads & desk mats',
      'microphones': 'Microphones',
      'webcams': 'Webcams & capture cards',
      'speakers': 'Speakers',
      'gaming-desks': 'Gaming desks',
      'graphics-cards': 'Graphics cards',
      'processors': 'Processors',
      'motherboards': 'Motherboards',
      'memory': 'RAM & memory',
      'storage': 'SSDs & hard drives',
      'power-supplies': 'Power supplies',
      'pc-cases': 'PC cases',
      'cooling': 'Cooling & fans',
      'gaming-laptops': 'Gaming laptops',
      'gaming-pcs': 'Gaming desktops',
    };
    for (final e in live.entries) {
      expect(
        storeCategoryIcon(e.key, e.value),
        isNot(Icons.category_outlined),
        reason: e.key,
      );
    }
  });

  test('specific words beat broad ones', () {
    expect(storeCategoryIcon('mousepads', null), Icons.crop_landscape_rounded);
    expect(storeCategoryIcon('mouse', null), Icons.mouse_outlined);
    expect(storeCategoryIcon('pc-cases', 'PC cases'), Icons.dns_outlined);
    expect(storeCategoryIcon('gaming-laptops', null), Icons.laptop_outlined);
    expect(
      storeCategoryIcon('gaming-pcs', null),
      Icons.desktop_windows_outlined,
    );
  });

  test('new categories map by name; unknown ones stay generic', () {
    expect(storeCategoryIcon('rgb-fans', 'RGB fans'), Icons.ac_unit_rounded);
    expect(
      storeCategoryIcon(null, 'Gaming headsets'),
      Icons.headphones_rounded,
    );
    // Short keys match whole words only: "frames" is not RAM.
    expect(
      storeCategoryIcon('photo-frames', 'Photo frames'),
      Icons.category_outlined,
    );
    expect(storeCategoryIcon(null, null), Icons.category_outlined);
  });
}
