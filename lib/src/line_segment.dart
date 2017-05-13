// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class LineSegment implements LineThing {
  final Vector2 from, to;

  LineSegment(this.from, this.to);

  @override
  Ray2 get ray => new Ray2.fromTo(from, to);

  @override
  int get drawPriority => 1;

  @override
  void draw(sk) {
    sk.drawLine(from, to, 'pen');
  }

  @override
  MagnetPoint attract(Vector2 target) {
    // Check if target is close enough to [from] or [to].
    final fromDistance = target.distanceTo(from);
    if (fromDistance < MagnetPoint.strongMagnetDistance) {
      return new MagnetPoint(from, fromDistance, MagnetPoint.priorityHigh);
    }
    final toDistance = target.distanceTo(to);
    if (toDistance < MagnetPoint.strongMagnetDistance) {
      return new MagnetPoint(to, toDistance, MagnetPoint.priorityHigh);
    }

    // Get vector from line start to [to].
    final relTo = target - from;

    // Project [relTo] on ray.
    final proj = from + vec2Projection(relTo, to - from);

    final distance = proj.distanceTo(target);
    if (bbox.containsVector2(proj) && distance < MagnetPoint.magnetDistance) {
      return new MagnetPoint(proj, distance, MagnetPoint.priorityNormal);
    } else {
      return null;
    }
  }

  @override
  bool containsIntersection(point) => bbox.containsVector2(point);

  Aabb2 get bbox => getLineBBox(from, to);
}
