import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'debug.dart';
import 'parser.dart';
import 'path_order.dart';
import 'types.dart';

class PaintedPainter extends PathPainter {
  PaintedPainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions);

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      for (var segment in pathSegments) {
        Paint paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint()
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
      }
    }
  }
}

class AllAtOncePainter extends PathPainter {
  AllAtOncePainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions);

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      for (var segment in pathSegments) {
        Path subPath = segment.path
            .computeMetrics()
            .first
            .extractPath(0, segment.length * animation.value);

        Paint paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint()
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(subPath, paint);
      }

      super.onFinish(canvas, size);
    }
  }
}

class OneByOnePainter extends PathPainter {
  OneByOnePainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : totalPathSum = 0,
        super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions) {
    for (var e in this.pathSegments) {
      totalPathSum += e.length;
    }
  }

  double totalPathSum;

  int paintedSegmentIndex = 0;

  double _paintedLength = 0.0;

  List<PathSegment> toPaint = [];

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);

    if (canPaint) {
      double upperBound = animation.value * totalPathSum;
      int currentIndex = paintedSegmentIndex;
      double currentLength = _paintedLength;
      while (currentIndex < pathSegments.length - 1) {
        if (currentLength + pathSegments[currentIndex].length < upperBound) {
          toPaint.add(pathSegments[currentIndex]);
          currentLength += pathSegments[currentIndex].length;
          currentIndex++;
        } else {
          break;
        }
      }

      double subPathLength = upperBound - currentLength;
      PathSegment lastPathSegment = pathSegments[currentIndex];

      Path subPath = lastPathSegment.path
          .computeMetrics()
          .first
          .extractPath(0, subPathLength);
      paintedSegmentIndex = currentIndex;
      _paintedLength = currentLength;

      Paint paint;
      Path tmp = Path();
      if (animation.value == 1.0) {
        toPaint.clear();
        toPaint.addAll(pathSegments);
      } else {
        tmp = Path.from(lastPathSegment.path);
        lastPathSegment.path = subPath;
        toPaint.add(lastPathSegment);
      }

      for (var segment in (toPaint
        ..sort(Extractor.getComparator(PathOrders.original)))) {
        paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint()
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
      }

      if (animation.value != 1.0) {
        toPaint.remove(lastPathSegment);
        lastPathSegment.path = tmp;
      }

      super.onFinish(canvas, size, lastPainted: toPaint.length - 1);
    } else {
      paintedSegmentIndex = 0;
      _paintedLength = 0.0;
      toPaint.clear();
    }
  }
}

abstract class PathPainter extends CustomPainter {
  PathPainter(
      this.animation,
      this.pathSegments,
      this.customDimensions,
      this.paints,
      this.onFinishCallback,
      this.scaleToViewport,
      this.debugOptions)
      : recorder = ui.PictureRecorder(),
        canPaint = false,
        pathBoundingBox = const Offset(1.0, 1.0) & const Size(1, 1),
        super(repaint: animation) {
    calculateBoundingBox();
  }

  Rect pathBoundingBox;

  double? strokeWidth;

  Size customDimensions;
  final Animation<double> animation;

  List<PathSegment> pathSegments;

  List<Paint> paints;

  bool canPaint;

  bool scaleToViewport;

  PaintedSegmentCallback onFinishCallback;

  DebugOptions debugOptions;
  ui.PictureRecorder recorder;

  void calculateBoundingBox() {
    Rect bb = pathSegments.first.path.getBounds();
    double strokeWidth = 0;

    for (var e in pathSegments) {
      bb = bb.expandToInclude(e.path.getBounds());
      if (strokeWidth < e.strokeWidth) {
        strokeWidth = e.strokeWidth;
      }
    }

    if (paints.isNotEmpty) {
      for (var e in paints) {
        if (strokeWidth < e.strokeWidth) {
          strokeWidth = e.strokeWidth;
        }
      }
    }
    pathBoundingBox = bb.inflate(strokeWidth / 2);
    this.strokeWidth = strokeWidth;
  }

  void onFinish(Canvas canvas, Size size, {int lastPainted = -1}) {
    if (debugOptions.recordFrames) {
      final ui.Picture picture = recorder.endRecording();
      int frame = getFrameCount(debugOptions);
      if (frame >= 0) {
        debugPrint("Write frame $frame");

        writeToFile(
            picture,
            "${debugOptions.outPutDir}/${debugOptions.fileName}_$frame.png",
            size);
      }
    }
    onFinishCallback(lastPainted);
  }

  Canvas paintOrDebug(Canvas canvas, Size size) {
    if (debugOptions.recordFrames) {
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder);

      canvas.scale(
          debugOptions.resolutionFactor, debugOptions.resolutionFactor);
    }
    paintPrepare(canvas, size);
    return canvas;
  }

  void paintPrepare(Canvas canvas, Size size) {
    canPaint = animation.status == AnimationStatus.forward ||
        animation.status == AnimationStatus.completed;

    if (canPaint) viewBoxToCanvas(canvas, size);
  }

  Future<void> writePicturetoFile(
      ui.Picture picture, String fn, Size sz) async {
    _ScaleFactor scaleFactor = calculateScaleFactor(sz);
    final byteData = await picture.toImage(
        (scaleFactor.x *
                debugOptions.resolutionFactor *
                (pathBoundingBox.width))
            .round(),
        (scaleFactor.y *
                debugOptions.resolutionFactor *
                (pathBoundingBox.height))
            .round());
    final pngBytes = await byteData.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes != null) {
      final buffer = pngBytes.buffer;
      await File(fn).writeAsBytes(
          buffer.asUint8List(pngBytes.offsetInBytes, pngBytes.lengthInBytes));
      debugPrint("File: $fn written.");
    }
  }

  Future<void> writeToFile(
      ui.Picture picture, String fileName, Size size) async {
    _ScaleFactor scale = calculateScaleFactor(size);
    final byteData = await ((await picture.toImage(
            (scale.x * debugOptions.resolutionFactor * (pathBoundingBox.width))
                .round(),
            (scale.y * debugOptions.resolutionFactor * pathBoundingBox.height)
                .round()))
        .toByteData(format: ui.ImageByteFormat.png));
    final buffer = byteData?.buffer;
    if (buffer != null && byteData != null) {
      await File(fileName).writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      debugPrint("File: $fileName written.");
    }
  }

  _ScaleFactor calculateScaleFactor(Size viewBox) {
    double dx = (viewBox.width) / pathBoundingBox.width;
    double dy = (viewBox.height) / pathBoundingBox.height;

    double ddx = 0.0, ddy = 0.0;

    if (!viewBox.isEmpty) {
      if (customDimensions != null) {
        ddx = dx;
        ddy = dy;
      } else {
        ddx = ddy = min(dx, dy);
      }
    } else if (dx == 0) {
      ddx = ddy = dy;
    } else if (dy == 0) {
      ddx = ddy = dx;
    }
    return _ScaleFactor(ddx, ddy);
  }

  void viewBoxToCanvas(Canvas canvas, Size size) {
    if (debugOptions.showViewPort) {
      Rect clipRect1 = Offset.zero & size;
      Paint ppp = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.green
        ..strokeWidth = 10.50;
      canvas.drawRect(clipRect1, ppp);
    }

    if (scaleToViewport) {
      Size viewBox;
      if ((customDimensions != null)) {
        viewBox = customDimensions;
      } else {
        viewBox = Size.copy(size);
      }
      _ScaleFactor scale = calculateScaleFactor(viewBox);
      canvas.scale(scale.x, scale.y);

      Offset offset = Offset.zero - pathBoundingBox.topLeft;
      canvas.translate(offset.dx, offset.dy);

      if (debugOptions.recordFrames != true) {
        Offset center = Offset(
            (size.width / scale.x - pathBoundingBox.width) / 2,
            (size.height / scale.y - pathBoundingBox.height) / 2);
        canvas.translate(center.dx, center.dy);
      }
    }

    Rect clipRect = pathBoundingBox;
    if (!(debugOptions.showBoundingBox || debugOptions.showViewPort)) {
      canvas.clipRect(clipRect);
    }

    if (debugOptions.showBoundingBox) {
      Paint pp = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.red
        ..strokeWidth = 0.500;
      canvas.drawRect(clipRect, pp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ScaleFactor {
  const _ScaleFactor(this.x, this.y);
  final double x;
  final double y;
}
