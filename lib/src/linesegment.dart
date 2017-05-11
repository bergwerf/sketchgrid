// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class LineSegmentThing implements SketchThing {
  final Vector2 from, to;

  LineSegmentThing(this.from, this.to);

  @override
  int get drawPriority => 1;

  @override
  void draw(sk) {
    sk.drawLine(from, to, 'pen');
  }

  @override
  Tuple2<Vector2, int> closestPoint(Vector2 target) {
    // Get vector from line start to [to].
    final relTo = target - from;

    // Project [relTo] on ray.
    final proj = from + vectorProjection(relTo, to - from);

    if (new Aabb2.centerAndHalfExtents(
            (from + to) / 2.0, ((to - from) / 2.0)..absolute())
        .containsVector2(proj)) {
      return new Tuple2<Vector2, int>(proj, 0);
    } else {
      return null;
    }
  }
}
