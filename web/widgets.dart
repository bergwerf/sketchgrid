// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:htgen/dynamic.dart' as ht;

class MaterialTabs {
  DivElement parent, tabbar;

  MaterialTabs() {
    parent = new DivElement();
    parent.classes.addAll(['mdl-tabs', 'mdl-js-tabs', 'mdl-js-ripple-effect']);
    tabbar = new DivElement();
    tabbar.classes.add('mdl-tabs__tab-bar');
    parent.append(tabbar);
  }

  Node get node => parent;

  void addTab(String label,
      {bool selected: false,
      List<String> classes: const [],
      void onSelect(),
      List<Element> content: const []}) {
    final tabHead = new AnchorElement();
    tabHead.classes.add('mdl-tabs__tab');
    final idPre = label.split(' ').join('-').toLowerCase();
    tabHead.href = '#$idPre-tab';
    tabHead.text = label;
    tabHead.onClick.listen((_) => onSelect());

    final tabBody = new DivElement();
    tabBody.style.display = 'none';
    tabBody.classes.add('mdl-tabs__panel');
    tabBody.classes.addAll(classes);
    tabBody.id = '$idPre-tab';

    tabBody.children.addAll(content);

    if (selected) {
      tabHead.classes.add('is-active');
      tabBody.classes.add('is-active');
    }

    tabbar.append(tabHead);
    parent.append(tabBody);
  }

  void showTabs() {
    // Initial setup.
    for (final elm in parent.children.sublist(1)) {
      elm.style.removeProperty('display');
    }
  }
}

Element _createIcon(List<int> coords) {
  final iconElement = new SpanElement();
  iconElement.classes.add('sketch-icon');
  iconElement.style.backgroundPosition =
      '${coords[0]*-24}px ${coords[1]*-24}px';
  return iconElement;
}

Element materialButton(String label,
    {List<int> icon: const [], void handle(ButtonElement btn)}) {
  const styles = const ['mdl-button', 'mdl-js-button', 'mdl-js-ripple-effect'];
  final button = new ButtonElement()
    ..classes.addAll(styles)
    ..append(new SpanElement()..text = label);
  button.onClick.listen((_) => handle(button));

  // If icon sprite coordinates are defined.
  // Most styles are contained in the .sketch-icon CSS class.
  if (icon.length == 2) {
    button.children.insert(0, _createIcon(icon));
  }

  return button;
}

Element materialCheckbox(String idPrefix, String label,
    {List<int> icon: const [], void handle(bool value)}) {
  final id = '$idPrefix-checkbox';
  final checkbox =
      ht.input('#$id.mdl-checkbox__input', attrs: {'type': 'checkbox'});
  checkbox.onChange.listen((_) => handle(checkbox.checked));
  return ht.span([
    ht.label('.mdl-checkbox.mdl-js-checkbox.mdl-js-ripple-effect', c: [
      checkbox,
      ht.span(['.mdl-checkbox__label', label]),
      icon.length == 2 ? _createIcon(icon) : null
    ])
  ]);
}

Element materialMenu<T>(String id, List<MenuItem<T>> items,
    {void handle(T data)}) {
  final buttonIcon = ht.span('');
  final buttonText = ht.span('');

  return ht.span([
    ht.button('#$id.dropdown.mdl-button.mdl-js-button.mdl-js-ripple-effect',
        c: [
          buttonIcon,
          buttonText,
          ht.span(['.material-icons', 'arrow_drop_down'])
        ]),
    ht.ul('.mdl-menu.mdl-menu--bottom-left.mdl-js-menu.mdl-js-ripple-effect',
        c: items.map((item) {
          void setButton() {
            handle(item.data);
            buttonText.text = item.label;
            buttonIcon.children
              ..clear()
              ..add(_createIcon(item.icon));
          }

          if (buttonText.text.isEmpty) {
            setButton();
          }

          return ht.li('.mdl-menu__item',
              c: [_createIcon(item.icon), ht.span('')..text = item.label])
            ..onClick.listen((_) => setButton());
        }).toList())
      ..setAttribute('for', id)
  ]);
}

class MenuItem<T> {
  final String label;
  final List<int> icon;
  final T data;
  MenuItem(this.label, this.data, this.icon);
}
