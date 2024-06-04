import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/rewards/reward_section_view.dart';
import '../../../../utils/widgets/loader.dart';
import '../../arena/views/arena_section_view.dart';
import '../../event/event_banner_view.dart';
import '../../game/views/game_section_view.dart';
import '../../shop/views/shop_section_view.dart';
import '../../team/team_section_view.dart';
import '../../tournaments/views/tournament_section_view.dart';
import '../../shorts/views/viral_shots_view.dart';


class HomeContentView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text('Hey, Gamer!', style: TextStyle(color: Colors.white)),
        PopupMenuButton<String>(offset: Offset(0, 40),
          color: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (String result) {
            // Handle menu item selection here
            print(result);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Profile',
              child: Text('Profile',style: TextStyle(color:Color.fromRGBO(58, 255, 107, 1.0), ),),
            ),
            const PopupMenuItem<String>(
              value: 'Settings',
              child: Text('Settings',style: TextStyle(color:Color.fromRGBO(58, 255, 107, 1.0), ),),
            ),
            const PopupMenuItem<String>(
              value: 'Logout',
              child: Text('Logout',style: TextStyle(color:Color.fromRGBO(58, 255, 107, 1.0), ),),
            ),
          ],
          child: CircleAvatar(
            child: Icon(Icons.person),
            backgroundColor: Color.fromRGBO(58, 255, 107, 1.0),
          ),
        )
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView(shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        children: [
          RewardsSection(),
          const SizedBox(height: 18,),

          RainbowLoadingBar(height: 0.5,width: Get.width,),

          const SizedBox(height: 18,),
          EventBanner(),
          const SizedBox(height: 18,),

          ViralShotsSection(),
          const SizedBox(height: 18,),

          ArenaSection(),
          const SizedBox(height: 18,),

          TeamSection(),
          const SizedBox(height: 18,),

          ShopSection(),
          const SizedBox(height: 18,),

          TournamentsSection(),
          const SizedBox(height: 18,),

          GamesSection(),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'Game On, India!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
