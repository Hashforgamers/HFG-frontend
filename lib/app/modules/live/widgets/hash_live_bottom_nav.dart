import 'package:flutter/cupertino.dart';
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF090A0D),
        border: Border(top: BorderSide(color: LiveUi.stroke)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: LiveUi.accentSoft,
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/navbar_icons/Vector (1).png')),
            activeIcon: ImageIcon(
              AssetImage('assets/navbar_icons/Vector (1).png'),
            ),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.dot_radiowaves_left_right),
            activeIcon: Icon(CupertinoIcons.dot_radiowaves_left_right),
            label: 'Go Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Host',
          ),
        ],
      ),
    );
  }
}
