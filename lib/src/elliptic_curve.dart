// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

class EllipticCurve implements SketchThing {
  final Vector2 center, radius;
  final num rotation, startAngle, endAngle;

  EllipticCurve(
      this.center, this.radius, this.rotation, this.startAngle, this.endAngle);

  @override
  int get drawPriority => 1;

  @override
  void draw(sk) {
    sk.drawEllipse(center, radius, rotation, startAngle, endAngle, 'pen');
  }

  @override
  MagnetPoint attract(Vector2 cursor) {
    // TODO: create ellipse class that handles transformations etc.
    final mRot = new Matrix2.identity()..setRotation(-rotation);
    final relTarget = mRot.transform(cursor - center);
    final relPoint = ellipseSectionClosestPoint(relTarget, radius.x, radius.y,
        startAngle - rotation, endAngle - rotation);

    if (relPoint == null) {
      return null;
    }

    // Transform back.
    mRot.invert();
    return new MagnetPoint.compute(mRot.transform(relPoint) + center, cursor,
        priority: 'normal', attraction: 'average');
  }

  @override
  List<Vector2> specialPoints() {
    if ((endAngle - startAngle).abs() < 2 * PI - 0.001) {
      // TODO: refactor.
      final startPoint =
          vec2(radius.x * cos(startAngle), radius.y * sin(startAngle));
      final endPoint = vec2(radius.x * cos(endAngle), radius.y * sin(endAngle));
      final mRot = new Matrix2.identity()..setRotation(rotation);
      return [
        center,
        center + mRot.transform(startPoint),
        center + mRot.transform(endPoint)
      ];
    } else {
      return [center];
    }
  }
}
