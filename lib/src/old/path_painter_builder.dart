import 'package:flutter/material.dart';

import 'debug.dart';
import 'line_animation.dart';
import 'painter.dart';
import 'parser.dart';

class PathPainterBuilder {
  List<Paint> paints;
  void Function(int currentPaintedPathIndex) onFinishFrame;
  bool scaleToViewport;
  DebugOptions debugOptions;
  List<PathSegment> pathSegments;
  LineAnimation lineAnimation;
  Animation<double> animation;
  Size customDimensions;
  PathPainterBuilder({
    required this.paints,
    required this.onFinishFrame,
    required this.scaleToViewport,
    required this.debugOptions,
    required this.pathSegments,
    required this.lineAnimation,
    required this.animation,
    required this.customDimensions,
  });

  PathPainter build() {
    switch (lineAnimation) {
      case LineAnimation.oneByOne:
        return OneByOnePainter(animation, pathSegments, customDimensions,
            paints, onFinishFrame, scaleToViewport, debugOptions);
      case LineAnimation.allAtOnce:
        return AllAtOncePainter(animation, pathSegments, customDimensions,
            paints, onFinishFrame, scaleToViewport, debugOptions);
      default:
        return PaintedPainter(animation, pathSegments, customDimensions, paints,
            onFinishFrame, scaleToViewport, debugOptions);
    }
  }

  void setAnimation(Animation<double> animation) {
    this.animation = animation;
  }

  void setCustomDimensions(Size customDimensions) {
    this.customDimensions = customDimensions;
  }

  void setPaints(List<Paint> paints) {
    this.paints = paints;
  }

  void setOnFinishFrame(
      void Function(int currentPaintedPathIndex) onFinishFrame) {
    this.onFinishFrame = onFinishFrame;
  }

  void setScaleToViewport(bool scaleToViewport) {
    this.scaleToViewport = scaleToViewport;
  }

  void setDebugOptions(DebugOptions debug) {
    debugOptions = debug;
  }

  void setPathSegments(List<PathSegment> pathSegments) {
    this.pathSegments = pathSegments;
  }

  PathPainterBuilder copyWith({
    List<Paint>? paints,
    void Function(int currentPaintedPathIndex)? onFinishFrame,
    bool? scaleToViewport,
    DebugOptions? debugOptions,
    List<PathSegment>? pathSegments,
    LineAnimation? lineAnimation,
    Animation<double>? animation,
    Size? customDimensions,
  }) {
    return PathPainterBuilder(
      paints: paints ?? this.paints,
      onFinishFrame: onFinishFrame ?? this.onFinishFrame,
      scaleToViewport: scaleToViewport ?? this.scaleToViewport,
      debugOptions: debugOptions ?? this.debugOptions,
      pathSegments: pathSegments ?? this.pathSegments,
      lineAnimation: lineAnimation ?? this.lineAnimation,
      animation: animation ?? this.animation,
      customDimensions: customDimensions ?? this.customDimensions,
    );
  }
}
