// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library sketchgridy;

import 'dart:html';

import 'package:tuple/tuple.dart';
import 'package:vector_math/vector_math.dart';

Vector2 vec2(num x, num y) => new Vector2(x, y);
String rgba(Vector4 c) =>
    'rgba(${(c.r * 255).round()},${(c.r * 255).round()},${(c.r * 255).round()},${c.a})';

class Ray2 {
  final Vector2 origin, direction;
  Ray2(this.origin, this.direction);

  Tuple2<Vector2, Vector2> intersect(Aabb2 aabb) {
    final result = new List<Vector2>();
    final bounds = [
      [aabb.min.x, aabb.max.x],
      [aabb.min.y, aabb.max.y]
    ];

    for (var d = 0; d < 2; d++) {
      for (var i = 0; i < 2; i++) {
        final dist = (bounds[d][i] - origin.storage[d]) / direction.storage[d];
        final proj = origin + direction * dist;
        final tmp = proj.storage[1 - d];
        if (tmp > bounds[1 - d][0] && tmp < bounds[1 - d][1]) {
          result.add(proj);
        }
      }
    }

    if (result.isEmpty) {
      return null;
    } else {
      assert(result.length == 2);
      return new Tuple2<Vector2, Vector2>(result[0], result[1]);
    }
  }

  /// Return translated ray.
  Ray2 translate(Vector2 translation) {
    return new Ray2(origin + translation, direction);
  }
}

enum SketchStyle { pen, grid }

abstract class SketchAPI {
  void drawLine(Vector2 from, Vector2 to, SketchStyle style);
  void drawArc(Vector2 center, num radius, num startAngle, num endAngle,
      SketchStyle style);
  Tuple2<Vector2, Vector2> projEdge(Ray2 ray);
}

class CanvasAPI implements SketchAPI {
  final CanvasRenderingContext2D ctx;
  final num penThickness, gridTickness;
  final Vector4 penColor, gridColor;
  final Vector2 wh;
  final num unitSizePx;

  CanvasAPI(this.ctx, this.wh, this.unitSizePx,
      {this.penThickness: .05,
      this.gridTickness: 0.02,
      Vector4 penColor,
      Vector4 gridColor})
      : penColor = penColor ?? Colors.black,
        gridColor = gridColor ?? Colors.lightGray;

  /// Get transformed and pixel-perfect point. A .5 translation is added when
  /// the [lineWidth] is an odd number.
  Vector2 _pp(Vector2 p, int lineWidth) {
    final v = vec2((p.x * unitSizePx + wh.x / 2.0).round(),
        (-p.y * unitSizePx + wh.y / 2.0).round());

    // Pixel perfect thin lines.
    if (lineWidth % 2 != 0) {
      v.x += .5;
      v.y += .5;
    }

    return v;
  }

  /// Returns line width because this is taken into account for pixel perfect
  /// line positioning.
  int _setStyle(SketchStyle style) {
    ctx.lineCap = 'round';
    switch (style) {
      case SketchStyle.pen:
        ctx.lineWidth = (penThickness * unitSizePx).ceil();
        ctx.strokeStyle = rgba(penColor);
        break;
      case SketchStyle.grid:
        ctx.lineWidth = (gridTickness * unitSizePx).ceil();
        ctx.strokeStyle = rgba(gridColor);
        break;
    }

    return ctx.lineWidth;
  }

  void _drawPath(SketchStyle style, void draw(int lineWidth)) {
    ctx.beginPath();
    draw(_setStyle(style));
    ctx.closePath();
    ctx.stroke();
  }

  @override
  Tuple2<Vector2, Vector2> projEdge(Ray2 ray) {
    return ray.intersect(
        new Aabb2.centerAndHalfExtents(vec2(0, 0), wh / unitSizePx / 2.0));
  }

  @override
  void drawLine(Vector2 from, Vector2 to, SketchStyle style) {
    _drawPath(style, (lw) {
      final _from = _pp(from, lw), _to = _pp(to, lw);
      ctx.moveTo(_from.x, _from.y);
      ctx.lineTo(_to.x, _to.y);
    });
  }

  @override
  void drawArc(Vector2 center, num radius, num startAngle, num endAngle,
      SketchStyle style) {
    _drawPath(style, (lw) {
      final _center = _pp(center, lw);
      ctx.arc(_center.x, _center.y, (radius * unitSizePx).round(), startAngle,
          endAngle);
    });
  }
}

abstract class SketchThing {
  void draw(SketchAPI sketch);
}

enum GridlineType { single, repeat }

enum GridlineConstraint {
  twoPoints,
  horizontal,
  vertical,
  parallel,
  perpendicular,
  singleTangent,
  doubleTangent
}

class GridlineThing implements SketchThing {
  final Ray2 ray;
  final bool repeat;
  final num distance;

  GridlineThing(this.ray, [this.repeat = false, this.distance = 0]);

  @override
  void draw(sk) {
    var proj = sk.projEdge(ray);
    sk.drawLine(proj.item1, proj.item2, SketchStyle.grid);
    if (repeat && distance > 0) {
      // <a b>*<x y> = 0 --> ax + by = 0, x + by = 0, b = -x/y
      var extend = ray.direction.y == 0
          ? vec2(0, 1)
          : vec2(1, -ray.direction.x / ray.direction.y);
      extend = extend / extend.length;

      for (final step in [1, -1]) {
        var offset = 0;
        while (offset < 10000) {
          offset += step;
          proj = sk.projEdge(ray.translate(extend * (distance * offset)));

          if (proj != null) {
            sk.drawLine(proj.item1, proj.item2, SketchStyle.grid);
          } else {
            break;
          }
        }
      }
    }
  }
}

enum SketchTool { line, arc, gridline }

class SketchGrid {
  final CanvasElement canvas;
  final things = new List<SketchThing>();

  CanvasRenderingContext2D ctx;
  bool scheduledRedraw = false;
  num gridSize = 11;

  SketchGrid(this.canvas) {
    ctx = canvas.getContext('2d');
    window.onResize.listen((_) => resize());
    resize();

    things
      ..add(new GridlineThing(new Ray2(vec2(0, 0), vec2(1, 0)), true, 1))
      ..add(new GridlineThing(new Ray2(vec2(0, 0), vec2(0, 1)), true, 1));
  }

  void resize() {
    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    redraw();
  }

  void redraw() {
    if (!scheduledRedraw) {
      scheduledRedraw = true;
      window.animationFrame.then((_) {
        scheduledRedraw = false;
        draw();
      });
    }
  }

  void draw() {
    final w = canvas.width, h = canvas.height;
    ctx.clearRect(0, 0, w, h);

    // Compute grid size in pixels based on smallest side.
    final gridSizePx = (w > h ? h : w) / gridSize;

    // Draw all things.
    final api = new CanvasAPI(ctx, vec2(w, h), gridSizePx);
    for (final thing in things) {
      thing.draw(api);
    }
  }
}
