// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Default styles.
final defaultStyles = {
  'pen': new SketchStyle(0.04, Colors.black),
  'grid': new SketchStyle(0.02, Colors.lightGray)
};

class CanvasAPI implements SketchAPI {
  final CanvasRenderingContext2D ctx;
  final Map<String, SketchStyle> styles;
  final Matrix3 transformation;
  final Vector2 wh;
  final num pointHighlightR = 0.1;

  CanvasAPI(this.ctx, this.transformation, this.wh, this.styles);

  num get unitScale => transformation.entry(0, 0);

  /// Get transformed vector.
  Vector2 _transform(Vector2 v, [bool round = true]) {
    final v3 = transformation.transform(vec3(v.x, v.y, 1.0));
    return round ? vec2(v3.x.roundToDouble(), v3.y.roundToDouble()) : v3.xy;
  }

  /// Apply given [style].
  void _applyStyle(SketchStyle style) {
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = (unitScale * style.relativeLineWidth).ceil();
    ctx.strokeStyle = rgba(style.strokeColor);
  }

  void _drawPath(String style, void draw()) {
    _applyStyle(styles[style]);
    ctx.beginPath();
    draw();
    ctx.closePath();
    ctx.stroke();
  }

  @override
  Tuple2<Vector2, Vector2> projEdge(Ray2 ray) {
    final rwh = wh / unitScale;
    final bbox = new Aabb2.centerAndHalfExtents(vec2(0, 0), rwh / 2.0);
    return ray.intersectAabb(bbox);
  }

  @override
  void drawPointHighlight(Vector2 point) {
    ctx.fillStyle = 'red';
    final c = _transform(point);
    final r = pointHighlightR * unitScale;

    ctx.beginPath();
    ctx.arc(c.x, c.y, r, 0, 2 * PI);
    ctx.closePath();
    ctx.fill();
  }

  @override
  void drawLine(Vector2 from, Vector2 to, String style) {
    _drawPath(style, () {
      final _from = _transform(from), _to = _transform(to);

      // If line is almost horizontal or vertical, and the line width is thin,
      // use this code to make it pixel perfect.
      if (ctx.lineWidth < 5 && ctx.lineWidth % 2 != 0) {
        if ((_from.x - _to.x).abs() < 5) {
          _from.x += .5;
          _to.x += .5;
        } else if ((_from.y - _to.y).abs() < 5) {
          _from.y += .5;
          _to.y += .5;
        }
      }

      ctx.moveTo(_from.x, _from.y);
      ctx.lineTo(_to.x, _to.y);
    });
  }

  @override
  void drawArc(
      Vector2 center, num radius, num startAngle, num endAngle, String style) {
    _drawPath(style, () {
      final _center = _transform(center);
      ctx.arc(_center.x, _center.y, (radius * unitScale).round(), startAngle,
          endAngle);
    });
  }
}
