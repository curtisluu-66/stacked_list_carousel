library stacked_list_carousel;

import 'dart:math';
import 'package:flutter/material.dart';
import 'src/controller/stacked_list_controller.dart';

typedef ItemBuilder = Widget Function(
  BuildContext context,
  Size size,
  int index,
  bool isOutermostCard,
);

/// A widget that layout its stacked-like children vertically, which behaves like a carousel.
///
/// Most suitable with in-app banners UI use cases.
class StackedListCarousel<T> extends StatefulWidget {
  /// List of card models.
  final List<T> items;

  /// The build method that generates card widget, which includes 4 params:
  /// * BuildContext: current build context of stacked card carousel.
  /// * Size: the actual space that the widget card takes up.
  /// * int: the actual index of built item inside [items] list.
  /// * bool: whether built item is the outermost card of the carousel at present.
  final ItemBuilder itemBuilder;

  /// The relative height of whole stacked card carousel to the height.
  /// of the entire view, calculated by the formula:
  ///
  /// [viewSizeHeightFactor] = actualCarouselHeight / viewSize.
  final double viewSizeHeightFactor;

  /// The relative height of the outermost card to the height
  /// of the entire view, calculated by the formula:
  ///
  /// [outermostCardHeightFactor] = outermostCardHeight / viewSize.
  final double outermostCardHeightFactor;

  /// Fixed display length / width ratio for each card. If null, displayed
  /// cards will have default size base to layout size.
  final double? cardAspectRatio;

  /// The maximum number of cards displayed on the carousel. Defaults to 3
  final int maxDisplayedItemsCount;

  /// Duration between automatic card transitions. Defaults to 8 seconds.
  final Duration autoSlideDuration;

  /// Duration of card transitions effect. Defaults to 200 milliseconds.
  final Duration transitionDuration;

  /// Duration of outermost card fly effect. Defaults to 250 milliseconds.
  final Duration outermostTransitionDuration;

  /// Callback function to notify latest discarded card index and its swipe direction
  /// whenever a transitions completed with user gesture.
  final SwipeNotify? onItemDiscarded;

  /// Callback function to notify outermost card index whenever a transitions completed.
  final Function(int outermostIndex)? onOutermostIndexChanged;

  const StackedListCarousel({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.viewSizeHeightFactor = 1.0,
    this.outermostCardHeightFactor = 0.8,
    this.cardAspectRatio,
    this.maxDisplayedItemsCount = 3,
    this.autoSlideDuration = const Duration(seconds: 8),
    this.transitionDuration = const Duration(milliseconds: 200),
    this.outermostTransitionDuration = const Duration(milliseconds: 450),
    this.onItemDiscarded,
    this.onOutermostIndexChanged,
  })  : assert(
          viewSizeHeightFactor > 0 && viewSizeHeightFactor <= 1,
          'view size height factor must be in range (0.0...1.0]',
        ),
        assert(
          outermostCardHeightFactor > 0 && outermostCardHeightFactor < 1,
          'outermost card height factor must be in range (0.0...1.0)',
        ),
        assert(
          outermostCardHeightFactor < viewSizeHeightFactor,
          'outermostCardHeightFactor must not be greater than viewSizeHeightFactor',
        ),
        super(key: key);

  @override
  State<StackedListCarousel> createState() => _StackedListCarouselState();
}

class _StackedListCarouselState extends State<StackedListCarousel>
    with TickerProviderStateMixin {
  late final StackedListController controller;

  /// The height gap factor relative to view size between each card.
  late final double itemGapFactor;

  Size? viewSize;

  @override
  void initState() {
    controller = StackedListController(
      maxDisplayedItemsCount: min(
        widget.items.length,
        widget.maxDisplayedItemsCount,
      ),
      itemsCount: widget.items.length,
      transitionDuration: widget.transitionDuration,
      outermostTransitionDuration: widget.outermostTransitionDuration,
      autoSlideDuration: widget.autoSlideDuration,
      onItemDiscarded: widget.onItemDiscarded,
      onOutermostIndexChanged: (index) {
        setState(() {});
        widget.onOutermostIndexChanged?.call(index);
      },
      vsync: this,
    );

    itemGapFactor =
        (widget.viewSizeHeightFactor - widget.outermostCardHeightFactor) /
            (controller.maxDisplayedItemsCount + 1);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
        Duration.zero,
        () {
          /// After get view size for the first time, do initialize widgets.
          if (controller.maxDisplayedItemsCount > 1) {
            controller.setCards(
              List<Widget>.generate(
                controller.maxDisplayedItemsCount,
                (i) => _buildItem(i),
              ),
            );
          }
        },
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        viewSize ??= Size(
          constraints.maxWidth,
          widget.cardAspectRatio != null
              ? constraints.maxWidth /
                  widget.cardAspectRatio! /
                  widget.outermostCardHeightFactor
              : constraints.maxHeight,
        );
        return widget.items.length == 1
            ? widget.itemBuilder(
                context,
                viewSize!,
                widget.items.first,
                true,
              )
            : Container(
                alignment: Alignment.center,
                constraints: constraints,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: controller.cardWidgets.reversed.toList(),
                ),
              );
      },
    );
  }

  AnimatedBuilder _buildItem(int index) => AnimatedBuilder(
        key: UniqueKey(),
        animation: controller.transitionController,
        builder: (context, child) {
          final Size rawSize = viewSize! *
              (widget.outermostCardHeightFactor +
                  controller.sizeFactors[index] *
                      itemGapFactor *
                      controller.transitionController.value);

          /// Actual displayed size of built banner.
          Size bannerSize = Size(
            rawSize.width,
            widget.cardAspectRatio != null
                ? rawSize.width / widget.cardAspectRatio!
                : rawSize.height,
          );

          return IgnorePointer(
            // Only allows front item to be interact
            ignoring: !(index == controller.outermostCardIndex),
            child: Container(
              margin: EdgeInsets.only(
                top: (viewSize!.height * widget.viewSizeHeightFactor) *
                    itemGapFactor *
                    (controller.sizeFactors[index] +
                        controller.transitionValue),
              ),
              width: bannerSize.width,
              height: bannerSize.height,
              child: index == controller.outermostCardIndex
                  ? ValueListenableBuilder<Offset>(
                      valueListenable: controller.outermostCardOffset,
                      builder: (context, offset, _) => Transform.translate(
                        offset: offset,
                        child: Transform.rotate(
                          angle:
                              offset.dx / MediaQuery.of(context).size.width / 2,
                          child: GestureDetector(
                            onPanStart: controller.handleDragStart,
                            onPanUpdate: controller.handleDragUpdate,
                            onPanEnd: (details) => controller.handleDragEnd(
                              details,
                              viewSize!.width,
                              MediaQuery.of(context).size.width,
                            ),
                            child: SizedBox.fromSize(
                              size: bannerSize,
                              child: widget.itemBuilder.call(
                                context,
                                bannerSize,
                                controller.displayedIndexes[index],
                                (index) == controller.outermostCardIndex,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.fromSize(
                      size: bannerSize,
                      child: widget.itemBuilder.call(
                        context,
                        bannerSize,
                        controller.displayedIndexes[index],
                        (index) == controller.outermostCardIndex,
                      ),
                    ),
            ),
          );
        },
      );
}
