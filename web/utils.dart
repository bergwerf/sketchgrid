// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

T _createElement<T extends Element>(
    T createdElement, String selector, List<Element> c, void store(T element)) {
  final classNames = selector.split('.')
    ..removeWhere((str) => str.isEmpty)
    ..removeWhere((str) {
      if (str.startsWith('#')) {
        createdElement.id = str.substring(1);
        return true;
      } else {
        return false;
      }
    });

  createdElement.classes.addAll(classNames);
  c.where((c) => c != null).forEach((child) => createdElement.append(child));

  if (store != null) {
    store(createdElement);
  }
  return createdElement;
}

DivElement div(String selector,
        {List<Element> c: const [], void store(DivElement element)}) =>
    _createElement<DivElement>(new DivElement(), selector, c, store);

SpanElement span(String selector,
        {List<Element> c: const [], void store(SpanElement element)}) =>
    _createElement<SpanElement>(new SpanElement(), selector, c, store);

LabelElement labelElm(String selector,
        {List<Element> c: const [], void store(LabelElement element)}) =>
    _createElement<LabelElement>(new LabelElement(), selector, c, store);

ButtonElement buttonElm(String selector,
        {List<Element> c: const [], void store(ButtonElement element)}) =>
    _createElement<ButtonElement>(new ButtonElement(), selector, c, store);

UListElement ulElm(String selector,
        {List<Element> c: const [], void store(UListElement element)}) =>
    _createElement<UListElement>(new UListElement(), selector, c, store);

LIElement liElm(String selector,
        {List<Element> c: const [], void store(LIElement element)}) =>
    _createElement<LIElement>(new LIElement(), selector, c, store);

InputElement inputElm(String selector,
        {String type: 'text',
        List<Element> c: const [],
        void store(InputElement element)}) =>
    _createElement<InputElement>(
        new InputElement(type: type), selector, c, store);
