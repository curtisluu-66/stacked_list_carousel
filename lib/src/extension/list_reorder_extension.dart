extension ListReorderExtension<T> on List<T> {
  /// Remove last item and insert it to the head of list.
  /// E.x: [1,2,3] -> [3,1,2]
  void rotateLTR() => insert(0, removeLast());

  /// Remove first item and insert it to the tail of the list
  /// E.x: [1,2,3] -> [2,3,1]
  void rotateRTL() => add(removeAt(0));
}
