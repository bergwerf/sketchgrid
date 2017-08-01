// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class RayRuler implements RayThing {
  @override
  final Ray2 ray;

  final bool ruler;
  final num stepSize;

  RayRuler(this.ray, [this.ruler = false, this.stepSize = 1]);

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
  MagnetPoint attract(Vector2 cursor) {
    // Project cursor on ray.
    final proj = ray.project(cursor);

    // If this is a ruler, check if the projection is close enough to an
    // indicator.
    if (ruler) {
      final distance = ray.origin.distanceTo(proj);
      final idx = (distance / stepSize).round() *
          ((proj - ray.origin).angleToSigned(ray.direction).abs() < 1 ? 1 : -1);

      final v = ray.at(idx * stepSize);
      final vDist = v.distanceTo(cursor);
      if (vDist < MagnetPoint.magnetAttraction['strong']) {
        return new MagnetPoint(v, vDist, priority: 'high');
      }
    }

    return new MagnetPoint.compute(proj, cursor,
        attraction: 'average', priority: 'normal');
  }

  @override
  bool containsIntersection(point) => true;

  @override
  List<Vector2> specialPoints() => [];
}
