/// Determine outermost card animation behavior
/// * [flyAway] : the outermost card is discarded.
/// * [comeBack] : the outermost is card brought back to the original position.
enum OutermostCardBehavior {
  flyAway,
  comeBack,
}

/// Define the way carousel arranges its children.
///
/// If alignment is [top], the outermost card will be align in the top most
/// position. Similar with [bottom].
///
enum StackedListAxisAlignment {
  top,
  bottom,
}

/// Determines card's swipe quarter direction, converted from card's drag
/// offset.
enum SwipeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Define what happens when user discards cards.
///
/// In [loop] mode, items will not disappear after being discarded. Instead,
/// it'll be moved to the bottom of the list.
///
/// In [consume] mode, items will be removed from cards after being discard.
/// When all cards has been consumed, an empty placeholder will take place.
///
enum CarouselBehavior {
  loop,
  consume,
}
