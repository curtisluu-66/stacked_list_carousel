import 'dart:math';
import 'package:flutter/animation.dart';

Size aspectSize({
  required double height,
  required double width,
  required double aspectRatio,
  double scaleFactor = 1,
}) {
  final finalHeight = min(width / aspectRatio, height);

  return Size(
        finalHeight * aspectRatio,
        finalHeight,
      ) *
      scaleFactor;
}
