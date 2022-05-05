import 'package:flutter/material.dart';

import '../../draw_svg.dart';
import '../old/drawing_state_with_ticker.dart';

const defaultDuration = Duration(seconds: 2);
void voidFn() {
  debugPrint("Animation Finished Finished");
}

class DrawSvg extends StatefulWidget {
  const DrawSvg(
    this.svgPath, {
    Key? key,
    this.controller,
    this.activate = true,
    this.duration = defaultDuration,
    this.onFinished = voidFn,
    this.onPaintPath,
    this.height,
    this.width,
    this.lineAnimation = LineAnimation.oneByOne,
  }) : super(key: key);

  final String svgPath;

  final AnimationController? controller;

  final bool activate;

  final Duration duration;
  final VoidCallback onFinished;
  final void Function(int, Path)? onPaintPath;
  final double? height;
  final double? width;
  final LineAnimation lineAnimation;

  @override
  State<DrawAnimation> createState() => AnimatedDrawingWithTickerState();
}
