import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked_card_carousel/src/extension/list_reorder_extension.dart';

/// Control animate state of [StackedCardCarousel], handle user's interactivity
/// and ordering children.
class StackedListController {
  /// Number of completed transitions.
  int _transitionsCount = 0;

  /// The current outermost index of animate state.
  ///
  /// This index does not show which element is in outermost position,
  /// but only the order of the widget in the stack view.
  int get outermostIndex => _transitionsCount % maxDisplayedBannersCount;

  /// See [StackedCardCarousel.maxDisplayedBannersCount]
  final int maxDisplayedBannersCount;

  final int itemCount;

  /// Animation controller of stacked card carousel
  final AnimationController _animationController;

  AnimationController get animationController => _animationController;

  /// List of widgets that laid out in carousel.
  List<Widget> cardWidgets = [];

  /// Actual index of the card items inside banner widgets,
  List<int> displayedIndexes = [];

  /// Actual displayed size of item inside banner widgets.
  List<int> sizeFactors = [];

  /// Callback function to notify new outermost card items index transition completed.
  Function(int index)? onSwapDone;

  StackedListController({
    required this.maxDisplayedBannersCount,
    required this.itemCount,
    required Duration transitionDuration,
    required Duration autoSlideDuration,
    required TickerProvider vsync,
    this.onSwapDone,
  })  : _animationController = AnimationController(
          vsync: vsync,
          duration: transitionDuration,
        ),
        _autoSlideDuration = autoSlideDuration {
    displayedIndexes = List.generate(
      maxDisplayedBannersCount,
      (index) => index,
    );
    sizeFactors = List.generate(
      maxDisplayedBannersCount,
      (index) => maxDisplayedBannersCount - index - 1,
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
  void handleDragEnd(
    DragEndDetails details,
    double cardViewWidth,
    double layoutWidth,
  ) {
    _unlockTimer();
    _outermostCardOffset.value = Offset.zero;

    if ((details.velocity.pixelsPerSecond.dx).abs() > 600) {
      return swapOrders();
    }
    double dxMoved =
        (_outermostCardOffset.value.dx - (layoutWidth - cardViewWidth) / 2)
            .abs();
    double dxThreshold = cardViewWidth * 0.7;
    if (dxMoved > dxThreshold) {
      swapOrders();
    }
  }

  /// Called only once when the widget starts building process.
  void setCards(List<Widget> banners) {
    cardWidgets.addAll(banners);
    _animationController.forward();
    _startTimer();
  }

  final ValueNotifier<Offset> _outermostCardOffset = ValueNotifier(Offset.zero);

  ValueNotifier<Offset> get outermostCardOffset => _outermostCardOffset;

  /// Change banners list's order linearly. Each banner moving to front side closer,
  /// current banner will be hidden and pushed to the tail of banners list.
  void swapOrders() {
    for (int i = 0; i < displayedIndexes.length; i++) {
      displayedIndexes[i] = (displayedIndexes[i] + 1) % itemCount;
    }

    displayedIndexes.rotateLTR();
    sizeFactors.rotateLTR();
    cardWidgets.rotateRTL();

    _transitionsCount++;
    onSwapDone?.call(_transitionsCount % itemCount);
    _animationController.forward(from: 0.0);
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
    _animationController.dispose();
    _autoSlideTimer?.cancel();
    _outermostCardOffset.dispose();
  }
}
