import 'package:flutter/material.dart';
import 'package:hash/app/modules/live/widgets/live_ui.dart';

class HashLiveBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HashLiveBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      backgroundColor: const Color(0xFF000000),
      selectedItemColor: LiveUi.accentSoft,
      unselectedItemColor: Colors.white54,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.videocam_outlined),
          activeIcon: Icon(Icons.videocam),
          label: 'Live',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person),
          label: 'Host',
        ),
      ],
    );
  }
}
