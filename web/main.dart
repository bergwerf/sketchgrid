// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:sketchgrid/sketchgrid.dart';
import 'widgets.dart';

final lineTool = new LineSegmentTool();
final curveTool = new EllipticCurveTool();
final rulerTool = new RayRulerTool();

void setRaised(ButtonElement btn) {
  const style = const ['mdl-button--raised', 'tool-selected'];
  btn.parent.querySelectorAll('.mdl-button').classes.removeAll(style);
  btn.classes.addAll(style);
}

void main() {
  SketchGrid sketch;

  // Create tabs UI.
  final tabs = new MaterialTabs();
  querySelector('#toolbox').append(tabs.node);

  tabs.addTab('Line', classes: ['sketchgrid-toolbar'], onSelect: () {
    sketch.tool = lineTool;
  }, content: [
    materialButton('Single line', icon: [0, 1], handle: (btn) {
      setRaised(btn);
      lineTool.path = false;
    }),
    materialButton('Line path', icon: [1, 1], handle: (btn) {
      setRaised(btn);
      lineTool.path = true;
    })
  ]);
  setRaised(tabs.parent.children[1].children[0]);

  tabs.addTab('Curve', classes: ['sketchgrid-toolbar'], onSelect: () {
    sketch.tool = curveTool;
  }, content: [
    materialButton('Circle', icon: [2, 1], handle: (btn) {
      setRaised(btn);
      curveTool.isCircle = true;
      curveTool.isSegment = false;
    }),
    materialButton('Arc', icon: [3, 1], handle: (btn) {
      setRaised(btn);
      curveTool.isCircle = true;
      curveTool.isSegment = true;
    }),
    materialButton('Ellipse', icon: [4, 1], handle: (btn) {
      setRaised(btn);
      curveTool.isCircle = false;
      curveTool.isSegment = false;
    })
  ]);
  setRaised(tabs.parent.children[2].children[0]);

  tabs.addTab('Grid', selected: true, classes: ['sketchgrid-toolbar'],
      onSelect: () {
    sketch.tool = rulerTool;
  }, content: [
    materialMenu('rayruler-constraint', [
      new MenuItem('Two points', RulerConstraint.twoPoints, [7, 1]),
      new MenuItem('Horizontal', RulerConstraint.horizontal, [8, 1]),
      new MenuItem('Vertical', RulerConstraint.vertical, [9, 1]),
      new MenuItem('Parallel', RulerConstraint.parallel, [0, 0]),
      new MenuItem('Midline', RulerConstraint.midline, [3, 0]),
      new MenuItem('Perpendicular', RulerConstraint.perpendicular, [1, 0]),
      new MenuItem('Bisect', RulerConstraint.bisect, [2, 0])
    ], handle: (data) {
      rulerTool.constraint = data;
      rulerTool.points.clear();
    }),
    materialCheckbox('', icon: [6, 1], handle: (value) {
      rulerTool.ruler = value;
    })
  ]);

  // Wait with showing to prevent ugly loading behavior.
  new Timer(new Duration(milliseconds: 500), () {
    tabs.showTabs();
    querySelector('#toolbox').style.opacity = '1';

    sketch = new SketchGrid(querySelector('#sketcharea'));
    sketch.tool = rulerTool;
  });
}
