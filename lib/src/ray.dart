// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// 2D ray + utils
class Ray2 {
  final Vector2 origin, direction;

  factory Ray2(Vector2 origin, Vector2 direction) {
    return new Ray2._(origin, unitVector(direction));
  }

  factory Ray2.fromTo(Vector2 from, Vector2 to) {
    return new Ray2(from, to - from);
  }

  Ray2._(this.origin, this.direction);

  Tuple2<Vector2, Vector2> intersectAabb(Aabb2 aabb) {
    final result = new List<Vector2>();
    final bounds = [
      [aabb.min.x, aabb.max.x],
      [aabb.min.y, aabb.max.y]
    ];

    for (var d = 0; d < 2; d++) {
      if (direction.storage[d] == 0) {
        continue;
      }
      for (var i = 0; i < 2; i++) {
        final dist = (bounds[d][i] - origin.storage[d]) / direction.storage[d];
        final proj = origin + direction * dist;
        final tmp = proj.storage[1 - d];
        if (tmp >= bounds[1 - d][0] && tmp <= bounds[1 - d][1]) {
          result.add(proj);
        }
      }
    }

    if (result.isEmpty) {
      return null;
    } else {
      return new Tuple2<Vector2, Vector2>(result[0], result[1]);
    }
  }

  Vector2 intersectRay(Ray2 other) {
    if (isAlmost(direction.cross(other.direction), 0, 0.001)) {
      return null;
    } else if (direction.x == 0 && other.direction.y == 0) {
      return vec2(origin.x, other.origin.y);
    } else if (direction.y == 0 && other.direction.x == 0) {
      return vec2(other.origin.x, origin.y);
    } else if (direction.x == 0 || other.direction.x == 0) {
      // Evaluate with respect to y, i.e. x = ay + b.
      final a1 = direction.x / direction.y;
      final a2 = other.direction.x / other.direction.y;
      final b1 = origin.x - (a1 * origin.y);
      final b2 = other.origin.x - (a2 * other.origin.y);
      final y = (b2 - b1) / (a1 - a2);
      return vec2(a1 * y + b1, y);
    } else {
      // Evaluate with respect to x, i.e. y = ax + b.
      final a1 = direction.y / direction.x;
      final a2 = other.direction.y / other.direction.x;
      final b1 = origin.y - (a1 * origin.x);
      final b2 = other.origin.y - (a2 * other.origin.x);
      final x = (b2 - b1) / (a1 - a2);
      return vec2(x, a1 * x + b1);
    }
  }

  /// Return translated ray.
  Ray2 translate(Vector2 translation) {
    return new Ray2(origin + translation, direction);
  }

  /// Get point at [distance] from origin.
  Vector2 at(num distance) {
    return origin + direction * distance;
  }

  /// Project [point] on ray.
  Vector2 project(Vector2 point) {
    return origin + vec2Projection(point - origin, direction);
  }
}
