import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stacked_list_carousel/src/enums/enums.dart';

typedef AnimationCallback = void Function(CarouselBehavior);

typedef CardSwipedCallback<T> = void Function(T, SwipeDirection);

class StackedListController<T> {
  StackedListController();

  late CarouselBehavior carouselBehavior;
  OutermostCardBehavior outermostCardBehavior = OutermostCardBehavior.flyAway;

  late AnimationController transitionController;
  late AnimationController outermostCardAnimationController;

  /// List of cards model [T] .
  late List<T> items;

  /// Length of [items].
  int get itemCount => items.length;

  int swapCount = 0;

  /// Whether all cards has been discarded in consume mode.
  bool get consumedAll =>
      swapCount >= items.length && carouselBehavior == CarouselBehavior.consume;

  /// The real outermost index of outermost card inside [items].
  int get realOutermostIndex => swapCount % items.length;

  bool get _isAnimating => transitionForwarding;

  /// Whether the animation is forwarding.
  bool get transitionForwarding =>
      transitionController.status == AnimationStatus.forward;

  /// Animation value.
  double get transitionValue => transitionController.value;

  /// The outermost card offset.
  ValueNotifier<Offset> outermostCardOffset = ValueNotifier(Offset.zero);

  /// Callback when animation starts.
  late AnimationCallback onAnimating;

  /// Callback to notify card swiped.
  late CardSwipedCallback<T>? onCardSwiped;

  /// Determine if the carousel should be interacted or not.
  late bool disableInteractingGestures;

  /// Trigger cards swap.
  Future<void> changeOrders({
    bool withOutermostDiscardEffect = false,
  }) async {
    // Does nothing if current animations is busy.
    if (_isAnimating) return;

    if (withOutermostDiscardEffect) {
      await outermostCardAnimationController.forward(from: 0);
      onCardSwiped?.call(
        items[realOutermostIndex],
        getSwipeDirection(offset: outermostCardOffset.value),
      );
    }

    onAnimating.call(carouselBehavior);

    outermostCardAnimationController.reset();
    outermostCardOffset.value = Offset.zero;
  }

  void registerOutermostCardAnimationListener() =>
      outermostCardAnimationController.addListener(
        () {
          if (outermostCardBehavior == OutermostCardBehavior.flyAway) {
            outermostCardOffset.value = outermostCardOffset.value *
                (1 + outermostCardAnimationController.value / 4);
          } else {
            outermostCardOffset.value = outermostCardOffset.value *
                outermostCardAnimationController.value;
          }
        },
      );

  /// Handle user's drag start gesture.
  ///
  /// On drag start, lock the timer and restrict carousel from transition.
  void handleDragStart(
    DragStartDetails details,
  ) {
    if (disableInteractingGestures) return;

    _lockTimer();
  }

  /// Handle user's drag update gesture.
  ///
  /// On update, updates current outermost card actual position while being
  /// interacted.
  void handleDragUpdate(
    DragUpdateDetails details,
  ) {
    if (disableInteractingGestures) return;

    if (itemCount > 1) {
      outermostCardOffset.value = outermostCardOffset.value + details.delta;
    }
  }

  /// Handle user's drag end gesture.
  ///
  /// Unlocks timer and allow carousel to continue transitions periodically.
  /// Also set outermost card's offset to zero.
  ///
  /// If user's swipe gesture's distance longer than dxThreshold (width) of the
  /// banner, dismiss it and trigger swapOrders.
  Future<void> handleDragEnd(
    DragEndDetails details,
    double cardViewWidth,
    double layoutWidth,
  ) async {
    if (disableInteractingGestures) return;

    if (itemCount <= 1) return;

    final dxThreshold = layoutWidth / 2;
    if ((details.velocity.pixelsPerSecond.dx).abs() > dxThreshold) {
      await changeOrders(withOutermostDiscardEffect: true);
    } else {
      final dxMoved =
          (outermostCardOffset.value.dx - (layoutWidth - cardViewWidth) / 2)
              .abs();

      if (dxMoved > dxThreshold) {
        await changeOrders(withOutermostDiscardEffect: true);
      } else {
        /// If outermost card wasn't discarded, change behavior mode to come
        /// back then animates offset to Offset.zero.
        outermostCardBehavior = OutermostCardBehavior.comeBack;
        await outermostCardAnimationController.reverse(from: 1).then(
              (_) => outermostCardBehavior = OutermostCardBehavior.flyAway,
            );
      }
    }

    _unlockTimer();
  }

  late final Duration autoSlideDuration;
  Timer? _autoSlideTimer;
  int _timerLockedCount = -1;
  bool _timerUnlocked = true;

  void startTransitionLoop() {
    if (carouselBehavior == CarouselBehavior.loop) {
      _startTimer();
    }
  }

  void _startTimer() {
    _autoSlideTimer = Timer.periodic(
      autoSlideDuration,
      (_) {
        if (_timerLockedCount == -1) {
          changeOrders();
        } else if (_timerLockedCount > -1 && _timerUnlocked) {
          _timerLockedCount--;
          if (_timerLockedCount == -1) {
            changeOrders();
          }
        }
      },
    );
  }

  void _lockTimer() {
    _timerLockedCount = 1;
    _timerUnlocked = false;
  }

  void _unlockTimer() {
    _timerUnlocked = true;
  }

  void dispose() {
    transitionController.dispose();
    outermostCardOffset.dispose();
    _autoSlideTimer?.cancel();
    outermostCardAnimationController.dispose();
  }
}

SwipeDirection getSwipeDirection({required Offset offset}) {
  final dir = offset.direction;
  if (dir >= 0 && dir < pi / 2) {
    return SwipeDirection.bottomRight;
  } else if (dir >= pi / 2 && dir <= pi) {
    return SwipeDirection.bottomLeft;
  } else if (dir >= -pi / 2 && dir < 0) {
    return SwipeDirection.topRight;
  } else {
    return SwipeDirection.topLeft;
  }
}
