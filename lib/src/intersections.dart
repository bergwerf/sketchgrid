// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Compute all intersection points between two things.
List<Vector2> thingIntersection(SketchThing a, SketchThing b) {
  final list = new List<Vector2>();
  if (a is RayThing && b is RayThing) {
    final v = a.ray.intersectRay(b.ray);
    if (v != null && a.containsIntersection(v) && b.containsIntersection(v)) {
      list.add(v);
    }
  } else if (a is EllipticCurve && b is RayThing ||
      b is EllipticCurve && a is RayThing) {
    // TODO: do not intersect in open parts (transform + measure angle).
    final EllipticCurve elipt = a is EllipticCurve ? a : b;
    final RayThing linet = a is EllipticCurve ? b : a;

    final elip = createEllipse(elipt.center, elipt.radius, elipt.rotation);
    final line = createLineConic(linet.ray.origin, linet.ray.direction);
    final out = intersectConics(elip.homogeneousMatrix, line.homogeneousMatrix);

    for (final v in out) {
      if (linet.containsIntersection(v)) {
        list.add(v);
      }
    }
  } else if (a is EllipticCurve && b is EllipticCurve) {
    final am = createEllipse(a.center, a.radius, a.rotation);
    final bm = createEllipse(b.center, b.radius, b.rotation);
    list.addAll(intersectConics(am.homogeneousMatrix, bm.homogeneousMatrix));
  }

  return list;
}
