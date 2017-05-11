// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Drawing style data
class SketchStyle {
  final num relativeLineWidth;
  final Vector4 strokeColor;

  SketchStyle(this.relativeLineWidth, this.strokeColor);
}

/// Universal drawing interface
abstract class SketchAPI {
  Tuple2<Vector2, Vector2> projEdge(Ray2 ray);
  void drawPointHighlight(Vector2 point);
  void drawLine(Vector2 from, Vector2 to, String style);
  void drawArc(
      Vector2 center, num radius, num startAngle, num endAngle, String style);
}

/// Magnet point for event handling
class MagnetPoint {
  static num magnetDistance = 0.2;
  static num strongMagnetDistance = 0.3;

  static const priorityNormal = 2;
  static const priorityHigh = 1;

  final Vector2 point;
  final num cursorDistance;
  final int priority;

  MagnetPoint(this.point, this.cursorDistance, this.priority);
}

/// Template for all things in the editor
abstract class SketchThing {
  /// Drawing priority (lower is higher priority).
  int get drawPriority;

  /// Draw the thing.
  void draw(SketchAPI sketch);

  /// Return point that is closest to [to].
  MagnetPoint attract(Vector2 to);
}

/// Common class for grid lines and line segments for easier intersection.
abstract class LineThing implements SketchThing {
  /// Get ray in the position and direction of this line.
  Ray2 get ray;

  /// For a given intersection point on the ray, check if it is on this line.
  bool containsIntersection(Vector2 point);
}
