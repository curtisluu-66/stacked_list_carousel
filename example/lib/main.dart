import 'package:flutter/material.dart';
import 'package:stacked_list_carousel/stacked_list_carousel.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stacked Cards Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(title: 'Awesome Card Carousel'),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StackedListCarousel<AwesomeInAppBanner>(
        items: banners,
        // Highly customizable builder function which actual widget's size,
        // its index inside item list, and whether built item is outermost
        itemBuilder: (context, size, index, isOutermost) => ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            color: cardColors[index],
            child: Center(
              child: Text(
                banners[index].title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Config card's aspect ratio
        cardAspectRatio: 16 / 9,
        // Config outermost card height factor relative to view height
        outermostCardHeightFactor: 0.7,
        // Config max item displayed count
        maxDisplayedItemsCount: 4,
        // Config view size height factor relative to view height
        viewSizeHeightFactor: 0.9,
        autoSlideDuration: const Duration(seconds: 4),
      ),
    );
  }
}

class AwesomeInAppBanner {
  final String imgUrl;
  final String title;

  const AwesomeInAppBanner(
    this.imgUrl,
    this.title,
  );
}

const List<AwesomeInAppBanner> banners = <AwesomeInAppBanner>[
  AwesomeInAppBanner(
    'https://picsum.photos/id/100/200/300',
    'Random image 1',
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/200/200/300',
    'Random image 2',
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/300/600/900',
    'Random image 3',
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/400/600/900',
    'Random image 4',
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/500/600/900',
    'Random image 5',
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/600/600/900',
    'Random image 6',
  ),
];

List<Color> cardColors = [
  Colors.green.shade300,
  Colors.red.shade300,
  Colors.purple.shade300,
  Colors.yellow.shade300,
  Colors.blue.shade300,
  Colors.orange.shade300,
];
