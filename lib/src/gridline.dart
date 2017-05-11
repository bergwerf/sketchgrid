// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

enum GridlineConstraint {
  twoPoints,
  horizontal,
  vertical,
  parallel,
  perpendicular,
  singleTangent,
  doubleTangent
}

class GridLine implements LineThing {
  @override
  final Ray2 ray;

  final bool ruler;
  final num rulerSteps;

  GridLine(this.ray, [this.ruler = false, this.rulerSteps = 1]);

  @override
  int get drawPriority => 2;

  @override
  void draw(sk) {
    final proj = sk.projEdge(ray);
    if (proj != null) {
      sk.drawLine(proj.item1, proj.item2, 'grid');
    }
  }

  @override
  MagnetPoint attract(Vector2 to) {
    // Get vector from this ray origin to [to].
    final relTo = to - ray.origin;

    // Project [relTo] on ray.
    final proj = ray.origin + vectorProjection(relTo, ray.direction);

    // Check if the point is close enough.
    final distance = proj.distanceTo(to);
    if (distance < MagnetPoint.magnetDistance) {
      return new MagnetPoint(proj, distance, MagnetPoint.priorityNormal);
    } else {
      return null;
    }
  }

  @override
  bool containsIntersection(point) => true;
}
