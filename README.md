# stacked_list_carousel

**This package allows you to create a carousel of stacked items that is highly customizable and interactive. It is particularly well-suited for specific use cases, such as in-app banners or tinder's cards swipe effect. Support 2 carousel behavior: loop and consume.**

### Loop mode
The item won't be removed from items list after being swiped and will be inserted to last position. It also implements auto slide in a exact set duration.

<img alt="Demo" src="https://raw.githubusercontent.com/hongduc6/stacked_list_carousel/master/example/asset/loop_example.gif" height="500">

### Consume mode
The item will be removed from items list after being swiped. The auto slide feature is not enabled in this mode. Also, an empty builder must be provided to build empty UI when all cards are consumed.

<img alt="Demo" src="https://raw.githubusercontent.com/hongduc6/stacked_list_carousel/master/example/asset/consume_example.gif" height="500">

## Features
* Create a widget carousel which align its children vertically with well-animated and smooth transition animation.
* Provide item discard action listener, which provides its information and discarded swipe direction.

## Documentation

### Installation
Add `stacked_list_carousel` to your `pubspec.yaml`:

```
dependencies:
  flutter:
    sdk: flutter

  stacked_list_carousel: <latest version>
```

### Attributes

|            **Name**            |              **Type**             |                                             **Notes**                                            |                      **Description**                     |
|:------------------------------:|:---------------------------------:|:------------------------------------------------------------------------------------------------:|:--------------------------------------------------------:|
| items                          | List<T>                           |                                                                                                  | List of card models with T type                          |
| cardBuilder                    | Function(BuildContext,T,Size)     | - second params is built card model - third params are rendered card size                        | Card widget builder function                             |
| behavior                       | CarouselBehavior                  | enum: loop / consume                                                                             | Config carousel transition behavior                      |
| outermostCardWrapper           | Widget Function(Widget)?          | wrap built outermost card with another widget                                                    | Avoid using complicated build functions if possible      |
| innerCardsWrapper              | Widget Function(Widget)?          | wrap built inner cards with another widget                                                       | --                                                       |
| cardSwipedCallback             | void Function(T, SwipeDirection)? | - first param is swiped card model - second param is swiped direction when the card is discarded | Notify card discarded                                    |
| cardAspectRatio                | double?                           |                                                                                                  | The width / height ratio of each card                    |
| controller                     | StackedListController?            |                                                                                                  | Provide a custom StackedListController                   |
| emptyBuilder                   | WidgetBuilder?                    |                                                                                                  | Must be provided in consume mode                         |
| alignment                      | StackedListAxisAlignment          | enum: top / bottom                                                                               | Aligns card vertically top or bottom                     |
| outermostCardHeightFactor      | double                            | Must be lower than 1                                                                             | The ratio between outermost card height / view height    |
| animationDuration              | Duration                          |                                                                                                  | Transition animation duration                            |
| transitionCurve                | Curve                             |                                                                                                  | Defaults to Curves.easeIn                                |
| maxDisplayedItemCount          | int                               |                                                                                                  | Config max amount of displayed card                      |
| itemGapHeightFactor            | double                            | outermostCardHeightFactor + (maxDisplayedItemCount - 1) * itemGapHeightFactor <= 1               | The height factor of gap between cards and view height   |
| autoSlideDuration              | Duration                          |                                                                                                  | Config auto slide duration in loop mode                  |
| outermostCardAnimationDuration | Duration                          |                                                                                                  | The duration of outermost card's flying effect animation |

### Implements

Import the package:

```
import 'package:stacked_list_carousel/stacked_list_carousel.dart';
```

Then use StackedCardCarousel widget

```
StackedListCarousel<AwesomeInAppBanner>(
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
```

### Contribution

Please contact via [**Github**](https://github.com/hongduc6)
