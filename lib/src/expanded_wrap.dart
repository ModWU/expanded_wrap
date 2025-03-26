import 'package:flutter/material.dart';

import 'wrap_more.dart';
import 'wrap_more_definition.dart';
import 'wrap_more_setter.dart';

/// Wrap with expand and collapse function.
class ExpandedWrap extends StatefulWidget {
  const ExpandedWrap({
    super.key,
    required this.children,
    this.controller,
    this.notifier,
    this.dropBuilder,
    this.dropChild,
    this.direction = Axis.horizontal,
    this.alignment = WrapMoreAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapMoreAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapMoreCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
    this.minLines = 1,
    this.maxLines,
    this.dropChildSpacing,
    this.initialExpanded = false,
    this.nearDirection = AxisDirection.right,
    this.nearSpacing = 0.0,
    this.nearAlignment = WrapMoreNearAlignment.start,
    this.nearChild,
    this.nearBuilder,
    this.alwaysShowNearChild = false,
    this.separate,
  });

  @override
  State<StatefulWidget> createState() => _ExpandedWrapState();

  /// children
  final List<Widget> children;

  /// controller
  final ExpandedWrapController? controller;

  /// notifier, provide the expandable state.
  /// Use it when needing to check whether there is more data available.
  final ExpandedWrapNotifier? notifier;

  /// see [Wrap]
  final Axis direction;

  /// see [Wrap]
  final WrapMoreAlignment alignment;

  /// see [Wrap]
  final double spacing;

  /// see [Wrap]
  final WrapMoreAlignment runAlignment;

  /// see [Wrap]
  final double runSpacing;

  /// see [Wrap]
  final WrapMoreCrossAlignment crossAxisAlignment;

  /// see [Wrap]
  final TextDirection? textDirection;

  /// see [Wrap]
  final VerticalDirection verticalDirection;

  /// see [Wrap]
  final Clip clipBehavior;

  /// Always displayed at the end of the list, only when there is an
  /// expanded/collapsed state present.
  final Widget? dropChild;

  /// The construction of the final component is always added at the
  /// end of the list and always displayed.
  final WrapChildBuilder? dropBuilder;

  /// The minimum row, if the total number of rows is greater than the
  /// minimum row, [dropChild] will be displayed, otherwise it will not
  /// be displayed. The default minimum behavior is 1 line.
  final int minLines;

  /// When the maximum row is null, all rows will be displayed in the expanded
  /// state. Otherwise, data exceeding the maximum row size will not be displayed.
  /// If the minimum row is smaller than the maximum row, there is a concept of
  /// expansion when the total number of rows exceeds the minimum row in the
  /// collapsed state; Otherwise, the total number of rows is the maximum value
  /// of the smallest and largest rows.
  final int? maxLines;

  /// The distance from [dropChild] on the main axis is the same as [spacing] by default.
  final double? dropChildSpacing;

  /// The initialized expansion state is set to false by default.
  final bool initialExpanded;

  /// The layout direction of the closely attached near child defaults
  /// to being close to the right end.
  final AxisDirection nearDirection;

  /// The gap between adjacent near child defaults to 0.0.
  final double nearSpacing;

  /// Align closely to the position of the near child and start aligning by default.
  /// Try to avoid using [RapMoreNearAlignment.stretch] as much as possible, as it
  /// may cause issues Perform secondary layout for the [nearChild].
  final WrapMoreNearAlignment nearAlignment;

  /// Closely attached components are laid out according to the direction of [nearDirection].
  ///
  /// When [alwaysShowNearChild] is true, it always displays the [nearChild];
  /// Otherwise, if there is more data not displayed, it will be displayed;
  /// otherwise, it will not be displayed.
  final Widget? nearChild;

  /// The builder of the [nearChild] component.
  final WrapChildBuilder? nearBuilder;

  /// Whether to always display the [nearChild], if true, then display; Otherwise,
  /// if there is more data, the [nearChild] will be displayed. The default is false,
  /// usually used for the purpose of displaying more data.
  final bool alwaysShowNearChild;

  /// Insert a separator component between each element on main axis.
  /// After setting [separate], the parameter [spacing] will become invalid.
  final Widget? separate;
}

class _ExpandedWrapState extends State<ExpandedWrap> {
  ExpandedWrapController get effectController =>
      (_controller ??= ExpandedWrapController());
  ExpandedWrapController? _controller;

  @override
  void initState() {
    super.initState();
    _updateController();
    effectController._isExpanded = widget.initialExpanded;
    widget.notifier?._attachController(effectController);
  }

  void _updateController() {
    final oldController = _controller;
    final controller = widget.controller ?? effectController;
    if (controller != oldController) {
      final bool oldExpanded = effectController.isExpanded;
      oldController?.removeListener(_rebuild);
      oldController?.dispose();
      _controller = controller;
      controller.isExpanded = oldExpanded;
      controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ExpandedWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != effectController) {
      _updateController();
    }

    if (widget.notifier != oldWidget.notifier) {
      oldWidget.notifier?._detachController();
      widget.notifier?._attachController(effectController);
    }
  }

  @override
  void dispose() {
    widget.notifier?._detachController();
    effectController.removeListener(_rebuild);
    if (effectController != widget.controller) {
      effectController.dispose();
    }
    _controller = null;
    super.dispose();
  }

  Widget? _buildDropChild(BuildContext context) {
    Widget? child = widget.dropChild;
    if (widget.dropBuilder case final dropBuilder?) {
      child = dropBuilder(context, effectController, child);
    }
    return child;
  }

  Widget? _buildNearChild(BuildContext context) {
    Widget? child = widget.nearChild;
    if (widget.nearBuilder case final nearBuilder?) {
      child = nearBuilder(context, effectController, child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return WrapMore(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      direction: widget.direction,
      alignment: widget.alignment,
      crossAxisAlignment: widget.crossAxisAlignment,
      runAlignment: widget.runAlignment,
      verticalDirection: widget.verticalDirection,
      textDirection: widget.textDirection,
      isExpanded: effectController.isExpanded,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      dropChild: _buildDropChild(context),
      clipBehavior: widget.clipBehavior,
      dropChildSpacing: widget.dropChildSpacing,
      nearDirection: widget.nearDirection,
      nearSpacing: widget.nearSpacing,
      nearAlignment: widget.nearAlignment,
      nearChild: _buildNearChild(context),
      alwaysShowNearChild: widget.alwaysShowNearChild,
      separate: widget.separate,
      setter: widget.notifier,
      children: widget.children,
    );
  }
}

/// Expand/Collapse Controller
class ExpandedWrapController extends ChangeNotifier {
  bool? _isExpanded;

  /// Is Expanded
  bool get isExpanded => _isExpanded ?? false;

  /// Set Expand/Collapse
  set isExpanded(bool value) {
    if (value == _isExpanded) {
      return;
    }
    _isExpanded = value;
    notifyListeners();
  }

  /// Toggle this expanded State
  void toggle() {
    isExpanded = !isExpanded;
  }

  @override
  void dispose() {
    _isExpanded = null;
    super.dispose();
  }
}

/// Expand/Collapse Controller
class ExpandedWrapNotifier extends ChangeNotifier with WrapMoreSetter {
  // Auto-bind a Controller
  ExpandedWrapController? _controller;

  void _attachController(ExpandedWrapController controller) {
    _controller = controller;
    controller.removeListener(notifyListeners);
    controller.addListener(notifyListeners);
  }

  void _detachController() {
    _controller?.removeListener(notifyListeners);
    _controller = null;
  }

  /// Whether Expandable
  @override
  bool get expandable => _expandable ?? false;
  bool? _expandable;

  /// Toggle this expanded State
  void toggle() => _controller?.toggle();

  /// Is Expanded
  bool get isExpanded => _controller?.isExpanded ?? false;

  /// Set Expand/Collapse
  void setExpanded(bool value) => _controller?.isExpanded = value;

  @override
  void dispose() {
    _controller?.removeListener(notifyListeners);
    _controller = null;
    super.dispose();
  }

  @override
  void setExpandable(bool value) {
    if (value == _expandable) {
      return;
    }
    _expandable = value;
    notifyListeners();
  }
}

/// this [dropChild]/[nearChild] builder
typedef WrapChildBuilder = Widget Function(
  BuildContext context,
  ExpandedWrapController controller,
  Widget? child,
);
