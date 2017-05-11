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
part 'src/linesegment.dart';

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

  /// Active tool
  var tool = SketchTool.line;

  /// Clicked target points
  final storedTargets = new List<Vector2>();

  SketchGrid(this.canvas) {
    // Setup event listening.
    canvas.onMouseMove.listen(onMouseMove);
    canvas.onMouseUp.listen(onMouseUp);

    // Setup drawing.
    ctx = canvas.getContext('2d');
    window.onResize.listen((_) => resize());
    resize();

    things
      ..add(new GridlineThing(new Ray2(vec2(0, 0), vec2(1, 0)), true, .7))
      ..add(new GridlineThing(new Ray2(vec2(0, 0), vec2(0, 1)), true, .7));
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
    things.sort((a, b) => b.drawPriority - a.drawPriority);
    for (final thing in things) {
      thing.draw(api);
    }

    // Draw target point.
    if (target != null) {
      api.drawPointHighlight(target);
    }

    for (final point in storedTargets) {
      api.drawPointHighlight(point);
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
    final points = things.map((t) => t.closestPoint(cursor)).toList();
    points.removeWhere((p) => p == null);

    // Get closest point.
    var targetIdx = -1;
    num smallestDistance = 1000;
    for (var i = 0; i < points.length; i++) {
      final distance = points[i].item1.distanceToSquared(cursor);
      if (distance < smallestDistance) {
        targetIdx = i;
        smallestDistance = distance;
      }
    }

    // If another point is very close to the current one, we can compute the
    // intersection between the two origin curves. If there turns out to be no
    // intersection, keep trying the other points etc.
    if (targetIdx != -1) {
      var targetIsIntersection = false;
      target = points[targetIdx].item1;

      for (var i = 0; i < points.length; i++) {
        if (i == targetIdx) {
          continue;
        }
        if (target.distanceTo(points[i].item1) < 0.3) {
          final intersect = thingIntersection(things[targetIdx],
              points[targetIdx].item2, things[i], points[i].item2, cursor);
          if (intersect != null &&
              ((!targetIsIntersection &&
                      intersect.distanceToSquared(cursor) < 0.3) ||
                  intersect.distanceToSquared(cursor) <
                      target.distanceToSquared(cursor))) {
            target = intersect;
            targetIsIntersection = true;
          }
        }
      }
    }

    redraw();
  }

  void onMouseUp(MouseEvent e) {
    if (target != null) {
      storedTargets.add(target);

      if (storedTargets.length > 1) {
        final from = storedTargets.removeLast(),
            to = storedTargets.removeLast();

        if (tool == SketchTool.line) {
          things.add(new LineSegmentThing(from, to));
        } else if (tool == SketchTool.gridline) {
          final ray = new Ray2.fromTo(from, to);
          things.add(new GridlineThing(ray));
        }

        redraw();
      }
    }
  }
}
