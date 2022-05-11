import 'package:flutter/painting.dart';

import 'parser.dart';

class PathOrder {
  PathOrder.byLength({reverse = false})
      : _comparator = _byLength(reverse: reverse);

  PathOrder.byPosition({required AxisDirection direction})
      : _comparator = _byPosition(direction: direction);

  PathOrder._(this._comparator);

  PathOrder._original() : _comparator = __original();

  final Comparator<PathSegment> _comparator;

  Comparator<PathSegment> _getComparator() {
    return _comparator;
  }

  static Comparator<PathSegment> _byLength({reverse = false}) {
    return (reverse)
        ? (PathSegment a, PathSegment b) {
            return a.length.compareTo(b.length);
          }
        : (PathSegment a, PathSegment b) {
            return b.length.compareTo(a.length);
          };
  }

  static Comparator<PathSegment> _byPosition(
      {required AxisDirection direction}) {
    switch (direction) {
      case AxisDirection.left:
        return (PathSegment a, PathSegment b) {
          return b.path
              .getBounds()
              .center
              .dx
              .compareTo(a.path.getBounds().center.dx);
        };
      case AxisDirection.right:
        return (PathSegment a, PathSegment b) {
          return a.path
              .getBounds()
              .center
              .dx
              .compareTo(b.path.getBounds().center.dx);
        };
      case AxisDirection.up:
        return (PathSegment a, PathSegment b) {
          return b.path
              .getBounds()
              .center
              .dy
              .compareTo(a.path.getBounds().center.dy);
        };
      case AxisDirection.down:
        return (PathSegment a, PathSegment b) {
          return a.path
              .getBounds()
              .center
              .dy
              .compareTo(b.path.getBounds().center.dy);
        };
      default:
        return PathOrder._original()._getComparator();
    }
  }

  static Comparator<PathSegment> __original() {
    return (PathSegment a, PathSegment b) {
      int comp = a.firstSegmentOfPathIndex.compareTo(b.firstSegmentOfPathIndex);
      if (comp == 0) comp = a.relativeIndex.compareTo(b.relativeIndex);
      return comp;
    };
  }

  PathOrder combine(PathOrder secondPathOrder) {
    return PathOrder._((PathSegment a, PathSegment b) {
      int comp = _comparator(a, b);
      if (comp == 0) comp = secondPathOrder._comparator(a, b);
      return comp;
    });
  }
}

class PathOrders {
  static PathOrder original = PathOrder._original();

  static PathOrder leftToRight =
      PathOrder.byPosition(direction: AxisDirection.right);

  static PathOrder rightToLeft =
      PathOrder.byPosition(direction: AxisDirection.left);

  static PathOrder topToBottom =
      PathOrder.byPosition(direction: AxisDirection.down);

  static PathOrder bottomToTop =
      PathOrder.byPosition(direction: AxisDirection.up);

  static PathOrder increasingLength = PathOrder.byLength(reverse: true);

  static PathOrder decreasingLength = PathOrder.byLength();
}

class Extractor {
  static Comparator<PathSegment> getComparator(PathOrder pathOrder) {
    return pathOrder._getComparator();
  }
}
