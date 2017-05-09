// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library sketchgrid;

import 'dart:html';
import 'dart:math';

import 'package:tuple/tuple.dart';
import 'package:vector_math/vector_math.dart';

part 'src/utils.dart';
part 'src/ray.dart';
part 'src/abstracts.dart';
part 'src/canvas_api.dart';
part 'src/gridline.dart';

enum SketchTool { line, arc, gridline }

class SketchGrid {
  final CanvasElement canvas;
  final things = new List<SketchThing>();

  /// Transformation matrix we use to map points to pixels
  Matrix3 transformation;

  CanvasRenderingContext2D ctx;
  bool scheduledRedraw = false;
  num gridSize = 11;

  /// Target point for selection
  Vector2 target;

  SketchGrid(this.canvas) {
    // Setup event listening.
    canvas.onMouseMove.listen(onMouseMove);

    // Setup drawing.
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

    // Compute grid size in pixels based on smallest side.
    final w = canvas.width, h = canvas.height;
    final gridSizePx = (w > h ? h : w) / gridSize;

    // Compute new transformation matrix.
    transformation = new Matrix3.fromList([
      gridSizePx, 0.0, 0.0, //
      0.0, -gridSizePx, 0.0, //
      w / 2, h / 2, 1.0
    ]);

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

    // Draw all things.
    final api = new CanvasAPI(ctx, transformation, vec2(w, h), defaultStyles);
    for (final thing in things) {
      thing.draw(api);
    }

    // Draw target point.
    if (target != null) {
      api.drawPointHighlight(target);
    }
  }

  /// Get mouse position in relative coordinates given [event].
  Vector2 getPointer(Event event) {
    final pointer = event is MouseEvent
        ? event.client
        : event is TouchEvent
            ? event.touches.first.client
            : new Point<num>(0, 0);

    final v = vec2(pointer.x, pointer.y);
    final rect = canvas.getBoundingClientRect();
    v.x -= rect.left;
    v.y -= rect.top;

    return transformToRel(v);
  }

  /// Transform pixel coordinate (from event) to relative coordinate.
  Vector2 transformToRel(Vector2 v) {
    final inverse = transformation.clone()..invert();
    final v3 = inverse.transform(vec3(v.x, v.y, 1.0));
    return vec2(v3.x, v3.y);
  }

  void onMouseMove(MouseEvent e) {
    final cursor = getPointer(e);

    // Get all closest points and get closest one.
    final points = things.map((t) => t.closestPoint(cursor));

    // Get closest point.
    num smallestDistance = 1000;
    for (final point in points) {
      final distance = point.distanceToSquared(cursor);
      if (distance < smallestDistance) {
        target = point;
        smallestDistance = distance;
      }
    }

    redraw();
  }
}
