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
  void drawLine(Vector2 from, Vector2 to, String style, [bool exact]);
  void drawEllipse(Vector2 center, Vector2 radius, num rotation, num startAngle,
      num endAngle, String style);
}

/// Magnet point for event handling
class MagnetPoint {
  static const magnetPriority = const {'normal': 2, 'high': 1};
  static const magnetAttraction = const {'average': .2, 'strong': .3};

  final Vector2 point;
  final num cursorDistance;
  final int priority;

  MagnetPoint(this.point, this.cursorDistance, {String priority: 'normal'})
      : priority = magnetPriority[priority];

  factory MagnetPoint.compute(Vector2 point, Vector2 cursor,
      {String priority: 'normal', String attraction: 'average'}) {
    final distanceValue = cursor.distanceTo(point);
    if (distanceValue <= magnetAttraction[attraction]) {
      return new MagnetPoint(point, distanceValue, priority: priority);
    } else {
      return null;
    }
  }
}

/// Template for all things in the editor
abstract class SketchThing {
  /// Drawing priority (lower is higher priority).
  int get drawPriority;

  /// Draw the thing.
  void draw(SketchAPI sketch);

  /// Return point that is closest to [cursor].
  MagnetPoint attract(Vector2 cursor);

  /// Return some special points in this thing with high attraction.
  List<Vector2> specialPoints();
}

/// Common class for grid lines and line segments for easier intersection.
abstract class RayThing implements SketchThing {
  /// Get ray in the position and direction of this line.
  Ray2 get ray;

  /// For a given intersection point on the ray, check if it is on this line.
  bool containsIntersection(Vector2 point);
}

class ToolPoint {
  final Vector2 v;
  final bool isSticked;
  ToolPoint(Vector2 v, this.isSticked) : v = v.clone();
}

/// Sketch tool interface
abstract class SketchTool<T extends SketchThing> {
  final points = new List<ToolPoint>();

  /// Get a sketchthing from the given points.
  T createThing(List<ToolPoint> points, bool permanent);

  /// Draw any tool related stuff.
  void draw(SketchAPI sk, ToolPoint hoveredPoint) {
    // Collect list of all points.
    final allPoints = new List<ToolPoint>.from(points);
    if (hoveredPoint != null) {
      allPoints.add(hoveredPoint);
    }

    // Draw preview of thing.
    try {
      final preview = createThing(allPoints, false);
      if (preview != null) {
        preview.draw(sk);
      }
    } on RangeError {
      // This is a bit of a hack, but it makes other code simpler.
    } finally {
      // Draw all points.
      for (final p in allPoints) {
        sk.drawPointHighlight(p.v);
      }
    }
  }

  /// The user clicked a point.
  void addPoint(ToolPoint point, List<SketchThing> things) {
    points.add(point);
    try {
      final thing = createThing(points, true);
      if (thing != null) {
        things.add(thing);
      }
    } on RangeError {
      // This is a bit of a hack, but it makes other code simpler.
    }
  }
}
