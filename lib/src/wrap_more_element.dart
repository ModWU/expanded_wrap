import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'render_wrap_more.dart';
import 'wrap_more.dart';

class WrapMoreElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  WrapMoreElement(WrapMore super.widget)
      : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children));

  @override
  ContainerRenderObjectMixin<RenderObject,
      ContainerParentDataMixin<RenderObject>> get renderObject {
    return super.renderObject as ContainerRenderObjectMixin<RenderObject,
        ContainerParentDataMixin<RenderObject>>;
  }

  /// The current list of children of this element.
  ///
  /// This list is filtered to hide elements that have been forgotten (using
  /// [forgetChild]).
  @protected
  @visibleForTesting
  Iterable<Element> get children =>
      _children.where((Element child) => !_forgottenChildren.contains(child));

  late List<Element> _children;

  Element? get dropElement =>
      _forgottenChildren.contains(_dropElement) ? null : _dropElement;
  Element? _dropElement;

  Element? get nearElement =>
      _forgottenChildren.contains(_nearElement) ? null : _nearElement;
  Element? _nearElement;

  Element? get separateElement =>
      _forgottenChildren.contains(_separateElement) ? null : _separateElement;
  Element? _separateElement;
  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  // [dropChild] slot
  final IndexedSlot dropElementSlot = IndexedSlot(-1, null);

  // [nearChild] slot
  final IndexedSlot nearElementSlot = IndexedSlot(-2, null);

  // [separateChild] slot
  final IndexedSlot separateElementSlot = IndexedSlot(-3, null);

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?> slot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(renderObject.debugValidateChild(child));
    if (slot == dropElementSlot) {
      final RenderWrapMore parent = renderObject as RenderWrapMore;
      assert(child is RenderBox);
      parent.dropRenderBox = child as RenderBox;
    } else if (slot == nearElementSlot) {
      final RenderWrapMore parent = renderObject as RenderWrapMore;
      assert(child is RenderBox);
      parent.nearRenderBox = child as RenderBox;
    } else if (slot == separateElementSlot) {
      final RenderWrapMore parent = renderObject as RenderWrapMore;
      assert(child is RenderBox);
      parent.separateRenderBox = child as RenderBox;
    } else {
      renderObject.insert(child, after: slot.value?.renderObject);
    }
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, IndexedSlot<Element?> oldSlot,
      IndexedSlot<Element?> newSlot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: newSlot.value?.renderObject);
    assert(renderObject == this.renderObject);
    // 不需要处理_dropElement/_nearElement/_separateElement
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject; //RenderWrapMore renderObject
    assert(child.parent == renderObject);
    if (slot == dropElementSlot) {
      final RenderWrapMore parent = renderObject as RenderWrapMore;
      parent.dropRenderBox = null;
    } else if (slot == nearElementSlot) {
      final RenderWrapMore parent = renderObject as RenderWrapMore;
      parent.nearRenderBox = null;
    } else if (slot == separateElementSlot) {
      final RenderWrapMore parent = renderObject as RenderWrapMore;
      parent.separateRenderBox = null;
    } else {
      renderObject.remove(child);
    }
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_dropElement != null && !_forgottenChildren.contains(_dropElement)) {
      visitor(_dropElement!);
    }
    if (_nearElement != null && !_forgottenChildren.contains(_nearElement)) {
      visitor(_nearElement!);
    }
    if (_separateElement != null &&
        !_forgottenChildren.contains(_separateElement)) {
      visitor(_separateElement!);
    }
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    if (child == _dropElement) {
      _dropElement = null;
    }
    if (child == _nearElement) {
      _nearElement = null;
    }
    if (child == _separateElement) {
      _separateElement = null;
    }
    super.forgetChild(child);
  }

  bool _debugCheckHasAssociatedRenderObject(Element newChild) {
    assert(() {
      if (newChild.renderObject == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                  'The children of `WrapMoreElement` must each has an associated render object.'),
              ErrorHint(
                'This typically means that the `${newChild.widget}` or its children\n'
                'are not a subtype of `RenderObjectWidget`.',
              ),
              newChild.describeElement(
                  'The following element does not have an associated render object'),
              DiagnosticsDebugCreator(DebugCreator(newChild)),
            ]),
          ),
        );
      }
      return true;
    }());
    return true;
  }

  @override
  Element inflateWidget(Widget newWidget, Object? newSlot) {
    final Element newChild = super.inflateWidget(newWidget, newSlot);
    assert(_debugCheckHasAssociatedRenderObject(newChild));
    return newChild;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final WrapMore wrapMore = widget as WrapMore;
    final List<Element> children =
        List<Element>.filled(wrapMore.children.length, _NullElement.instance);
    Element? previousChild;
    for (int i = 0; i < children.length; i += 1) {
      final Element newChild = inflateWidget(
          wrapMore.children[i], IndexedSlot<Element?>(i, previousChild));
      children[i] = newChild;
      previousChild = newChild;
    }
    _children = children;

    _dropElement = updateChild(
      _dropElement,
      wrapMore.dropChild,
      dropElementSlot,
    );
    _nearElement = updateChild(
      _nearElement,
      wrapMore.nearChild,
      nearElementSlot,
    );
    _separateElement = updateChild(
      _separateElement,
      wrapMore.separate,
      separateElementSlot,
    );
  }

  @override
  void update(WrapMore newWidget) {
    super.update(newWidget);
    final WrapMore wrapMore = widget as WrapMore;
    assert(widget == newWidget);
    assert(!debugChildrenHaveDuplicateKeys(widget, wrapMore.children));
    _children = updateChildren(
      _children,
      wrapMore.children,
      forgottenChildren: _forgottenChildren,
    );
    _dropElement = updateChild(
      _dropElement,
      wrapMore.dropChild,
      dropElementSlot,
    );
    _nearElement = updateChild(
      _nearElement,
      wrapMore.nearChild,
      nearElementSlot,
    );
    _separateElement = updateChild(
      _separateElement,
      wrapMore.separate,
      separateElementSlot,
    );
    _forgottenChildren.clear();
  }
}

/// Used as a placeholder in [List<Element>] objects when the actual
/// elements are not yet determined.
class _NullElement extends Element {
  _NullElement() : super(const _NullWidget());

  static _NullElement instance = _NullElement();

  @override
  bool get debugDoingBuild => throw UnimplementedError();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
