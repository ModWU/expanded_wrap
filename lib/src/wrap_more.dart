import 'package:flutter/cupertino.dart';
import 'render_wrap_more.dart';
import 'wrap_more_element.dart';
import 'wrap_more_definition.dart';

class WrapMore extends RenderObjectWidget {
  /// Creates a wrap layout.
  ///
  /// By default, the wrap layout is horizontal and both the children and the
  /// runs are aligned to the start.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to decide which direction to lay the children in or to
  /// disambiguate `start` or `end` values for the main or cross axis
  /// directions, the [textDirection] must not be null.
  const WrapMore({
    super.key,
    required this.children,
    required this.dropChild,
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
    this.dropChildSpacing = 0.0,
    this.isExpanded = false,
    this.nearChild,
    this.nearDirection = AxisDirection.right,
    this.nearSpacing = 0.0,
    this.nearAlignment = WrapMoreNearAlignment.start,
    this.alwaysShowNearChild = false,
  })  : assert(spacing >= 0.0),
        assert(runSpacing >= 0.0),
        assert(nearSpacing >= 0.0),
        assert(dropChildSpacing == null || dropChildSpacing >= 0.0);

  /// The direction to use as the main axis.
  ///
  /// For example, if [direction] is [Axis.horizontal], the default, the
  /// children are placed adjacent to one another in a horizontal run until the
  /// available horizontal space is consumed, at which point a subsequent
  /// children are placed in a new run vertically adjacent to the previous run.
  final Axis direction;

  /// How the children within a run should be placed in the main axis.
  ///
  /// For example, if [alignment] is [WrapAlignment.center], the children in
  /// each run are grouped together in the center of their run in the main axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  final WrapMoreAlignment alignment;

  /// How much space to place between children in a run in the main axis.
  ///
  /// For example, if [spacing] is 10.0, the children will be spaced at least
  /// 10.0 logical pixels apart in the main axis.
  ///
  /// If there is additional free space in a run (e.g., because the wrap has a
  /// minimum size that is not filled or because some runs are longer than
  /// others), the additional free space will be allocated according to the
  /// [alignment].
  ///
  /// Defaults to 0.0.
  final double spacing;

  /// How the runs themselves should be placed in the cross axis.
  ///
  /// For example, if [runAlignment] is [WrapAlignment.center], the runs are
  /// grouped together in the center of the overall [WrapMore] in the cross axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  final WrapMoreAlignment runAlignment;

  /// How much space to place between the runs themselves in the cross axis.
  ///
  /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
  /// 10.0 logical pixels apart in the cross axis.
  ///
  /// If there is additional free space in the overall [WrapMore] (e.g., because
  /// the wrap has a minimum size that is not filled), the additional free space
  /// will be allocated according to the [runAlignment].
  ///
  /// Defaults to 0.0.
  final double runSpacing;

  /// How the children within a run should be aligned relative to each other in
  /// the cross axis.
  ///
  /// For example, if this is set to [WrapCrossAlignment.end], and the
  /// [direction] is [Axis.horizontal], then the children within each
  /// run will have their bottom edges aligned to the bottom edge of the run.
  ///
  /// Defaults to [WrapCrossAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  final WrapMoreCrossAlignment crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If the [direction] is [Axis.horizontal], this controls order in which the
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [alignment] property's [WrapAlignment.start] and
  /// [WrapAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [alignment] is either [WrapAlignment.start] or [WrapAlignment.end], or
  /// there's more than one child, then the [textDirection] (or the ambient
  /// [Directionality]) must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the order in which
  /// runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
  /// [WrapCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the
  /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
  /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
  /// [WrapCrossAlignment.end], or there's more than one child, then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  final TextDirection? textDirection;

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [alignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [alignment]
  /// is either [WrapAlignment.start] or [WrapAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
  /// [WrapCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
  /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
  /// [WrapCrossAlignment.end], or there's more than one child, then the
  /// [verticalDirection] must not be null.
  final VerticalDirection verticalDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// Always displayed at the end of the list, only when there is an
  /// expanded/collapsed state present.
  final Widget? dropChild;

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

  /// Whether to always display the [nearChild], if true, then display; Otherwise,
  /// if there is more data, the [nearChild] will be displayed. The default is false,
  /// usually used for the purpose of displaying more data.
  final bool alwaysShowNearChild;

  /// Expand or not, default is false.
  final bool isExpanded;

  @override
  RenderWrapMore createRenderObject(BuildContext context) {
    return RenderWrapMore(
      direction: direction,
      alignment: alignment,
      spacing: spacing,
      runAlignment: runAlignment,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      verticalDirection: verticalDirection,
      clipBehavior: clipBehavior,
      minLines: minLines,
      maxLines: maxLines,
      dropChildSpacing: dropChildSpacing,
      nearDirection: nearDirection,
      nearSpacing: nearSpacing,
      nearAlignment: nearAlignment,
      alwaysShowNearChild: alwaysShowNearChild,
      isExpanded: isExpanded,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderWrapMore renderObject) {
    renderObject
      ..direction = direction
      ..alignment = alignment
      ..spacing = spacing
      ..runAlignment = runAlignment
      ..runSpacing = runSpacing
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..verticalDirection = verticalDirection
      ..clipBehavior = clipBehavior
      ..minLines = minLines
      ..maxLines = maxLines
      ..dropChildSpacing = dropChildSpacing
      ..isExpanded = isExpanded
      ..nearDirection = nearDirection
      ..nearSpacing = nearSpacing
      ..nearAlignment = nearAlignment
      ..alwaysShowNearChild = alwaysShowNearChild;
  }

  final List<Widget> children;

  @override
  WrapMoreElement createElement() => WrapMoreElement(this);
}
