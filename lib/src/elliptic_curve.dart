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
  MagnetPoint attract(Vector2 target) {
    // TODO: Implement curve, center, begin/endpoint attraction.
    return null;
  }
}
