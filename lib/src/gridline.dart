// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class GridLine implements LineThing {
  @override
  final Ray2 ray;

  final bool ruler;
  final num stepSize;

  GridLine(this.ray, [this.ruler = false, this.stepSize = 1]);

  @override
  int get drawPriority => 2;

  @override
  void draw(sk) {
    final proj = sk.projEdge(ray);
    if (proj != null) {
      sk.drawLine(proj.item1, proj.item2, 'grid');
    }
    if (ruler) {
      final bbox = getLineBBox(proj.item1, proj.item2);
      final o = vec2Perpendicular(ray.direction) * 0.1;

      // Draw ruler indicators.
      var v = ray.origin.clone();
      while (bbox.containsVector2(v)) {
        sk.drawLine(v + o, v - o, 'grid', true);
        v += ray.direction * stepSize;
      }
      v = ray.origin.clone() - ray.direction;
      while (bbox.containsVector2(v)) {
        sk.drawLine(v + o, v - o, 'grid', true);
        v -= ray.direction * stepSize;
      }
    }
  }

  @override
  MagnetPoint attract(Vector2 target) {
    // Project target on ray.
    final proj = ray.project(target);

    // If this is a ruler, check if the projection is close enough to an
    // indicator.
    if (ruler) {
      final distance = ray.origin.distanceTo(proj);
      final idx = (distance / stepSize).round() *
          ((proj - ray.origin).angleToSigned(ray.direction).abs() < 1 ? 1 : -1);

      final v = ray.at(idx * stepSize);
      final vDist = v.distanceTo(target);
      if (vDist < MagnetPoint.strongMagnetDistance) {
        return new MagnetPoint(v, vDist, MagnetPoint.priorityHigh);
      }
    }

    // Check if the point is close enough.
    final distance = proj.distanceTo(target);
    if (distance < MagnetPoint.magnetDistance) {
      return new MagnetPoint(proj, distance, MagnetPoint.priorityNormal);
    } else {
      return null;
    }
  }

  @override
  bool containsIntersection(point) => true;

  @override
  List<Vector2> specialPoints() => [];
}
