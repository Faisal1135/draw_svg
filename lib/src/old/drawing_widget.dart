import 'package:flutter/material.dart';

import 'abstract_drawing_state.dart';
import 'debug.dart';
import 'drawing_state_with_ticker.dart';
import 'line_animation.dart';
import 'path_order.dart';
import 'range.dart';

typedef PaintedPathCallback = void Function(int, Path);
const defaultDuration = Duration(seconds: 2);
void voidFn() {
  debugPrint("Animation Finished Finished");
}

class DrawAnimation extends StatefulWidget {
  DrawAnimation.svg(
    this.assetPath, {
    Key? key,
    this.controller,
    this.run = true,
    this.duration = defaultDuration,
    this.onFinish = voidFn,
    this.onPaint,
    required this.width,
    required this.height,
    this.range,
    this.lineAnimation = LineAnimation.oneByOne,
    this.scaleToViewport = true,
    this.debug,
  })  : paths = [],
        animationCurve = Curves.easeInOut,
        animationOrder = PathOrders.original,
        paints = [],
        super(key: key) {
    assertAnimationParameters();
    assert(assetPath.isNotEmpty);
  }

  DrawAnimation.paths(
    this.paths, {
    Key? key,
    this.paints = const <Paint>[],
    this.controller,
    this.run = true,
    this.duration = defaultDuration,
    this.onFinish,
    this.onPaint,
    this.width,
    this.height,
    this.range,
    this.lineAnimation = LineAnimation.oneByOne,
    this.scaleToViewport = true,
    this.debug,
  })  : assetPath = '',
        animationCurve = Curves.easeInOut,
        animationOrder = PathOrders.original,
        super(key: key) {
    assertAnimationParameters();
    assert(paths.isNotEmpty);
    if (paints.isNotEmpty) assert(paints.length == paths.length);
  }

  final String assetPath;

  final List<Path> paths;

  final List<Paint> paints;

  final AnimationController? controller;

  final Curve animationCurve;

  final VoidCallback? onFinish;

  final PaintedPathCallback? onPaint;

  PathOrder animationOrder;

  final bool run;

  final Duration duration;

  final double? width;

  final double? height;

  final AnimationRange? range;

  final LineAnimation lineAnimation;

  final bool scaleToViewport;

  final DebugOptions? debug;

  @override
  AbstractAnimatedDrawingState createState() {
    return AnimatedDrawingWithTickerState();
  }

  void assertAnimationParameters() {
    assert(!(controller == null && (duration == null)));
  }
}
