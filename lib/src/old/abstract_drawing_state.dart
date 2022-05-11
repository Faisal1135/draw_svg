import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'debug.dart';
import 'drawing_widget.dart';
import 'line_animation.dart';
import 'painter.dart';
import 'parser.dart';
import 'path_order.dart';
import 'path_painter_builder.dart';
import 'range.dart';

void voidCall() {}

abstract class AbstractAnimatedDrawingState extends State<DrawAnimation> {
  AbstractAnimatedDrawingState()
      : debug = DebugOptions(),
        assetPath = "",
        animationOrder = PathOrders.original,
        onFinishAnimation = voidCall;

  AnimationController? controller;
  CurvedAnimation? curve;

  Curve? animationCurve;
  AnimationRange? range;
  String assetPath;
  PathOrder animationOrder;
  DebugOptions debug;
  int lastPaintedPathIndex = -1;

  List<PathSegment> pathSegments = <PathSegment>[];
  List<PathSegment> pathSegmentsToAnimate = <PathSegment>[];
  List<PathSegment> pathSegmentsToPaintAsBackground = <PathSegment>[];

  VoidCallback onFinishAnimation;

  bool onFinishEvoked = false;

  void onFinishAnimationDefault() {
    if (widget.onFinish != null) {
      widget.onFinish!();
    }
    if (debug.recordFrames) resetFrame(debug);
  }

  void onFinishFrame(int currentPaintedPathIndex) {
    if (newPathPainted(currentPaintedPathIndex)) {
      evokeOnPaintForNewlyPaintedPaths(currentPaintedPathIndex);
    }
    if (controller != null && controller!.status == AnimationStatus.completed) {
      onFinishAnimation();
    }
  }

  void evokeOnPaintForNewlyPaintedPaths(int currentPaintedPathIndex) {
    final int paintedPaths =
        pathSegments[currentPaintedPathIndex].pathIndex - lastPaintedPathIndex;
    for (int i = lastPaintedPathIndex + 1;
        i <= lastPaintedPathIndex + paintedPaths;
        i++) {
      evokeOnPaintForPath(i);
    }
    lastPaintedPathIndex = currentPaintedPathIndex;
  }

  void evokeOnPaintForPath(int i) {
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        if (widget.onPaint != null) {
          widget.onPaint!(i, widget.paths[i]);
        }
      });
    });
  }

  bool newPathPainted(int currentPaintedPathIndex) {
    return currentPaintedPathIndex != -1 &&
        pathSegments[currentPaintedPathIndex].pathIndex - lastPaintedPathIndex >
            0;
  }

  @override
  void didUpdateWidget(DrawAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (animationOrder != widget.animationOrder) {
      applyPathOrder();
    }
  }

  @override
  void initState() {
    super.initState();
    updatePathData();
    applyAnimationCurve();
    applyDebugOptions();
  }

  void applyDebugOptions() {
    if (widget.debug != null) {
      debug = widget.debug!;
      debug;
    }
  }

  void applyAnimationCurve() {
    animationCurve = widget.animationCurve;
  }

  Animation<double> getAnimation() {
    Animation<double> animation;
    if (!widget.run) {
      animation = controller!;
    } else if (animationCurve == widget.animationCurve && curve != null) {
      animation = curve!;
    } else if (controller != null) {
      curve =
          CurvedAnimation(parent: controller!, curve: widget.animationCurve);
      animationCurve = widget.animationCurve;
      animation = curve!;
    } else {
      animation = controller!;
    }
    return animation;
  }

  void applyPathOrder() {
    if (pathSegments.isEmpty) return;

    setState(() {
      if (checkIfDefaultOrderSortingRequired()) {
        pathSegments.sort(Extractor.getComparator(PathOrders.original));
        animationOrder = PathOrders.original;
        return;
      }

      if (widget.animationOrder != animationOrder) {
        pathSegments.sort(Extractor.getComparator(widget.animationOrder));
        animationOrder = widget.animationOrder;
      }
    });
  }

  PathPainter? buildForegroundPainter() {
    if (pathSegmentsToAnimate.isEmpty) return null;
    PathPainterBuilder builder = preparePaintBudler(widget.lineAnimation);
    return builder.copyWith(pathSegments: pathSegmentsToAnimate).build();
  }

  PathPainter? buildBackgroundPainter() {
    if (pathSegmentsToPaintAsBackground.isEmpty) return null;
    PathPainterBuilder builder = preparePaintBudler();
    return builder
        .copyWith(pathSegments: pathSegmentsToPaintAsBackground)
        .build();
  }

  PathPainterBuilder preparePaintBudler([LineAnimation? lineAnimation]) {
    return PathPainterBuilder(
        lineAnimation: lineAnimation ?? widget.lineAnimation,
        animation: getAnimation(),
        customDimensions: getCustomDimensions(),
        paints: widget.paints,
        onFinishFrame: onFinishFrame,
        scaleToViewport: widget.scaleToViewport,
        debugOptions: debug,
        pathSegments: []);
  }

  void assignPathSegmentsToPainters() {
    if (pathSegments.isEmpty) return;

    if (widget.range == null) {
      pathSegmentsToAnimate = pathSegments;
      range = null;
      pathSegmentsToPaintAsBackground.clear();
      return;
    }

    if (widget.range != range) {
      checkValidRange();

      pathSegmentsToPaintAsBackground =
          pathSegments.where((x) => x.pathIndex < widget.range!.start).toList();

      pathSegmentsToAnimate = pathSegments
          .where((x) => (x.pathIndex >= widget.range!.start &&
              x.pathIndex <= widget.range!.end))
          .toList();

      range = widget.range;
    }
  }

  void checkValidRange() {
    RangeError.checkValidRange(
        widget.range!.start,
        widget.range!.end,
        widget.paths.length - 1,
        "start",
        "end",
        "The provided range is invalid for the provided number of paths.");
  }

  Size getCustomDimensions() {
    if (widget.height != null || widget.width != null) {
      return Size(
        (widget.width != null) ? widget.width! : 0,
        (widget.height != null) ? widget.height! : 0,
      );
    } else {
      return const Size(0, 0);
    }
  }

  CustomPaint createCustomPaint(BuildContext context) {
    updatePathData();
    return CustomPaint(
        foregroundPainter: buildForegroundPainter(),
        painter: buildBackgroundPainter(),
        size: Size.copy(MediaQuery.of(context).size));
  }

  void addListenersToAnimationController() {
    if (debug.recordFrames && controller != null) {
      controller!.view.addListener(() {
        setState(() {
          if (controller!.status == AnimationStatus.forward) {
            iterateFrame(debug);
          }
        });
      });
    }

    controller!.view.addListener(() {
      setState(() {
        if (controller!.status == AnimationStatus.dismissed) {
          lastPaintedPathIndex = -1;
        }
      });
    });
  }

  void updatePathData() {
    parsePathData();
    applyPathOrder();
    assignPathSegmentsToPainters();
  }

  void parsePathData() {
    SvgParser parser = SvgParser();
    if (svgAssetProvided()) {
      if (widget.assetPath == assetPath) return;

      parseFromSvgAsset(parser);
    } else if (pathsProvided()) {
      parseFromPaths(parser);
    }
  }

  void parseFromPaths(SvgParser parser) {
    parser.loadFromPaths(widget.paths);
    setState(() {
      pathSegments = parser.getPathSegments();
    });
  }

  bool pathsProvided() => widget.paths.isNotEmpty;

  bool svgAssetProvided() => widget.assetPath.isNotEmpty;

  void parseFromSvgAsset(SvgParser parser) {
    parser.loadFromFile(widget.assetPath).then((_) {
      setState(() {
        widget.paths.clear();
        widget.paths.addAll(parser.getPaths());

        pathSegments = parser.getPathSegments();
        assetPath = widget.assetPath;
      });
    });
  }

  bool checkIfDefaultOrderSortingRequired() {
    final bool defaultSortingWhenNoOrderDefined =
        widget.lineAnimation == LineAnimation.allAtOnce &&
            animationOrder != PathOrders.original;
    return defaultSortingWhenNoOrderDefined;
  }
}
