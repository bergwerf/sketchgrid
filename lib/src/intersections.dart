// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Compute all intersection points between two things.
List<Vector2> thingIntersection(SketchThing a, SketchThing b) {
  final list = new List<Vector2>();
  if (a is LineThing && b is LineThing) {
    final v = a.ray.intersectRay(b.ray);
    if (v != null && a.containsIntersection(v) && b.containsIntersection(v)) {
      list.add(v);
    }
  }

  return list;
}
