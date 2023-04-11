import 'package:flutter/material.dart';
import 'package:stacked_list_carousel/stacked_list_carousel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stacked Cards Example',
      theme: ThemeData(
        useMaterial3: true,
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
        title: const Text('Stacked List Carousel'),
      ),
      body: StackedListCarousel<AwesomeInAppBanner>(
        items: banners,
        behavior: CarouselBehavior.consume,
        // A widget builder callback to build cards with context, card model
        // and its size attributes.
        cardBuilder: (context, item, size) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Stack(
              children: [
                Image.network(
                  item.imgUrl,
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 30.0 *
                            size.width /
                            MediaQuery.of(context).size.width,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        // You can config fixed card width / height ratio. For default, the ratio
        // is view size width / height
        // cardAspectRatio: 0.75,
        // Config outermost card height factor relative to view height
        outermostCardHeightFactor: 0.8,
        // Gap height factor relative to view height
        itemGapHeightFactor: 0.05,
        // Config max item displayed count
        maxDisplayedItemCount: 3,
        // You can config transition duration here (the animation between cards
        // swap). Defaults to 450 milliseconds
        animationDuration: const Duration(milliseconds: 550),
        // You can config auto slide duration. This only works in loop mode.
        autoSlideDuration: const Duration(seconds: 8),
        // Define cards align
        alignment: StackedListAxisAlignment.bottom,
        // In consume mode, you must declare the empty builder, which will be
        // built when user swiped all cards.
        emptyBuilder: (context) => const Center(
          child: Text('You have consumed all cards!'),
        ),
        // You can customize inner cards wrapper builder. For example, you want to
        // shade the unready cards, just wrap it with a gray decorated box.
        innerCardsWrapper: (child) {
          return Stack(
            children: [
              child,
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xffA6A3CC).withOpacity(0.64),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
        // You can also customize outermost card builder for some special effects.
        outermostCardWrapper: (child) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent,
                  blurRadius: 12,
                  blurStyle: BlurStyle.normal,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: child,
          );
        },
        // When implementing use case like tinder card swipe,
        // you'll wish to know what swipe behavior user did.
        // This callback will provide the discard direction of
        // corresponding item for you.
        cardSwipedCallback: (item, direction) {
          debugPrint('card swiped: ${item.title}, $direction');
        },
      ),
    );
  }
}

class AwesomeInAppBanner {
  final String imgUrl;
  final String title;
  final Color color;

  const AwesomeInAppBanner(
    this.imgUrl,
    this.title,
    this.color,
  );
}

List<AwesomeInAppBanner> banners = <AwesomeInAppBanner>[
  AwesomeInAppBanner(
    'https://picsum.photos/id/123/1200/1800',
    'My awesome banner No.1',
    Colors.green.shade300,
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/234/1200/1800',
    'My awesome banner No.2',
    Colors.red.shade300,
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/345/1200/1800',
    'My awesome banner No.3',
    Colors.purple.shade300,
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/456/1200/1800',
    'My awesome banner No.4',
    Colors.yellow.shade300,
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/567/1200/1800',
    'My awesome banner No.5',
    Colors.blue.shade300,
  ),
  AwesomeInAppBanner(
    'https://picsum.photos/id/678/1200/1800',
    'My awesome banner No.6',
    Colors.orange.shade300,
  ),
];
