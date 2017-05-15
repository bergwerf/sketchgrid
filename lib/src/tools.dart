// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Stick [point] angle relative to [center] to some common values.
void _stickAngle(ToolPoint center, ToolPoint point) {
  final rel = point.v - center.v;
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
      point.v.setFrom(center.v + direction * rel.length);
      break;
    }
  }
}

class LineSegmentTool extends SketchTool<LineSegment> {
  bool path = false;

  @override
  LineSegment createThing(points, permanent) {
    if (points.length == 2) {
      final a = permanent ? points.removeAt(0) : points.first;
      final b = permanent && !path ? points.removeLast() : points.last;

      if (!b.isSticked) {
        _stickAngle(a, b);
      }

      if (a.v.distanceTo(b.v) < 0.01) {
        return null;
      } else {
        return new LineSegment(a.v.clone(), b.v.clone());
      }
    } else {
      return null;
    }
  }
}

class EllipticCurveTool extends SketchTool<EllipticCurve> {
  bool isCircle = true;
  bool isSegment = false;

  @override
  EllipticCurve createThing(points, permanent) {
    if (isCircle || (points.length == 2 && !permanent)) {
      if (points.length < 2 || points.length == 2 && permanent && isSegment) {
        return null;
      }

      final pts = getNPoints(points.length, points, permanent);
      final c = pts[0].v;
      final r = c.distanceTo(pts[1].v);
      final startAngle = vec2AnglePositive(pts[1].v - c);
      var endAngle = startAngle + 2 * PI;

      if (pts.length == 3) {
        _stickAngle(pts[0], pts[2]);
        endAngle = vec2AnglePositive(pts[2].v - c);
        pts[2].v.setFrom(c + vec2(cos(endAngle), sin(endAngle)) * r);
      }

      // TODO: refactor
      if (!angleIsBetween(startAngle + 0.01, startAngle, endAngle)) {
        return null;
      } else {
        return new EllipticCurve(
            c, new Vector2.all(r), 0, startAngle, endAngle);
      }
    } else {
      // Ellipse
      // See: https://math.stackexchange.com/questions/2068583/
      // TODO: Move all algorithms to ellipse_math.dart
      if (points.length < 3 || points.length == 3 && permanent && isSegment) {
        return null;
      }

      final pts = getNPoints(points.length, points, permanent);

      final c = pts[0].v;
      final v1 = pts[1].v - c;
      final v2 = pts[2].v - c;

      final a = v1.length;
      final b = (v2 - vec2Projection(v2, v1)).length;
      final shear = (v2.angleToSigned(v1) - PI / 2) % PI;

      // Do not create invisible ellipses.
      if (a == 0 || b == 0) {
        return null;
      }

      // This is needed to prevent exceptions.
      if (shear == 0) {
        return new EllipticCurve(c, vec2(a, b), vec2Angle(v1), 0, 2 * PI);
      }

      final A = 1 / pow2(a);
      final B = 2 *
          -tan(shear) /
          pow2(
            a,
          );
      final C = 1 / pow2(b) + pow2(tan(shear)) / pow2(a);
      final y1 = 1 / 2 * (A + C - sqrt(pow2(A + C) + pow2(B) - 4 * A * C));
      final y2 = 1 / 2 * (A + C + sqrt(pow2(A + C) + pow2(B) - 4 * A * C));
      final aa = sqrt(1 / y1);
      final bb = sqrt(1 / y2);
      final ev1 = vec2(A - C - sqrt(pow2(A + C) + pow2(B) - 4 * A * C), B);
      final rot = vec2Angle(v1) + vec2Angle(ev1);

      final rMat = new Matrix2.identity()..setRotation(rot);
      final rMatInv = rMat.clone()..invert();
      final xyc = vec2(1 / aa, 1 / bb); // XY correction
      final sv = rMatInv.transform(pts[2].v - c)..multiply(xyc);
      final startAngle = vec2AnglePositive(sv);
      var endAngle = startAngle + 2 * PI;

      if (pts.length == 4) {
        final ev = rMatInv.transform(pts[3].v - c)..multiply(xyc);
        endAngle = vec2AnglePositive(ev);
        pts[3].v.setFrom(c + rMat.transform(vec2FromAngle(endAngle, aa, bb)));
      }

      // TODO: refactor
      if (!angleIsBetween(startAngle + 0.01, startAngle, endAngle)) {
        return null;
      } else {
        return new EllipticCurve(c, vec2(aa, bb), rot, startAngle, endAngle);
      }
    }
  }
}

enum RulerConstraint {
  twoPoints,
  horizontal,
  vertical,
  parallel,
  midline,
  perpendicular,
  bisect
}

class RayRulerTool extends SketchTool<RayRuler> {
  var ruler = false;
  var constraint = RulerConstraint.twoPoints;

  @override
  RayRuler createThing(points, permanent) {
    switch (constraint) {
      case RulerConstraint.twoPoints:
        final pts = getNPoints(2, points, permanent);
        return new RayRuler(new Ray2.fromTo(pts[0].v, pts[1].v), ruler);

      case RulerConstraint.horizontal:
        final pts = getNPoints(1, points, permanent);
        return new RayRuler(new Ray2(pts[0].v, vec2(1, 0)), ruler);

      case RulerConstraint.vertical:
        final pts = getNPoints(1, points, permanent);
        return new RayRuler(new Ray2(pts[0].v, vec2(0, 1)), ruler);

      case RulerConstraint.parallel:
        final pts = getNPoints(3, points, permanent);
        return new RayRuler(new Ray2(pts[2].v, pts[1].v - pts[0].v), ruler);

      case RulerConstraint.midline:
        final pts = getNPoints(3, points, permanent);
        return new RayRuler(
            new Ray2(
                pts[0].v + (pts[2].v - pts[0].v) / 2.0, pts[1].v - pts[0].v),
            ruler);

      case RulerConstraint.perpendicular:
        final pts = getNPoints(3, points, permanent);
        final direction = vec2Perpendicular(pts[1].v - pts[0].v);
        return new RayRuler(new Ray2(pts[2].v, direction), ruler);

      case RulerConstraint.bisect:
        final pts = getNPoints(3, points, permanent);
        final o = pts[0].v;
        final v1 = pts[1].v - o, v2 = pts[2].v - o;
        final angle = (vec2Angle(v1) + vec2Angle(v2)) / 2;
        return new RayRuler(new Ray2(o, vec2FromAngle(angle)), ruler);

      default:
        return null;
    }
  }
}
