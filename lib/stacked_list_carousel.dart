import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stacked_list_carousel/src/controller/stacked_list_controller.dart';
import 'package:stacked_list_carousel/src/enums/enums.dart';
import 'package:stacked_list_carousel/src/extension/extensions.dart';
import 'package:stacked_list_carousel/src/helpers/aspect_size.dart';

export './src/controller/stacked_list_controller.dart';
export './src/enums/enums.dart';

typedef SizedWidgetBuilder<T> = Widget Function(BuildContext, T, Size);

typedef WrapperBuilder = Widget Function(Widget);

class StackedListCarousel<T> extends StatefulWidget {
  const StackedListCarousel({
    required this.items,
    required this.cardBuilder,
    required this.behavior,
    this.cardSwipedCallback,
    this.cardAspectRatio,
    this.controller,
    this.emptyBuilder,
    this.alignment = StackedListAxisAlignment.bottom,
    this.outermostCardHeightFactor = 0.8,
    this.animationDuration = const Duration(milliseconds: 450),
    this.transitionCurve = Curves.easeIn,
    this.maxDisplayedItemCount = 3,
    this.itemGapHeightFactor = 0.05,
    this.autoSlideDuration = const Duration(seconds: 5),
    this.outermostCardAnimationDuration = const Duration(milliseconds: 450),
    this.innerCardsWrapper,
    this.outermostCardWrapper,
    Key? key,
  })  : assert(
          behavior != CarouselBehavior.consume || emptyBuilder != null,
          'emptyBuilder() must be provided in consume mode',
        ),
        assert(
          maxDisplayedItemCount > 1,
          'maxDisplayedItemCount must be greater than 1',
        ),
        assert(
          outermostCardHeightFactor +
                  (maxDisplayedItemCount - 1) * itemGapHeightFactor <=
              1,
          'Not enough space. The total height of outermost card and gaps must '
          'be lower than 1',
        ),
        super(key: key);

  /// A list of [T] items which used to render cards.
  final List<T> items;

  /// A function which provides build context, current item & rendered size for
  /// building widgets.
  final SizedWidgetBuilder<T> cardBuilder;

  /// Define carousel behavior. See [CarouselBehavior].
  final CarouselBehavior behavior;

  /// A widget builder which helps you customize outermost card.
  final WrapperBuilder? outermostCardWrapper;

  /// A widget builder which helps you customize inner cards.
  final WrapperBuilder? innerCardsWrapper;

  /// Notify card discarded callback. It provides discarded item and discarded
  /// quarter direction
  final CardSwipedCallback<T>? cardSwipedCallback;

  /// Config fixed card aspect widget / height ratio. By default, card's aspect ratio equals to
  /// view size width / height
  final double? cardAspectRatio;

  /// An optional [StackedListController] to provide, helpful for access current
  /// carousel state
  final StackedListController<T>? controller;

  /// The widget builder function that build empty widget, when there is no card
  /// left in carousel. In consume behavior, this function is required.
  final WidgetBuilder? emptyBuilder;

  /// See [StackedListAxisAlignment]
  final StackedListAxisAlignment alignment;

  /// The height factor of outermost card relative to view size. Must be lower
  /// than 1.
  final double outermostCardHeightFactor;

  /// The cards transition duration.
  final Duration animationDuration;

  /// Customized transition curves.
  final Curve transitionCurve;

  /// Limit max amount of displayed cards inside carousel.
  final int maxDisplayedItemCount;

  /// The gap between cards relatives to height factor.
  final double itemGapHeightFactor;

  /// The auto slide duration, which only works in loop mode.
  final Duration autoSlideDuration;

  /// The outermost card flying away animation duration.
  final Duration outermostCardAnimationDuration;

  @override
  State<StackedListCarousel<T>> createState() => _StackedListCarouselState();
}

class _StackedListCarouselState<T> extends State<StackedListCarousel<T>>
    with TickerProviderStateMixin {
  late final StackedListController<T> controller;

  late int reorderCardsCount;

  late int maxDisplayedItemCount;

  late double itemGapHeightFactor;

  double? cardAspectRatio;

  List<Widget?> cards = List.empty(growable: true);

  List<double> cardsMargin = [];
  List<double> cardsSizeFactors = [];

  List<Animation<double>> marginAnimations = [];
  List<Animation<double>> sizeFactorAnimations = [];

  late Animation<double> innermostCardMarginAnimation;

  Size viewSize = Size.zero;

  bool get hasInnerWrapper => widget.innerCardsWrapper != null;
  bool get hasOutermostWrapper => widget.outermostCardWrapper != null;

  @override
  void initState() {
    super.initState();

    controller = (widget.controller ?? StackedListController<T>())
      ..items = widget.items
      ..transitionController = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      )
      ..outermostCardAnimationController = AnimationController(
        duration: widget.outermostCardAnimationDuration,
        vsync: this,
      )
      ..carouselBehavior = widget.behavior
      ..onAnimating = (behavior) {
        if (behavior == CarouselBehavior.consume) {
          cards[controller.realOutermostIndex] = null;
        }
        appendCard(context, viewSize);

        controller.transitionController
          ..stop()
          ..value = 0.0
          ..forward();
      }
      ..onCardSwiped = widget.cardSwipedCallback
      ..autoSlideDuration = widget.autoSlideDuration;

    controller.transitionController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          controller.swapCount++;
          setState(() {});
        }
      },
    );

    controller.registerOutermostCardAnimationListener();

    cardAspectRatio ??= widget.cardAspectRatio;

    maxDisplayedItemCount = min(
      controller.itemCount,
      widget.maxDisplayedItemCount,
    );

    updateAnimations(
      itemCount: controller.itemCount,
      initial: true,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        controller.startTransitionLoop();
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void appendCard(
    BuildContext context,
    Size size,
  ) {
    if (cards.length < controller.itemCount) {
      cards.add(_indexedCard(context, cards.length));
    }
  }

  void updateAnimations({
    required int itemCount,
    bool initial = false,
  }) {
    if (itemCount == controller.itemCount && !initial) return;

    maxDisplayedItemCount = min(
      itemCount,
      widget.maxDisplayedItemCount,
    );

    itemGapHeightFactor = min(
      widget.itemGapHeightFactor,
      (1 - widget.outermostCardHeightFactor) / (maxDisplayedItemCount - 1),
    );

    reorderCardsCount = maxDisplayedItemCount - 1;

    final freeHeightFactor = 1 -
        (widget.outermostCardHeightFactor +
            (maxDisplayedItemCount - 1) * itemGapHeightFactor);

    cardsMargin
      ..clear()
      ..addAll(
        List.generate(
          maxDisplayedItemCount,
          (index) => freeHeightFactor / 2 + (itemGapHeightFactor * index),
        ),
      );

    cardsSizeFactors
      ..clear()
      ..addAll(
        List.generate(
          maxDisplayedItemCount,
          (index) =>
              widget.outermostCardHeightFactor -
              widget.itemGapHeightFactor * (maxDisplayedItemCount - index - 1),
        ),
      );

    marginAnimations
      ..clear()
      ..addAll(
        List.generate(
          reorderCardsCount,
          (index) => Tween<double>(
            begin: cardsMargin[index],
            end: cardsMargin[index + 1],
          ).animate(
            CurvedAnimation(
              parent: controller.transitionController,
              curve: Interval(
                0.1 / (maxDisplayedItemCount - index),
                0.9 / (maxDisplayedItemCount - index),
                curve: widget.transitionCurve,
              ),
            ),
          ),
        ),
      );

    sizeFactorAnimations
      ..clear()
      ..addAll(
        List.generate(
          reorderCardsCount,
          (index) => Tween<double>(
            begin: cardsSizeFactors[index],
            end: cardsSizeFactors[index + 1],
          ).animate(
            CurvedAnimation(
              parent: controller.transitionController,
              curve: Interval(
                0.1 / (maxDisplayedItemCount - index),
                0.9 / (maxDisplayedItemCount - index),
                curve: widget.transitionCurve,
              ),
            ),
          ),
        ),
      );

    if (itemCount > 1) {
      innermostCardMarginAnimation = Tween<double>(
        begin: cardsMargin[1],
        end: cardsMargin[0],
      ).animate(
        CurvedAnimation(
          parent: controller.transitionController,
          curve: Interval(0.1, 0.9, curve: widget.transitionCurve),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        final size = Size(constraint.maxWidth, constraint.maxHeight);

        cardAspectRatio ??= size.width / size.height;

        if (cards.isEmpty || size != viewSize) {
          viewSize = size;
          cards
            ..clear()
            ..addAll(
              List.generate(
                min(
                  maxDisplayedItemCount + 1 + controller.swapCount,
                  controller.itemCount,
                ),
                (index) => Container(
                  child: _indexedCard(
                    context,
                    (index + controller.realOutermostIndex) %
                        controller.itemCount,
                  ),
                ),
              ),
            );
        }

        final scaleAlignment = widget.alignment.isTop
            ? Alignment.bottomCenter
            : Alignment.topCenter;

        return SizedBox.fromSize(
          size: viewSize,
          child: controller.consumedAll
              ? widget.emptyBuilder!.call(context)
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Build innermost (placeholder) card.
                    if (controller.itemCount > 2)
                      _innermostCard(size, scaleAlignment),
                    // Build reorder-able cards list.
                    ...List.generate(
                      reorderCardsCount,
                      (i) => _innerCard(i, size, scaleAlignment),
                    ),
                    // Build outermost card.
                    _outermostCard(size, scaleAlignment),
                  ],
                ),
        );
      },
    );
  }

  Widget _innermostCard(
    Size size,
    Alignment scaleAlignment,
  ) {
    final child = cards[(reorderCardsCount + controller.swapCount + 1) %
            controller.itemCount] ??
        const SizedBox.shrink();

    return AnimatedBuilder(
      animation: innermostCardMarginAnimation,
      builder: (context, child) => _alignPositioned(
        margin: (controller.transitionForwarding
                ? innermostCardMarginAnimation.value
                : cardsMargin.first) *
            size.height,
        child: Transform.scale(
          scale: cardsSizeFactors.first,
          alignment: scaleAlignment,
          child: child,
        ),
      ),
      child: hasInnerWrapper ? widget.innerCardsWrapper!.call(child) : child,
    );
  }

  Widget _innerCard(
    int i,
    Size size,
    Alignment scaleAlignment,
  ) {
    final child = cards[(reorderCardsCount - i + controller.swapCount) %
            controller.itemCount] ??
        const SizedBox.shrink();

    return AnimatedBuilder(
      animation: marginAnimations[i],
      builder: (context, _) => _alignPositioned(
        margin: (controller.transitionForwarding
                ? marginAnimations[i].value
                : cardsMargin[i]) *
            size.height,
        child: Transform.scale(
          scale: controller.transitionForwarding
              ? sizeFactorAnimations[i].value
              : cardsSizeFactors[i],
          alignment: scaleAlignment,
          child: hasInnerWrapper
              ? ((i == reorderCardsCount - 1 && controller.transitionForwarding)
                  ? hasOutermostWrapper
                      ? widget.outermostCardWrapper!.call(child)
                      : child
                  : widget.innerCardsWrapper!.call(child))
              : child,
        ),
      ),
    );
  }

  Widget _outermostCard(
    Size size,
    Alignment scaleAlignment,
  ) {
    final child =
        cards[controller.realOutermostIndex] ?? const SizedBox.shrink();

    return _alignPositioned(
      margin: cardsMargin.last * size.height,
      child: ValueListenableBuilder<Offset>(
        valueListenable: controller.outermostCardOffset,
        builder: (context, offset, child) {
          return Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: offset.dx / MediaQuery.of(context).size.width / 2,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onPanStart: controller.handleDragStart,
          onPanUpdate: controller.handleDragUpdate,
          onPanEnd: (details) => controller.handleDragEnd(
            details,
            viewSize.width,
            MediaQuery.of(context).size.width,
          ),
          child: AnimatedBuilder(
            animation: controller.transitionController,
            builder: (context, _) => Transform.scale(
              scale: cardsSizeFactors.last,
              alignment: scaleAlignment,
              child: Visibility(
                visible: !controller.transitionForwarding,
                child: hasOutermostWrapper
                    ? widget.outermostCardWrapper!.call(
                        child,
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _indexedCard(
    BuildContext context,
    int index,
  ) {
    final cardSize = aspectSize.call(
      height: viewSize.height,
      width: viewSize.width,
      aspectRatio: cardAspectRatio!,
    );

    return SizedBox.fromSize(
      size: cardSize,
      child: widget.cardBuilder.call(
        context,
        controller.items[index],
        cardSize,
      ),
    );
  }

  Widget _alignPositioned({
    required double margin,
    required Widget? child,
  }) =>
      Positioned(
        top: !widget.alignment.isTop ? margin : null,
        bottom: widget.alignment.isTop ? margin : null,
        child: child ?? const SizedBox.shrink(),
      );
}
