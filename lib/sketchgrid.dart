// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library sketchgrid;

import 'dart:html';
import 'dart:math';

import 'package:tuple/tuple.dart';
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math.dart';

part 'src/utils.dart';
part 'src/ray.dart';
part 'src/abstracts.dart';
part 'src/canvas_api.dart';
part 'src/gridline.dart';
part 'src/linesegment.dart';
part 'src/intersections.dart';

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

    // Compute all intersections.
    final inter = new List<Vector2>();
    for (var i = 0; i < things.length; i++) {
      for (var j = i + 1; j < things.length; j++) {
        inter.addAll(thingIntersection(things[i], things[j]));
      }
    }

    // Check if any intersection is within magnet distance.
    final interDistance = new List<Tuple2<num, int>>.generate(inter.length,
        (i) => new Tuple2<num, int>(inter[i].distanceTo(cursor), i)).toList();
    final minInter = minBy(interDistance, (e) => e.item1);
    if (minInter != null && minInter.item1 < MagnetPoint.strongMagnetDistance) {
      target = inter[minInter.item2];
    } else {
      // Get all magnet points.
      final m = things.map((t) => t.attract(cursor)).toList();
      m.removeWhere((p) => p == null);
      m.sort((a, b) {
        if (a.priority < b.priority) {
          return -1;
        } else if (a.priority > b.priority) {
          return 1;
        } else {
          return a.cursorDistance - b.cursorDistance;
        }
      });

      if (m.isNotEmpty) {
        target = m.first.point;
      } else {
        target = cursor;
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
          things.add(new LineSegment(from, to));
        } else if (tool == SketchTool.gridline) {
          final ray = new Ray2.fromTo(from, to);
          things.add(new GridLine(ray, true));
        }

        redraw();
      }
    }
  }
}
