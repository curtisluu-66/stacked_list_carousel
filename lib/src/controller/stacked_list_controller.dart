import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:stacked_list_carousel/src/enums/outermost_card_behavior.dart';
import 'package:stacked_list_carousel/src/enums/swipe_direction.dart';
import 'package:stacked_list_carousel/src/extension/list_reorder_extension.dart';

typedef SwipeNotify = void Function(
  int outermostIndex,
  SwipeDirection direction,
);

/// Control animate state of [StackedCardCarousel], handle user's interactivity
/// and ordering children.
class StackedListController {
  /// Number of completed transitions.
  int _transitionsCount = 0;

  /// The current outermost index inside widgets list.
  ///
  /// This index does not show which element is in outermost position (see [outermostItemIndex]),
  /// but only the order of the widget in the stack view.
  int get outermostCardIndex => _transitionsCount % maxDisplayedItemsCount;

  /// The current outermost index inside items list.
  int get outermostItemIndex => _transitionsCount % itemsCount;

  /// See [StackedCardCarousel.maxDisplayedItemsCount]
  final int maxDisplayedItemsCount;

  final int itemsCount;

  /// Animation controller of stacked card carousel
  final AnimationController _transitionController;
  final AnimationController _outermostTransitionController;

  AnimationController get transitionController => _transitionController;

  AnimationController get outermostTransitionController =>
      _outermostTransitionController;

  OutermostCardBehavior cardBehavior = OutermostCardBehavior.flyAway;

  double get transitionValue => transitionController.value;
  double get outermostTransitionValue => outermostTransitionController.value;

  /// List of widgets that laid out in carousel.
  List<Widget> cardWidgets = [];

  /// Actual index of the card items inside banner widgets,
  List<int> displayedIndexes = [];

  /// Actual displayed size of item inside banner widgets.
  List<int> sizeFactors = [];

  SwipeNotify? onItemDiscarded;

  /// Callback function to notify new outermost card items index transition completed.
  Function(int index)? onOutermostIndexChanged;

  StackedListController({
    required this.maxDisplayedItemsCount,
    required this.itemsCount,
    required Duration transitionDuration,
    required Duration outermostTransitionDuration,
    required Duration autoSlideDuration,
    required TickerProvider vsync,
    this.onItemDiscarded,
    this.onOutermostIndexChanged,
  })  : _autoSlideDuration = autoSlideDuration,
        _transitionController = AnimationController(
          vsync: vsync,
          duration: transitionDuration,
        ),
        _outermostTransitionController = AnimationController(
          vsync: vsync,
          duration: outermostTransitionDuration,
        ) {
    displayedIndexes = List.generate(
      maxDisplayedItemsCount,
      (index) => index,
    );

    sizeFactors = List.generate(
      maxDisplayedItemsCount,
      (index) => maxDisplayedItemsCount - index - 1,
    );

    _outermostTransitionController.addListener(
      () {
        if (cardBehavior == OutermostCardBehavior.flyAway) {
          _outermostCardOffset.value =
              _outermostCardOffset.value * (1 + outermostTransitionValue / 4);
        } else {
          _outermostCardOffset.value =
              _outermostCardOffset.value * outermostTransitionValue;
        }
      },
    );
  }

  /// Handle user's drag start gesture.
  ///
  /// On drag start, lock the timer and restrict carousel from transition.
  void handleDragStart(
    DragStartDetails details,
  ) =>
      _lockTimer();

  /// Handle user's drag update gesture.
  ///
  /// On update, updates current outermost card actual position while being interacted.
  void handleDragUpdate(
    DragUpdateDetails details,
  ) =>
      _outermostCardOffset.value = _outermostCardOffset.value + details.delta;

  /// Handle user's drag end gesture.
  ///
  /// Unlocks timer and allow carousel to continue transitions periodically.
  /// Also set outermost card's offset to zero.
  ///
  /// If user's swipe gesture's distance longer than [dxThreshold] (width) of the banner,
  /// dismiss it and trigger [swapOrders].
  Future<void> handleDragEnd(
    DragEndDetails details,
    double cardViewWidth,
    double layoutWidth,
  ) async {
    final double dxThreshold = layoutWidth / 2;
    if ((details.velocity.pixelsPerSecond.dx).abs() > dxThreshold) {
      await swapOrders(withOutermostDiscardEffect: true);
    } else {
      double dxMoved =
          (_outermostCardOffset.value.dx - (layoutWidth - cardViewWidth) / 2)
              .abs();

      if (dxMoved > dxThreshold) {
        await swapOrders(withOutermostDiscardEffect: true);
      } else {
        /// If outermost card wasn't discarded, change behavior mode to come back
        /// then animates offset to Offset.zero.
        cardBehavior = OutermostCardBehavior.comeBack;
        await _outermostTransitionController.reverse(from: 1.0).then(
              (_) => cardBehavior = OutermostCardBehavior.flyAway,
            );
      }
    }

    _unlockTimer();
  }

  /// Called only once when the widget starts building process.
  void setCards(List<Widget> banners) {
    cardWidgets.addAll(banners);
    _transitionController.forward();
    _startTimer();
  }

  final ValueNotifier<Offset> _outermostCardOffset = ValueNotifier(Offset.zero);

  ValueNotifier<Offset> get outermostCardOffset => _outermostCardOffset;

  /// Change banners list's order linearly. Each banner moving to front side closer,
  /// current banner will be hidden and pushed to the tail of banners list.
  Future<void> swapOrders({
    bool withOutermostDiscardEffect = false,
  }) async {
    if (withOutermostDiscardEffect) {
      onItemDiscarded?.call(
        _transitionsCount % itemsCount,
        getSwipeDirection(offset: _outermostCardOffset.value),
      );
      await outermostTransitionController.forward(from: 0.0);
    }

    // Rotate arrays
    for (int i = 0; i < displayedIndexes.length; i++) {
      displayedIndexes[i] = (displayedIndexes[i] + 1) % itemsCount;
    }

    displayedIndexes.rotateLTR();
    sizeFactors.rotateLTR();
    cardWidgets.rotateRTL();

    _transitionsCount++;

    _outermostTransitionController.reset();

    _transitionController.forward(from: 0.0);
    onOutermostIndexChanged?.call(outermostItemIndex);
    _outermostCardOffset.value = Offset.zero;
  }

  final Duration _autoSlideDuration;
  Timer? _autoSlideTimer;
  int _timerLockedCount = -1;
  bool _timerUnlocked = true;

  void _startTimer() {
    _autoSlideTimer = Timer.periodic(
      _autoSlideDuration,
      (_) {
        if (_timerLockedCount == -1) {
          swapOrders();
        } else if (_timerLockedCount > -1 && _timerUnlocked) {
          _timerLockedCount--;
          if (_timerLockedCount == -1) {
            swapOrders();
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

  /// Free used elements.
  void dispose() {
    _transitionController.dispose();
    _autoSlideTimer?.cancel();
    _outermostCardOffset.dispose();
    _outermostTransitionController.dispose();
  }
}

SwipeDirection getSwipeDirection({required Offset offset}) {
  final double dir = offset.direction;
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
