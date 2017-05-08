// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'package:sketchgrid/sketchgrid.dart';

final gridlineTypes = {
  'Single': GridlineType.single,
  'Repeat': GridlineType.repeat
};

final gridlineConstraints = {
  'Two points': GridlineConstraint.twoPoints,
  'Horizontal': GridlineConstraint.horizontal,
  'Vertical': GridlineConstraint.vertical,
  'Parallel': GridlineConstraint.parallel,
  'Perpendicular': GridlineConstraint.perpendicular,
  'Single tangent': GridlineConstraint.singleTangent,
  'Double tangent': GridlineConstraint.doubleTangent
};

void main() {
  // Setup menus.
  setupMenu(querySelector('#gridline-type'),
      querySelector('#gridline-type + ul'), gridlineTypes, (type) {});
  setupMenu(
      querySelector('#gridline-constraint'),
      querySelector('#gridline-constraint + ul'),
      gridlineConstraints,
      (constraint) {});

  // Setup canvas.
  new SketchGrid(querySelector('#sketcharea'));
}

void setupMenu<T>(ButtonElement button, UListElement ul, Map<String, T> values,
    void callback(T value)) {
  final buttonLabel = new SpanElement()..text = values.keys.first;
  button.children.insert(0, buttonLabel);

  values.forEach((key, value) {
    ul.append(new LIElement()
      ..classes.add('mdl-menu__item')
      ..text = key
      ..onClick.listen((_) {
        buttonLabel.text = key;
        callback(value);
      }));
  });
}
