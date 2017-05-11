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
part 'src/tools.dart';

class SketchGrid {
  final CanvasElement canvas;
  final things = new List<SketchThing>();

  /// Transformation matrix we use to map points to pixels
  Matrix3 transformation;

  CanvasRenderingContext2D ctx;
  bool scheduledRedraw = false;
  num gridSize = 11;

  /// Hovered point
  Vector2 hoveredPoint;

  /// Active tool
  SketchTool tool;

  SketchGrid(this.canvas) {
    // Setup event listening.
    canvas.onMouseMove.listen(onMouseMove);
    canvas.onMouseDown.listen(onMouseDown);
    canvas.onMouseUp.listen(onMouseUp);
    canvas.onContextMenu.listen((e) => e.preventDefault());
    canvas.onMouseLeave.listen((_) {
      hoveredPoint = null;
      redraw();
    });

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
    final sk = new CanvasAPI(ctx, transformation, vec2(w, h), defaultStyles);
    things.sort((a, b) => b.drawPriority - a.drawPriority);
    for (final thing in things) {
      thing.draw(sk);
    }

    // Draw target point.
    if (hoveredPoint != null) {
      sk.drawPointHighlight(hoveredPoint);
    }

    if (tool != null) {
      tool.draw(sk, hoveredPoint);
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

  /// Get attraction points for the given [cursor] point.
  List<Tuple2<MagnetPoint, int>> getAttractionPoints(Vector2 cursor) {
    final m = new List<Tuple2<MagnetPoint, int>>();
    for (var i = 0; i < things.length; i++) {
      final magnet = things[i].attract(cursor);
      if (magnet != null) {
        m.add(new Tuple2<MagnetPoint, int>(magnet, i));
      }
    }

    m.sort((a, b) {
      if (a.item1.priority < b.item1.priority) {
        return -1;
      } else if (a.item1.priority > b.item1.priority) {
        return 1;
      } else {
        return a.item1.cursorDistance - b.item1.cursorDistance;
      }
    });

    return m;
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
      hoveredPoint = inter[minInter.item2];
    } else {
      final m = getAttractionPoints(cursor);
      if (m.isNotEmpty) {
        hoveredPoint = m.first.item1.point;
      } else {
        hoveredPoint = cursor;
      }
    }

    redraw();
  }

  void onMouseDown(MouseEvent e) {
    e.preventDefault();
    if (e.button == 2) {
      final m = getAttractionPoints(getPointer(e));
      if (m.isNotEmpty) {
        things.removeAt(m.first.item2);
      } else {
        tool.points.clear();
      }

      redraw();
    }
  }

  void onMouseUp(MouseEvent e) {
    e.preventDefault();
    if (e.button == 0) {
      if (hoveredPoint != null && tool != null) {
        tool.addPoint(hoveredPoint, things);
        redraw();
      }
    }
  }
}
