// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

enum GridlineType { single, repeat }

enum GridlineConstraint {
  twoPoints,
  horizontal,
  vertical,
  parallel,
  perpendicular,
  singleTangent,
  doubleTangent
}

class GridlineThing implements SketchThing {
  final Ray2 ray;
  final bool repeat;
  final num distance;

  GridlineThing(this.ray, [this.repeat = false, this.distance = 0]);

  @override
  int get drawPriority => 2;

  /// Get perpendicular ray direction.
  Vector2 perpendicular() {
    // <a b>*<x y> = 0 --> ax + by = 0, x + by = 0, b = -x/y
    final extend = ray.direction.y == 0
        ? vec2(0, 1)
        : vec2(1, -ray.direction.x / ray.direction.y);
    return extend / extend.length;
  }

  @override
  void draw(sk) {
    var proj = sk.projEdge(ray);
    if (proj != null) {
      sk.drawLine(proj.item1, proj.item2, 'grid');
    }
    if (repeat && distance > 0) {
      final extend = perpendicular();
      for (final step in [1, -1]) {
        var offset = 0;
        while (offset < 10000) {
          offset += step;
          proj = sk.projEdge(ray.translate(extend * (distance * offset)));

          if (proj != null) {
            sk.drawLine(proj.item1, proj.item2, 'grid');
          } else {
            break;
          }
        }
      }
    }
  }

  @override
  Tuple2<Vector2, int> closestPoint(Vector2 to) {
    // Get vector from this ray origin to [to].
    final relTo = to - ray.origin;

    // Project [relTo] on ray.
    final proj = ray.origin + vectorProjection(relTo, ray.direction);

    // If this is a repeating line, compute which line is closest to the point.
    if (repeat) {
      final offset = (proj.distanceTo(to) / distance + .5).floor();
      final offsetV = perpendicular();
      final normalDirection = (to - proj).angleToSigned(offsetV).abs() < 1;
      final index = normalDirection ? offset : -offset;
      final target = proj + offsetV * (distance * index.toDouble());
      return new Tuple2<Vector2, int>(target, index);
    } else {
      return new Tuple2<Vector2, int>(proj, 0);
    }
  }

  /// Get ray at [i].
  Ray2 getRay(int i) {
    return new Ray2(
        ray.origin + perpendicular() * (distance * i), ray.direction);
  }
}

/// Compute intersection point between two things at the given path indices
/// nearest to the given point.
Vector2 thingIntersection(
    SketchThing a, int aIdx, SketchThing b, int bIdx, Vector2 nearest) {
  if (a is GridlineThing && b is GridlineThing) {
    // Compute intersection.
    return a.getRay(aIdx).intersectRay(b.getRay(bIdx));
  } else {
    return null;
  }
}
