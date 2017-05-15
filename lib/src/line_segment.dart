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
  MagnetPoint attract(Vector2 cursor) {
    // Get vector from line start to [to].
    final relCursor = cursor - from;

    // Project [relCursor] on ray.
    final proj = from + vec2Projection(relCursor, to - from);

    return bbox.containsVector2(proj)
        ? new MagnetPoint.compute(proj, cursor,
            attraction: 'average', priority: 'normal')
        : null;
  }

  @override
  bool containsIntersection(point) => bbox.containsVector2(point);

  @override
  List<Vector2> specialPoints() {
    return [from, to];
  }

  Aabb2 get bbox => getLineBBox(from, to);
}
