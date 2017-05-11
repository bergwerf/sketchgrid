// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Shortcut for 2D vector.
Vector2 vec2(num x, num y) => new Vector2(x, y);

/// Shortcut for 3D vector.
Vector3 vec3(num x, num y, num z) => new Vector3(x, y, z);

/// Color vector to rgba string.
String rgba(Vector4 c) => [
      'rgba(',
      c.rgb.storage.map((c) => (c * 255).round().toString()).join(','),
      ',${c.a})'
    ].join();

/// Compute vector projection of [a] on [v].
Vector2 vectorProjection(Vector2 a, Vector2 v) {
  return (v / v.length) * (a.dot(v) / v.length);
}

/// Get bounding box around line between [from] and [to].
Aabb2 getLineBBox(Vector2 from, Vector2 to) {
  final extents = ((to - from) / 2.0)..absolute();
  final bbox = new Aabb2.centerAndHalfExtents(
      (from + to) / 2.0, vec2(max(extents.x, 0.1), max(extents.y, 0.1)));
  return bbox;
}
