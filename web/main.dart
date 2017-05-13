// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:sketchgrid/sketchgrid.dart';

final lineSegmentTool = new LineSegmentTool();
final ellipseTool = new EllipticCurveTool();
final gridLineTool = new GridLineTool();

enum SketchToolType { linesegment, ellipse, gridline }
final toolButtons = {
  SketchToolType.linesegment: 'Line',
  SketchToolType.ellipse: 'Arc',
  SketchToolType.gridline: 'Gridline'
};
final tools = {
  SketchToolType.linesegment: lineSegmentTool,
  SketchToolType.ellipse: ellipseTool,
  SketchToolType.gridline: gridLineTool
};

final gridLineRuler = {'Normal': false, 'Ruler': true};
final gridLineConstraints = {
  'Two points': GridlineConstraint.twoPoints,
  'Horizontal': GridlineConstraint.horizontal,
  'Vertical': GridlineConstraint.vertical,
  'Parallel': GridlineConstraint.parallel,
  'Perpendicular': GridlineConstraint.perpendicular,
  'Bisect': GridlineConstraint.bisect,
  'Single tangent': GridlineConstraint.singleTangent,
  'Double tangent': GridlineConstraint.doubleTangent
};

void main() {
  // CSS styles
  final buttonStyle = ['mdl-button', 'mdl-js-button', 'mdl-js-ripple-effect'];
  final selectedToolStyle = ['mdl-button--raised', 'tool-selected'];

  // Stream that indicates if the gridline tool is selected.
  // ignore: close_sinks
  final gridLineIsOn = new StreamController<bool>.broadcast();

  // Setup canvas.
  final sketch = new SketchGrid(querySelector('#sketcharea'));

  // Get tool container.
  final toolset = querySelector('.sketchgrid-toolset');

  // Tool button handling.
  final buttons = new Map<SketchToolType, ButtonElement>();
  final setTool = (SketchToolType tool) {
    sketch.tool = tools[tool];
    gridLineIsOn.add(tool == SketchToolType.gridline);
    buttons.values.forEach((btn) => btn.classes.removeAll(selectedToolStyle));
    buttons[tool].classes.addAll(selectedToolStyle);
  };

  // Create tool buttons.
  toolButtons.keys.toList().reversed.forEach((key) {
    final button = new ButtonElement()
      ..classes.addAll(buttonStyle)
      ..text = toolButtons[key];
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
      gridLineRuler,
      gridLineIsOn.stream, (isOn) {
    gridLineTool.ruler = isOn;
  });
  setupMenu(
      querySelector('#gridline-constraint'),
      querySelector('#gridline-constraint + ul'),
      gridLineConstraints,
      gridLineIsOn.stream, (constraint) {
    gridLineTool.constraint = constraint;
    gridLineTool.points.clear();
  });

  setTool(SketchToolType.gridline);
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
