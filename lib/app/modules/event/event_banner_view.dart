import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventBanner extends StatelessWidget {
  final List<String> imgList = [
    'https://i1.wp.com/roonby.com/wp-content/uploads/2022/07/afkgaming_2021-07_d1a5deab-9632-419f-a1a7-a7aa0411b5be_Aztral__17_.jpg?resize=1200%2C630&ssl=1',
    'https://nosnerds.com.br/wp-content/uploads/2020/06/pubgmobilepmplloops-capa.jpg',
    'https://mir-s3-cdn-cf.behance.net/project_modules/fs/fb8e63113195963.6022ecca5fa95.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 190,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          viewportFraction: 1,
        ),
        items: imgList.map((item) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(item), // Use CachedNetworkImageProvider here
                fit: BoxFit.fill,
              ),
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(35),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
