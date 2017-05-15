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
part 'src/ellipse_math.dart';
part 'src/abstracts.dart';
part 'src/canvas_api.dart';
part 'src/ray_ruler.dart';
part 'src/line_segment.dart';
part 'src/elliptic_curve.dart';
part 'src/intersections.dart';
part 'src/tools.dart';

class SketchGrid {
  final CanvasElement canvas;
  final things = new List<SketchThing>();

  /// Transformation matrix we use to map points to pixels
  Matrix3 transformation;

  CanvasRenderingContext2D ctx;
  bool scheduledRedraw = false;
  num gridSize = 16;

  /// Cached version of all intersections.
  List<Vector2> _inter = [];

  /// Hovered point
  ToolPoint hoveredPoint;

  /// Active tool
  SketchTool _tool;

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

    window.onKeyDown.listen((e) {
      if (e.keyCode == KeyCode.ESC) {
        _tool.points.clear();
      }
    });

    // Setup drawing.
    ctx = canvas.getContext('2d');
    window.onResize.listen((_) => resize());
    resize();
  }

  set tool(SketchTool replace) {
    _tool = replace;
    _tool.points.clear();
    redraw();
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

    if (_tool != null) {
      _tool.draw(sk, hoveredPoint);
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

  /// Compute all intersections between [things].
  /// This function could be optimized in several ways, such as caching.
  List<Vector2> computeAllIntersections() {
    final intersections = new List<Vector2>();
    for (var i = 0; i < things.length; i++) {
      for (var j = i + 1; j < things.length; j++) {
        intersections.addAll(thingIntersection(things[i], things[j]));
      }
    }
    return intersections;
  }

  /// Run and store [computeAllIntersections].
  void recomputeIntersections() {
    _inter = computeAllIntersections();
  }

  /// Get all attraction points for the given [cursor].
  List<Tuple2<MagnetPoint, int>> attractCursor(Vector2 cursor) {
    final m = new List<Tuple2<MagnetPoint, int>>();
    for (var i = 0; i < things.length; i++) {
      final specialPoints = things[i].specialPoints();
      for (final point in specialPoints) {
        final distance = point.distanceTo(cursor);
        if (distance < MagnetPoint.magnetAttraction['strong']) {
          final mg = new MagnetPoint(point, distance, priority: 'high');
          m.add(new Tuple2<MagnetPoint, int>(mg, i));
          continue;
        }
      }

      final aPoint = things[i].attract(cursor);
      if (aPoint != null) {
        m.add(new Tuple2<MagnetPoint, int>(aPoint, i));
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

    // Check if any intersection is within magnet distance.
    final interDistance = new List<Tuple2<num, int>>.generate(_inter.length,
        (i) => new Tuple2<num, int>(_inter[i].distanceTo(cursor), i)).toList();
    final minInter = minBy(interDistance, (e) => e.item1);
    if (minInter != null &&
        minInter.item1 < MagnetPoint.magnetAttraction['strong']) {
      hoveredPoint = new ToolPoint(_inter[minInter.item2], true);
    } else {
      // TODO: Attract towards X/Y position of existing points?
      final aPoints = attractCursor(cursor);
      if (aPoints.isNotEmpty) {
        hoveredPoint = new ToolPoint(aPoints.first.item1.point, true);
      } else {
        hoveredPoint = new ToolPoint(cursor, false);
      }
    }

    redraw();
  }

  void onMouseDown(MouseEvent e) {
    e.preventDefault();
    if (e.button == 2) {
      final snapPoints = attractCursor(getPointer(e));

      if (_tool.points.isNotEmpty) {
        _tool.points.clear();
      } else if (snapPoints.isNotEmpty) {
        // Sort [snapPoints] by [SketchThing.drawPriority].
        snapPoints.sort((a, b) {
          return things[a.item2].drawPriority - things[b.item2].drawPriority;
        });

        things.removeAt(snapPoints.first.item2);
        recomputeIntersections();
      }

      redraw();
    }
  }

  void onMouseUp(MouseEvent e) {
    e.preventDefault();
    if (e.button == 0) {
      if (hoveredPoint != null && _tool != null) {
        _tool.addPoint(hoveredPoint, things);
        recomputeIntersections();
        redraw();
      }
    }
  }
}
