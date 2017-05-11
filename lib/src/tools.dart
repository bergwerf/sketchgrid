// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class LineSegmentTool extends SketchTool<LineSegment> {
  @override
  LineSegment createThing(points, remove) {
    final pts = getNPoints(2, points, remove);
    return new LineSegment(pts[0], pts[1]);
  }
}

enum GridlineConstraint {
  twoPoints,
  horizontal,
  vertical,
  parallel,
  perpendicular,
  singleTangent,
  doubleTangent
}

class GridLineTool extends SketchTool<GridLine> {
  var ruler = false;
  var constraint = GridlineConstraint.twoPoints;

  @override
  GridLine createThing(points, remove) {
    switch (constraint) {
      case GridlineConstraint.twoPoints:
        final pts = getNPoints(2, points, remove);
        return new GridLine(new Ray2.fromTo(pts[0], pts[1]), ruler);

      case GridlineConstraint.horizontal:
        final pts = getNPoints(1, points, remove);
        return new GridLine(new Ray2(pts[0], vec2(1, 0)), ruler);

      case GridlineConstraint.vertical:
        final pts = getNPoints(1, points, remove);
        return new GridLine(new Ray2(pts[0], vec2(0, 1)), ruler);

      default:
        return null;
    }
  }
}
