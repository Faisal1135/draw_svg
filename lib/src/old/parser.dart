import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart' as xml;

class SvgParser {
  final List<PathSegment> _pathSegments = <PathSegment>[];
  List<Path> _paths = <Path>[];

  Color parseColor(String cStr) {
    if (cStr.isEmpty) {
      throw UnsupportedError("Empty color field found.");
    }
    if (cStr[0] == '#') {
      return Color(int.parse(cStr.substring(1), radix: 16)).withOpacity(1.0);
    } else if (cStr == 'none') {
      return Colors.transparent;
    } else {
      throw UnsupportedError(
          "Only hex color format currently supported. String:  $cStr");
    }
  }

  void addPathSegments(
      Path path, int index, double? strokeWidth, Color? color) {
    int firstPathSegmentIndex = _pathSegments.length;
    int relativeIndex = 0;
    path.computeMetrics().forEach((pp) {
      PathSegment segment = PathSegment()
        ..path = pp.extractPath(0, pp.length)
        ..length = pp.length
        ..firstSegmentOfPathIndex = firstPathSegmentIndex
        ..pathIndex = index
        ..relativeIndex = relativeIndex;

      segment.color = color ?? Colors.black;

      segment.strokeWidth = strokeWidth ?? 0.0;

      _pathSegments.add(segment);
      relativeIndex++;
    });
  }

  void loadFromString(String svgString) {
    _pathSegments.clear();
    int index = 0;
    var doc = xml.XmlDocument.parse(svgString);

    doc
        .findAllElements("path")
        .map((node) => node.attributes)
        .forEach((attributes) {
      var dPath = attributes.firstWhere((attr) => attr.name.local == "d",
          orElse: () => throw UnsupportedError(
              "No d attribute found in path element. Attributes: $attributes"));
      Path path = Path();
      writeSvgPathDataToPath(dPath.value, PathModifier(path));

      Color? color;
      double? strokeWidth;

      try {
        var style = attributes.firstWhere(
          (attr) => attr.name.local == "style",
        );
        RegExp exp = RegExp(r"stroke:([^;]+);");
        var match = exp.firstMatch(style.value);
        String cStr = match?.group(1) ?? "";
        color = parseColor(cStr);

        exp = RegExp(r"stroke-width:([0-9.]+)");
        match = exp.firstMatch(style.value);
        String cStrw = match?.group(1) ?? "";
        strokeWidth = double.tryParse(cStrw) ?? 0.0;

        var strokeElement = attributes.firstWhere(
          (attr) => attr.name.local == "stroke",
        );
        color = parseColor(strokeElement.value);
        var strokeWidthElement = attributes.firstWhere(
          (attr) => attr.name.local == "stroke-width",
        );
        strokeWidth = double.tryParse(strokeWidthElement.value) ?? 0.0;
      } catch (e) {
        debugPrint("Error parsing attributes: $e");
      }

      _paths.add(path);
      addPathSegments(path, index, strokeWidth, color);
      index++;
    });
  }

  void loadFromPaths(List<Path> paths) {
    _pathSegments.clear();
    _paths = paths;

    int index = 0;
    for (var p in paths) {
      addPathSegments(p, index, null, null);
      index++;
    }
  }

  Future<void> loadFromFile(String file) async {
    _pathSegments.clear();
    String svgString = await rootBundle.loadString(file);
    loadFromString(svgString);
  }

  List<PathSegment> getPathSegments() {
    return _pathSegments;
  }

  List<Path> getPaths() {
    return _paths;
  }
}

class PathSegment {
  PathSegment()
      : strokeWidth = 0.0,
        length = 0,
        color = Colors.black,
        firstSegmentOfPathIndex = 0,
        relativeIndex = 0,
        path = Path(),
        pathIndex = 0;

  Path path;
  double strokeWidth;
  Color color;

  double length;

  int firstSegmentOfPathIndex;

  int pathIndex;

  int relativeIndex;
}

class PathModifier extends PathProxy {
  PathModifier(this.path);

  Path path;

  @override
  void close() {
    path.close();
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
  }
}
