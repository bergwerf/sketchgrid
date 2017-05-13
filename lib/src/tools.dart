// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class LineSegmentTool extends SketchTool<LineSegment> {
  @override
  LineSegment createThing(points, remove) {
    final pts = getNPoints(2, points, remove);

    // If the second point is not sticked, clamp it to one of the exact angles:
    // 0, 1/6, 1/2, 1/3, 1, ...
    // If within deviation of 0.2 rad.
    if (!pts[1].isSticked) {
      final rel = pts[1].v - pts[0].v;
      final a = vec2Angle(rel);

      const angleStickThreshold = .3;
      const stickingAngles = const [
        // 0, 1 / 6, 1 / 4, 2 / 6, 2 / 4, 4 / 6, 3 / 4, 5 / 6, 1,
        // -1 / 6, -1 / 4, -2 / 6, -2 / 4, -4 / 6, -3 / 4, -5 / 6, -1
        -1, -1 / 2, 0, 1 / 2, 1
      ];

      final margin = angleStickThreshold / rel.length;
      for (final _stickAngle in stickingAngles) {
        final stickAngle = _stickAngle * PI;
        if (isAlmost(a, stickAngle, margin)) {
          final direction = vec2(cos(stickAngle), sin(stickAngle));
          pts[1].v.setFrom(pts[0].v + direction * rel.length);
          break;
        }
      }
    }

    return new LineSegment(pts[0].v, pts[1].v);
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
        return new GridLine(new Ray2.fromTo(pts[0].v, pts[1].v), ruler);

      case GridlineConstraint.horizontal:
        final pts = getNPoints(1, points, remove);
        return new GridLine(new Ray2(pts[0].v, vec2(1, 0)), ruler);

      case GridlineConstraint.vertical:
        final pts = getNPoints(1, points, remove);
        return new GridLine(new Ray2(pts[0].v, vec2(0, 1)), ruler);

      case GridlineConstraint.parallel:
        final pts = getNPoints(3, points, remove);
        return new GridLine(new Ray2(pts[2].v, pts[1].v - pts[0].v));

      case GridlineConstraint.perpendicular:
        final pts = getNPoints(2, points, remove);
        final direction = vec2Perpendicular(pts[1].v - pts[0].v);
        return new GridLine(new Ray2(pts[1].v, direction));

      default:
        return null;
    }
  }
}
