// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:sketchgrid/sketchgrid.dart';

final tools = {
  SketchTool.gridline: 'Gridline',
  SketchTool.arc: 'Arc',
  SketchTool.line: 'Line'
};

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
  // CSS styles
  final buttonStyle = ['mdl-button', 'mdl-js-button', 'mdl-js-ripple-effect'];
  final selectedToolStyle = ['mdl-button--raised', 'tool-selected'];

  // Stream that indicates if the gridline tool is selected.
  // ignore: close_sinks
  final gridlineIsOn = new StreamController<bool>.broadcast();

  // Setup canvas.
  final sketch = new SketchGrid(querySelector('#sketcharea'));

  // Get tool container.
  final toolset = querySelector('.sketchgrid-toolset');

  // Tool button handling.
  final buttons = new Map<SketchTool, ButtonElement>();
  final setTool = (SketchTool tool) {
    sketch.tool = tool;
    gridlineIsOn.add(tool == SketchTool.gridline);
    buttons.values.forEach((btn) => btn.classes.removeAll(selectedToolStyle));
    buttons[tool].classes.addAll(selectedToolStyle);
  };

  // Create tool buttons.
  tools.forEach((key, name) {
    final button = new ButtonElement()
      ..classes.addAll(buttonStyle)
      ..text = name;
    button.onClick.listen((_) {
      setTool(key);
    });
    buttons[key] = button;
    toolset.children.insert(0, button);
  });

  // Setup menus.
  setupMenu(
      querySelector('#gridline-type'),
      querySelector('#gridline-type + ul'),
      gridlineTypes,
      gridlineIsOn.stream,
      (type) {});
  setupMenu(
      querySelector('#gridline-constraint'),
      querySelector('#gridline-constraint + ul'),
      gridlineConstraints,
      gridlineIsOn.stream,
      (constraint) {});

  setTool(SketchTool.line);
}

void setupMenu<T>(ButtonElement button, UListElement ul, Map<String, T> values,
    Stream<bool> activate, void callback(T value)) {
  activate.listen((v) {
    button.disabled = !v;
  });

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
