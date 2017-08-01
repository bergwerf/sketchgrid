// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Shortcut for pow([x], 2)
num pow2(num x) => pow(x, 2);

/// Color vector to rgba string.
String rgba(Vector4 c) => [
      'rgba(',
      c.rgb.storage.map((c) => (c * 255).round().toString()).join(','),
      ',${c.a})'
    ].join();

/// Get bounding box around line between [from] and [to].
Aabb2 getLineBBox(Vector2 from, Vector2 to) {
  final extents = ((to - from) / 2.0)..absolute();
  final bbox = new Aabb2.centerAndHalfExtents(
      (from + to) / 2.0, vec2(max(extents.x, 0.1), max(extents.y, 0.1)));
  return bbox;
}

/// Turn [v] into unit vector.
Vector2 unitVector(Vector2 v) {
  return v / v.length;
}

/// Compute vector projection of [a] on [v].
Vector2 vec2Projection(Vector2 a, Vector2 v) {
  return unitVector(v) * (a.dot(v) / v.length);
}

/// Get angle of [vector] relative to origin.
num vec2Angle(Vector2 vector) {
  return atan2(vector.y, vector.x);
}

/// Get angle of [vector] relative to origin such that the angle is in {0 2PI}.
num vec2AnglePositive(Vector2 vector) {
  final a = vec2Angle(vector);
  return a < 0 ? a + 2 * PI : a;
}

/// Get unit vector that is perpendicular to [vector].
Vector2 vec2Perpendicular(Vector2 vector) {
// <a b>*<x y> = 0 --> ax + by = 0, x + by = 0, b = -x/y
  if (vector.y == 0) {
    return vec2(0, 1);
  } else {
    final v = vec2(1, -vector.x / vector.y);
    return unitVector(v);
  }
}

/// Generate unit vector from [angle] with [xScale] and [yScale].
Vector2 vec2FromAngle(num angle, [num xScale = 1, num yScale = 1]) {
  return vec2(xScale * cos(angle), yScale * sin(angle));
}

/// Check if [value] is almost equal to [compare] by [margin].
bool isAlmost(num value, num compare, num margin) {
  return value > compare - margin && value < compare + margin;
}

/// Get last [n] points from [list]. Also remove them if [remove] it true.
List<T> getNPoints<T>(int n, List<T> list, bool remove) {
  if (list.length < n) {
    throw new RangeError('list is too short');
  }

  if (remove) {
    return new List<T>.generate(n, (i) => list.removeLast()).reversed.toList();
  } else {
    return new List<T>.generate(n, (i) => list[list.length - n + i]);
  }
}
