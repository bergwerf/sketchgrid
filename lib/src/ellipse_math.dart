// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of sketchgrid;

/// Compute intersection points between line given by y = [m]x + [c] and ellipse
/// given by x^2/[a]^2 + y^2/[b]^2 = 1.
/// See: http://www.ambrsoft.com/TrigoCalc/Circles2/Ellipse/EllipseLine.htm
Tuple2<Vector2, Vector2> ellipseLineIntersection(num a, num b, num m, num c) {
  final sqrtTerm = pow2(a) * pow2(m) + pow2(b) - pow2(c);
  final denominator = pow2(a) * pow2(m) + pow2(b);

  if (sqrtTerm < 0 || denominator == 0) {
    return null;
  } else {
    final xTerm = -pow2(a) * m * c;
    final yTerm = pow2(b) * c;

    final x1 = (xTerm + a * b * sqrt(sqrtTerm)) / denominator;
    final x2 = (xTerm - a * b * sqrt(sqrtTerm)) / denominator;
    final y1 = (yTerm + a * b * m * sqrt(sqrtTerm)) / denominator;
    final y2 = (yTerm - a * b * m * sqrt(sqrtTerm)) / denominator;

    return new Tuple2<Vector2, Vector2>(vec2(x1, y1), vec2(x2, y2));
  }
}

/// Check if angle [a] is between [from] and [to].
bool angleIsBetween(num a, num from, num to) {
  // Make sure to >= from.
  while (to < from) {
    // ignore: parameter_assignments
    to += 2 * PI;
  }
  // Make sure a >= from.
  while (a < from) {
    // ignore: parameter_assignments
    a += 2 * PI;
  }
  // Compare
  return a >= from && a <= to;
}

/// Get point on ellipse section closest to the given [point]. Ellipse section
/// is given by x^2/[a]^2 + y^2/[b]^2 = 1 and goes from [startAngle] to
/// [endAngle]. If [point] is at (0, 0), then null is returned.
Vector2 ellipseSectionClosestPoint(
    Vector2 point, num a, num b, num startAngle, num endAngle) {
  if (point.x == 0 && point.y == 0) {
    return null;
  }

  final scaledX = point.x / a;
  final scaledY = point.y / b;
  final unitV = unitVector(vec2(scaledX, scaledY));
  final angle = vec2AnglePositive(unitV);

  if (angleIsBetween(angle, startAngle, endAngle)) {
    return unitV..multiply(vec2(a, b));
  } else {
    return null;
  }
}
