// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// 2D ray + utils
class Ray2 {
  final Vector2 origin, direction;
  Ray2(this.origin, this.direction);

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

  /// Return translated ray.
  Ray2 translate(Vector2 translation) {
    return new Ray2(origin + translation, direction);
  }
}
