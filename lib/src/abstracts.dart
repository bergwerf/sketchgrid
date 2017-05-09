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

/// Template for all things in the editor
abstract class SketchThing {
  /// Draw the thing.
  void draw(SketchAPI sketch);

  /// Return point that is closest to [to].
  Vector2 closestPoint(Vector2 to);
}
