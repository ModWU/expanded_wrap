import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'wrap_more_definition.dart';

typedef _NextChild = RenderBox? Function(RenderBox child);
typedef _PositionChild = void Function(Offset offset, RenderBox child);
typedef _GetChildSize = Size Function(RenderBox child);
//typedef _CrossRange = (double minSize, double maxSize);

class _ChildLayout {
  _ChildLayout(
    this.child,
    this.layoutChild,
    this.childConstraints,
    this.direction, {
    this.spacing = 0.0,
  });

  final RenderBox child;
  final ChildLayouter layoutChild;
  final BoxConstraints childConstraints;
  final Axis direction;
  final double spacing;

  _AxisSize? _axisSize;
  _AxisSize get axisSize {
    assert(_axisSize != null, 'Call this "axisSize" must be after the layout.');
    return _axisSize!;
  }

  bool get hasSize => !(_axisSize?.isEmpty ?? true);

  bool get hasLayout => _axisSize != null;

  _ChildLayout layout({
    double? mainMinSize,
    double? mainMaxSize,
    double? crossMinSize,
    double? crossMaxSize,
    bool force = false,
  }) {
    if (!force && hasLayout) {
      assert(_axisSize != null);
      return this;
    }
    // final BoxConstraints childConstrains =
    //     _CrossAxisConstraints.fromConstraints(
    //   constraints: child.constraints,
    //   direction: direction,
    // ).getConstraints(constraints, crossMaxSize, direction);

    BoxConstraints? tmpChildConstraints;
    if (mainMinSize != null ||
        mainMaxSize != null ||
        crossMinSize != null ||
        crossMaxSize != null) {
      tmpChildConstraints = switch (direction) {
        Axis.horizontal => BoxConstraints(
            minWidth: mainMinSize ?? childConstraints.minWidth,
            maxWidth: mainMaxSize ?? childConstraints.maxWidth,
            minHeight: crossMinSize ?? childConstraints.minHeight,
            maxHeight: crossMaxSize ?? childConstraints.maxHeight,
          ),
        Axis.vertical => BoxConstraints(
            minHeight: mainMinSize ?? childConstraints.minHeight,
            maxHeight: mainMaxSize ?? childConstraints.maxHeight,
            minWidth: crossMinSize ?? childConstraints.minWidth,
            maxWidth: crossMaxSize ?? childConstraints.maxWidth,
          ),
      };
    }

    final _AxisSize axisSize = _AxisSize.fromSize(
      size: layoutChild(
        child,
        tmpChildConstraints ?? childConstraints,
      ),
      direction: direction,
    );
    _axisSize = axisSize;
    return this;
  }
}

// A 2D vector that uses a [RenderWrap]'s main axis and cross axis as its first and second coordinate axes.
// It represents the same vector as (double mainAxisExtent, double crossAxisExtent).
extension type const _AxisSize._(Size _size) {
  _AxisSize({required double mainAxisExtent, required double crossAxisExtent})
      : this._(Size(mainAxisExtent, crossAxisExtent));
  _AxisSize.fromSize({required Size size, required Axis direction})
      : this._(_convert(size, direction));

  static const _AxisSize empty = _AxisSize._(Size.zero);

  static Size _convert(Size size, Axis direction) {
    return switch (direction) {
      Axis.horizontal => size,
      Axis.vertical => size.flipped,
    };
  }

  double get mainAxisExtent => _size.width;
  double get crossAxisExtent => _size.height;

  Size toSize(Axis direction) => _convert(_size, direction);

  bool get isEmpty => _size.isEmpty;

  _AxisSize applyConstraints(BoxConstraints constraints, Axis direction) {
    final BoxConstraints effectiveConstraints = switch (direction) {
      Axis.horizontal => constraints,
      Axis.vertical => constraints.flipped,
    };
    return _AxisSize._(effectiveConstraints.constrain(_size));
  }

  _AxisSize get flipped => _AxisSize._(_size.flipped);
  _AxisSize operator +(_AxisSize other) => _AxisSize._(Size(
      _size.width + other._size.width,
      math.max(_size.height, other._size.height)));
  _AxisSize operator -(_AxisSize other) => _AxisSize._(
      Size(_size.width - other._size.width, _size.height - other._size.height));
}

// extension type _CrossAxisConstraints(_CrossRange range) {
//   _CrossAxisConstraints.fromConstraints(
//       {required BoxConstraints constraints, required Axis direction})
//       : this(_convert(constraints, direction));
//
//   static _CrossRange _convert(BoxConstraints constraints, Axis direction) {
//     return switch (direction) {
//       Axis.horizontal => (constraints.minHeight, constraints.maxHeight),
//       Axis.vertical => (constraints.minWidth, constraints.maxWidth),
//     };
//   }
//
//   _CrossAxisConstraints applyMaxSize(double maxSize) {
//     return hasInfinite
//         ? _CrossAxisConstraints((maxSize, maxSize))
//         : _CrossAxisConstraints((0, double.infinity));
//   }
//
//   BoxConstraints getConstraints(
//     BoxConstraints constrains,
//     double maxCrossSize,
//     Axis direction,
//   ) {
//     final _CrossAxisConstraints crossConstraints = applyMaxSize(maxCrossSize);
//     return switch (direction) {
//       Axis.horizontal => BoxConstraints(
//           maxWidth: constrains.maxWidth,
//           minHeight: crossConstraints.minSize,
//           maxHeight: crossConstraints.maxSize),
//       Axis.vertical => BoxConstraints(
//           maxHeight: constrains.maxHeight,
//           minWidth: crossConstraints.minSize,
//           maxWidth: crossConstraints.maxSize),
//     };
//   }
//
//   double get minSize => range.$1;
//
//   double get maxSize => range.$2;
//
//   bool get hasInfinite => minSize >= double.infinity;
// }

class _RunMetrics {
  _RunMetrics(this.leadingChild, this.axisSize, this.dropChild);

  _AxisSize axisSize;
  int childCount = 1;
  RenderBox? dropChild; // 代表最后一个[dropChild]
  RenderBox leadingChild;

  static void _setChildNextDrop(bool needPaintDropChild, RenderBox child) {
    (child.parentData! as WrapMoreParentData).needPaintDropChild =
        needPaintDropChild;
  }

  static void _setNextSeparate(bool hasNextSeparate, RenderBox child) {
    (child.parentData! as WrapMoreParentData).hasNextSeparate = hasNextSeparate;
  }

  // Look ahead, creates a new run if incorporating the child would exceed the allowed line width.
  List<_RunMetrics>? tryAddingNewChild(
    RenderBox child,
    _AxisSize childSize,
    bool flipMainAxis,
    double spacing,
    double maxMainExtent,
    bool isExpanded,
    RenderBox previousChild,
    bool hasNextChild,
    int currentLine,
    int minLines,
    int? maxLines,
    _ChildLayout? dropLayout,
    _AxisSize? separateSize,
  ) {
    final double totalSpacing =
        separateSize == null ? spacing : separateSize.mainAxisExtent;
    final double childTotal =
        axisSize.mainAxisExtent + childSize.mainAxisExtent + totalSpacing;
    bool needsNewRun = childTotal - maxMainExtent > precisionErrorTolerance;
    final bool hasMinLines = maxLines == null || minLines < maxLines;
    RenderBox? resultDropChild;
    _AxisSize resultDropChildSize = _AxisSize.empty;
    bool breakDropLine = false;
    // 此时正好计算最小行上的数据，需要判断是否在这一行显示[dropChild]
    // 当这一行只能容纳[dropChild]的尺寸时，[dropChild]直接放到[currentLine]的下一行
    if (hasMinLines && dropLayout != null) {
      final drop = dropLayout.layout(force: true);
      resultDropChildSize = drop.axisSize;
      if (drop.hasSize) {
        if (isExpanded) {
          // 先考虑是否有下一个元素的逻辑
          if (!hasNextChild) {
            // 没有下一个元素时直接添加到最后
            if (needsNewRun) {
              // 直接换行肯定存在[dropChild]
              if (currentLine + 1 > minLines) {
                // 有更多
                resultDropChild = drop.child;
                breakDropLine = childSize.mainAxisExtent +
                        drop.spacing +
                        drop.axisSize.mainAxisExtent -
                        maxMainExtent >
                    precisionErrorTolerance;
              }
            } else {
              if (currentLine > minLines) {
                // [child]不会在新的一行
                breakDropLine = childTotal +
                        drop.spacing +
                        drop.axisSize.mainAxisExtent -
                        maxMainExtent >
                    precisionErrorTolerance;
                resultDropChild = drop.child;
              }
            }
          } else if (maxLines != null) {
            // 最大行不为null的情况需要进一步判断
            if (currentLine >= maxLines) {
              if (needsNewRun) {
                // 需要换行，[child]孩子就不应该展示
                child = resultDropChild = drop.child;
                childSize = drop.axisSize;
                breakDropLine = axisSize.mainAxisExtent +
                        drop.spacing +
                        drop.axisSize.mainAxisExtent -
                        maxMainExtent >
                    precisionErrorTolerance;
                if (!breakDropLine) {
                  // 如果[dropChild]不需要单独一行
                  needsNewRun = false;
                }
              } else {
                if (childTotal +
                        drop.spacing +
                        drop.axisSize.mainAxisExtent -
                        maxMainExtent >
                    precisionErrorTolerance) {
                  // 1. [child] + [dropChild]需要换新
                  // 看是否能容下[previousChild] + [dropChild]
                  if (axisSize.mainAxisExtent +
                          drop.spacing +
                          drop.axisSize.mainAxisExtent -
                          maxMainExtent >
                      precisionErrorTolerance) {
                    // 放不下[dropChild]需要进一步循环后面的[child]，直到后面的[child]需要换新行
                  } else {
                    // 能放下[dropChild]就替换[child]
                    breakDropLine = false;
                    child = resultDropChild = drop.child;
                  }
                } else {
                  // 2. [child] + [dropChild]不需要换新行，继续看下一个
                }
              }
            }
          }
        } else {
          // 未展开的情况，需要计算最小[minLines]
          if (currentLine >= minLines) {
            if (needsNewRun) {
              // [child]都换行了当然不展示了
              breakDropLine = axisSize.mainAxisExtent +
                      drop.spacing +
                      drop.axisSize.mainAxisExtent -
                      maxMainExtent >
                  precisionErrorTolerance;
              child = resultDropChild = drop.child;
              if (!breakDropLine) {
                needsNewRun = false;
              }
            } else {
              if (hasNextChild) {
                if (childTotal +
                        drop.spacing +
                        drop.axisSize.mainAxisExtent -
                        maxMainExtent >
                    precisionErrorTolerance) {
                  //  1. [child] + [dropChild]需要换新
                  if (axisSize.mainAxisExtent +
                          drop.spacing +
                          drop.axisSize.mainAxisExtent -
                          maxMainExtent >
                      precisionErrorTolerance) {
                    // 放不下[dropChild]需要进一步循环后面的[child]，直到后面的[child]需要换新行
                  } else {
                    // 能放下就替换[child]
                    breakDropLine = false;
                    child = resultDropChild = drop.child;
                  }
                } else {
                  //  2. [child] + [dropChild]不需要换新
                }
              } else {
                // 直接没有下一个元素时，直接不展示[dropChild]
              }
            }
          }
        }
      }
    }

    // print(
    //     "wcc##${currentLine} => resultDropChild => ${resultDropChild != null}, childCount => ${childCount}, needsNewRun => $needsNewRun, child == resultDropChild => ${child == resultDropChild}，breakDropLine => $breakDropLine");

    if (needsNewRun) {
      final _RunMetrics runMetrics = _RunMetrics(
          child,
          child == resultDropChild ? resultDropChildSize : childSize,
          breakDropLine ? null : resultDropChild);
      final List<_RunMetrics> runMetricsList = [runMetrics];
      if (child == resultDropChild) {
        runMetrics.dropChild = resultDropChild;
        _setChildNextDrop(true, previousChild);
      } else if (resultDropChild != null) {
        _setChildNextDrop(true, child);
        if (breakDropLine) {
          runMetricsList.add(_RunMetrics(
              resultDropChild, dropLayout!.axisSize, resultDropChild));
        } else {
          _addDropChild(runMetrics, dropLayout!.axisSize, dropLayout.spacing);
        }
      }
      return runMetricsList;
    } else {
      if (child == resultDropChild) {
        _setChildNextDrop(true, previousChild);
        dropChild = resultDropChild;
        _addDropChild(this, dropLayout!.axisSize, dropLayout.spacing);
        return null;
      } else {
        axisSize += childSize +
            _AxisSize(
              mainAxisExtent: totalSpacing,
              crossAxisExtent: separateSize?.crossAxisExtent ?? 0.0,
            );
        if (separateSize != null) {
          _setNextSeparate(true, previousChild);
        }
        childCount += 1;
        if (flipMainAxis) {
          leadingChild = child;
        }
        if (resultDropChild != null) {
          _setChildNextDrop(true, child);
          if (breakDropLine) {
            return [
              _RunMetrics(
                  resultDropChild, dropLayout!.axisSize, resultDropChild)
            ];
          }
          dropChild = resultDropChild;
          _addDropChild(this, dropLayout!.axisSize, dropLayout.spacing);
        }
        return null;
      }
    }
  }

  static void _addDropChild(
    _RunMetrics runMetrics,
    _AxisSize dropChildSize,
    double spacing,
  ) {
    if (runMetrics.dropChild != null) {
      runMetrics.axisSize += dropChildSize +
          _AxisSize(mainAxisExtent: spacing, crossAxisExtent: 0.0);
      runMetrics.childCount += 1;
    }
  }
}

class RenderWrapMore extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, WrapMoreParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, WrapMoreParentData> {
  /// Creates a wrap render object.
  ///
  /// By default, the wrap layout is horizontal and both the children and the
  /// runs are aligned to the start.
  RenderWrapMore({
    RenderBox? dropRenderBox,
    RenderBox? nearRenderBox,
    RenderBox? separateRenderBox,
    List<RenderBox>? children,
    Axis direction = Axis.horizontal,
    AxisDirection nearDirection = AxisDirection.right,
    WrapMoreAlignment alignment = WrapMoreAlignment.start,
    double spacing = 0.0,
    WrapMoreAlignment runAlignment = WrapMoreAlignment.start,
    double runSpacing = 0.0,
    WrapMoreCrossAlignment crossAxisAlignment = WrapMoreCrossAlignment.start,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    Clip clipBehavior = Clip.none,
    int minLines = 0,
    int? maxLines,
    double? dropChildSpacing,
    bool isExpanded = false,
    double nearSpacing = 0.0,
    WrapMoreNearAlignment nearAlignment = WrapMoreNearAlignment.start,
    bool alwaysShowNearChild = false,
  })  : _direction = direction,
        _alignment = alignment,
        _spacing = spacing,
        _runAlignment = runAlignment,
        _runSpacing = runSpacing,
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection,
        _nearDirection = nearDirection,
        _clipBehavior = clipBehavior,
        _minLines = minLines,
        _maxLines = maxLines,
        _dropChildSpacing = dropChildSpacing,
        _isExpanded = isExpanded,
        _nearSpacing = nearSpacing,
        _nearAlignment = nearAlignment,
        _alwaysShowNearChild = alwaysShowNearChild {
    this.dropRenderBox = dropRenderBox;
    this.nearRenderBox = nearRenderBox;
    this.separateRenderBox = separateRenderBox;
    addAll(children);
  }

  /// nearChild
  RenderBox? _nearRenderBox;
  RenderBox? get nearRenderBox => _nearRenderBox;
  set nearRenderBox(RenderBox? value) {
    if (_nearRenderBox != null) {
      dropChild(_nearRenderBox!);
    }
    _nearRenderBox = value;
    if (_nearRenderBox != null) {
      adoptChild(_nearRenderBox!);
    }
  }

  AxisDirection _nearDirection;
  set nearDirection(AxisDirection value) {
    if (_nearDirection == value) {
      return;
    }
    _nearDirection = value;
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  double _nearSpacing;
  double get nearSpacing => _nearSpacing;
  set nearSpacing(double value) {
    if (_nearSpacing == value) {
      return;
    }
    _nearSpacing = value;
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  WrapMoreNearAlignment _nearAlignment;
  WrapMoreNearAlignment get nearAlignment => _nearAlignment;
  set nearAlignment(WrapMoreNearAlignment value) {
    if (_nearAlignment == value) {
      return;
    }
    _nearAlignment = value;
    markNeedsLayout();
  }

  bool _alwaysShowNearChild;
  bool get alwaysShowNearChild => _alwaysShowNearChild;
  set alwaysShowNearChild(bool value) {
    if (_alwaysShowNearChild == value) {
      return;
    }
    _alwaysShowNearChild = value;
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  /// dropChild
  RenderBox? _dropRenderBox;
  RenderBox? get dropRenderBox => _dropRenderBox;
  set dropRenderBox(RenderBox? value) {
    if (_dropRenderBox != null) {
      dropChild(_dropRenderBox!);
    }
    _dropRenderBox = value;
    if (_dropRenderBox != null) {
      adoptChild(_dropRenderBox!);
    }
  }

  double? get dropChildSpacing => _dropChildSpacing;
  double? _dropChildSpacing;
  set dropChildSpacing(double? value) {
    if (_dropChildSpacing == value) {
      return;
    }
    _dropChildSpacing = value;
    markNeedsLayout();
  }

  /// separateChild
  RenderBox? _separateRenderBox;
  RenderBox? get separateRenderBox => _separateRenderBox;
  set separateRenderBox(RenderBox? value) {
    if (_separateRenderBox != null) {
      dropChild(_separateRenderBox!);
    }
    _separateRenderBox = value;
    if (_separateRenderBox != null) {
      adoptChild(_separateRenderBox!);
    }
  }

  bool get isExpanded => _isExpanded;
  bool _isExpanded;
  set isExpanded(bool value) {
    if (_isExpanded == value) {
      return;
    }
    _isExpanded = value;
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  int get minLines => _minLines;
  int _minLines;
  set minLines(int value) {
    if (_minLines == value) {
      return;
    }
    _minLines = value;
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  int? get maxLines => _maxLines;
  int? _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) {
      return;
    }
    _maxLines = value;
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  /// The direction to use as the main axis.
  ///
  /// For example, if [direction] is [Axis.horizontal], the default, the
  /// children are placed adjacent to one another in a horizontal run until the
  /// available horizontal space is consumed, at which point a subsequent
  /// children are placed in a new run vertically adjacent to the previous run.
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    if (_direction == value) {
      return;
    }
    _direction = value;
    markNeedsLayout();
  }

  /// How the children within a run should be placed in the main axis.
  ///
  /// For example, if [alignment] is [WrapMoreAlignment.center], the children in
  /// each run are grouped together in the center of their run in the main axis.
  ///
  /// Defaults to [WrapMoreAlignment.start].
  ///
  /// See also:
  ///
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  WrapMoreAlignment get alignment => _alignment;
  WrapMoreAlignment _alignment;
  set alignment(WrapMoreAlignment value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    markNeedsLayout();
  }

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
  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (_spacing == value) {
      return;
    }
    _spacing = value;
    markNeedsLayout();
  }

  /// How the runs themselves should be placed in the cross axis.
  ///
  /// For example, if [runAlignment] is [WrapMoreAlignment.center], the runs are
  /// grouped together in the center of the overall [RenderWrapMore] in the cross
  /// axis.
  ///
  /// Defaults to [WrapMoreAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  WrapMoreAlignment get runAlignment => _runAlignment;
  WrapMoreAlignment _runAlignment;
  set runAlignment(WrapMoreAlignment value) {
    if (_runAlignment == value) {
      return;
    }
    _runAlignment = value;
    markNeedsLayout();
  }

  /// How much space to place between the runs themselves in the cross axis.
  ///
  /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
  /// 10.0 logical pixels apart in the cross axis.
  ///
  /// If there is additional free space in the overall [RenderWrapMore] (e.g.,
  /// because the wrap has a minimum size that is not filled), the additional
  /// free space will be allocated according to the [runAlignment].
  ///
  /// Defaults to 0.0.
  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) {
      return;
    }
    _runSpacing = value;
    markNeedsLayout();
  }

  /// How the children within a run should be aligned relative to each other in
  /// the cross axis.
  ///
  /// For example, if this is set to [WrapMoreCrossAlignment.end], and the
  /// [direction] is [Axis.horizontal], then the children within each
  /// run will have their bottom edges aligned to the bottom edge of the run.
  ///
  /// Defaults to [WrapMoreCrossAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  WrapMoreCrossAlignment get crossAxisAlignment => _crossAxisAlignment;
  WrapMoreCrossAlignment _crossAxisAlignment;
  set crossAxisAlignment(WrapMoreCrossAlignment value) {
    if (_crossAxisAlignment == value) {
      return;
    }
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [alignment] property's [WrapMoreAlignment.start] and
  /// [WrapMoreAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [alignment] is either [WrapMoreAlignment.start] or [WrapMoreAlignment.end], or
  /// there's more than one child, then the [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the order in
  /// which runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapMoreAlignment.start] and [WrapMoreAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapMoreCrossAlignment.start] and
  /// [WrapMoreCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the
  /// [runAlignment] is either [WrapMoreAlignment.start] or [WrapMoreAlignment.end], the
  /// [crossAxisAlignment] is either [WrapMoreCrossAlignment.start] or
  /// [WrapMoreCrossAlignment.end], or there's more than one child, then the
  /// [textDirection] must not be null.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [alignment] property's
  /// [WrapMoreAlignment.start] and [WrapMoreAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [alignment]
  /// is either [WrapMoreAlignment.start] or [WrapMoreAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapMoreAlignment.start] and [WrapMoreAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapMoreCrossAlignment.start] and
  /// [WrapMoreCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [runAlignment] is either [WrapMoreAlignment.start] or [WrapMoreAlignment.end], the
  /// [crossAxisAlignment] is either [WrapMoreCrossAlignment.start] or
  /// [WrapMoreCrossAlignment.end], or there's more than one child, then the
  /// [verticalDirection] must not be null.
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  AxisDirection get _nearRealDirection => switch (_nearDirection) {
        AxisDirection.left => textDirection == TextDirection.rtl
            ? AxisDirection.right
            : AxisDirection.left,
        AxisDirection.right => textDirection == TextDirection.rtl
            ? AxisDirection.left
            : AxisDirection.right,
        AxisDirection.up => verticalDirection == VerticalDirection.up
            ? AxisDirection.down
            : AxisDirection.up,
        AxisDirection.down => verticalDirection == VerticalDirection.up
            ? AxisDirection.up
            : AxisDirection.down,
      };

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _dropRenderBox?.attach(owner);
    _nearRenderBox?.attach(owner);
    _separateRenderBox?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    _dropRenderBox?.detach();
    _nearRenderBox?.detach();
    _separateRenderBox?.detach();
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    if (_dropRenderBox != null) {
      redepthChild(_dropRenderBox!);
    }

    if (_nearRenderBox != null) {
      redepthChild(_nearRenderBox!);
    }

    if (_separateRenderBox != null) {
      redepthChild(_separateRenderBox!);
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    RenderBox? child = firstChild;
    bool needPaintDropChild = false;
    bool needPaintSeparateChild = false;
    while (child != null) {
      visitor(child);
      final WrapMoreParentData childParentData =
          child.parentData! as WrapMoreParentData;

      if (childParentData.isEndLineLast) {
        break;
      }

      if (childParentData.needPaintDropChild) {
        needPaintDropChild = true;
        break;
      }
      if (childParentData.hasNextSeparate) {
        needPaintSeparateChild = true;
      }
      child = childParentData.nextSibling;
    }

    if (needPaintDropChild && dropRenderBox != null) {
      visitor(dropRenderBox!);
    }

    if (needPaintSeparateChild && separateRenderBox != null) {
      visitor(separateRenderBox!);
    }

    if (nearRenderBox case final child?) {
      final WrapMoreParentData childParentData =
          child.parentData! as WrapMoreParentData;
      if (childParentData.showNearChild) {
        visitor(child);
      }
    }
  }

  bool get _debugHasNecessaryDirections {
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null,
              'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
        case Axis.vertical:
          break;
      }
    }
    if (alignment == WrapMoreAlignment.start ||
        alignment == WrapMoreAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null,
              'Horizontal $runtimeType with alignment $alignment has a null textDirection, so the alignment cannot be resolved.');
        case Axis.vertical:
          break;
      }
    }
    if (runAlignment == WrapMoreAlignment.start ||
        runAlignment == WrapMoreAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          break;
        case Axis.vertical:
          assert(textDirection != null,
              'Vertical $runtimeType with runAlignment $runAlignment has a null textDirection, so the alignment cannot be resolved.');
      }
    }
    if (crossAxisAlignment == WrapMoreCrossAlignment.start ||
        crossAxisAlignment == WrapMoreCrossAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          break;
        case Axis.vertical:
          assert(textDirection != null,
              'Vertical $runtimeType with crossAxisAlignment $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
      }
    }
    return true;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WrapMoreParentData) {
      child.parentData = WrapMoreParentData();
    }
  }

  // 是否存在[dropChild]
  bool get _hasDropChild {
    if (_dropRenderBox == null) return false;
    // 最大行，最大行必须大于最小行才有按钮
    final int? maxLines = this.maxLines;
    if (maxLines != null && maxLines <= minLines) {
      return false;
    }
    return true;
  }

  // // 是否展示[dropChild]
  // bool get _isShowDropChild {
  //   if (_isInvalidLine) {
  //     return false;
  //   }
  //   final bool flipMainAxis = direction == Axis.vertical;
  //   final double maxMainExtent = switch (direction) {
  //     Axis.horizontal => constraints.maxWidth,
  //     Axis.vertical => constraints.maxHeight,
  //   };
  //
  //   // 当前行
  //   int lastLine = 1;
  //   // 孩子
  //   RenderBox? child = firstChild;
  //   // 宽度
  //   double totalMainAxisExtent =
  //       (flipMainAxis ? child?.size.height : child?.size.width) ?? 0.0;
  //   while (child != null && lastLine <= minLines) {
  //     final RenderBox? nextChild = childAfter(child);
  //     if (nextChild != null) {
  //       final double nextChildMainAxisExtent =
  //           flipMainAxis ? nextChild.size.height : nextChild.size.width;
  //       final bool needsNewRun = totalMainAxisExtent +
  //               (flipMainAxis ? nextChild.size.height : nextChild.size.width) +
  //               spacing -
  //               maxMainExtent >
  //           precisionErrorTolerance;
  //       if (needsNewRun) {
  //         lastLine++;
  //         totalMainAxisExtent = nextChildMainAxisExtent;
  //       }
  //     }
  //     child = nextChild;
  //   }
  //   return lastLine > minLines;
  // }

  @override
  double computeMinIntrinsicWidth(double height) {
    switch (direction) {
      case Axis.horizontal:
        double width = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          width = math.max(width, child.getMinIntrinsicWidth(double.infinity));
          child = childAfter(child);
        }
        // 没处理隐藏逻辑，隐藏逻辑需要在[layout]之后才知道[固有大小的计算不需要处理]
        if (dropRenderBox != null) {
          width = math.max(width,
              dropRenderBox?.getMinIntrinsicWidth(double.infinity) ?? 0.0);
        }
        if (nearRenderBox != null) {
          width = math.max(width,
              nearRenderBox?.getMinIntrinsicWidth(double.infinity) ?? 0.0);
        }
        if (separateRenderBox != null) {
          width = math.max(width,
              separateRenderBox?.getMinIntrinsicWidth(double.infinity) ?? 0.0);
        }
        return width;
      case Axis.vertical:
        return getDryLayout(BoxConstraints(maxHeight: height)).width;
    }
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    switch (direction) {
      case Axis.horizontal:
        double width = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          width += child.getMaxIntrinsicWidth(double.infinity);
          child = childAfter(child);
        }
        // 没处理隐藏逻辑，隐藏逻辑需要在[layout]之后才知道[固有大小的计算不需要处理]
        if (dropRenderBox != null) {
          width +=
              (dropRenderBox?.getMaxIntrinsicWidth(double.infinity) ?? 0.0);
        }
        if (nearRenderBox != null) {
          width +=
              (nearRenderBox?.getMaxIntrinsicWidth(double.infinity) ?? 0.0);
        }
        if (separateRenderBox != null) {
          width +=
              separateRenderBox?.getMaxIntrinsicWidth(double.infinity) ?? 0.0;
        }
        return width;
      case Axis.vertical:
        return getDryLayout(BoxConstraints(maxHeight: height)).width;
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return getDryLayout(BoxConstraints(maxWidth: width)).height;
      case Axis.vertical:
        double height = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          height =
              math.max(height, child.getMinIntrinsicHeight(double.infinity));
          child = childAfter(child);
        }
        // 没处理隐藏逻辑，隐藏逻辑需要在[layout]之后才知道[固有大小的计算不需要处理]
        if (dropRenderBox != null) {
          height = math.max(height,
              dropRenderBox?.getMinIntrinsicHeight(double.infinity) ?? 0.0);
        }
        if (nearRenderBox != null) {
          height = math.max(height,
              nearRenderBox?.getMinIntrinsicHeight(double.infinity) ?? 0.0);
        }
        if (separateRenderBox != null) {
          height += math.max(height,
              separateRenderBox?.getMinIntrinsicHeight(double.infinity) ?? 0.0);
        }
        return height;
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    switch (direction) {
      case Axis.horizontal:
        return getDryLayout(BoxConstraints(maxWidth: width)).height;
      case Axis.vertical:
        double height = 0.0;
        RenderBox? child = firstChild;
        while (child != null) {
          height += child.getMaxIntrinsicHeight(double.infinity);
          child = childAfter(child);
        }
        // 没处理隐藏逻辑，隐藏逻辑需要在[layout]之后才知道[固有大小的计算不需要处理]
        if (dropRenderBox != null) {
          height +=
              (dropRenderBox?.getMaxIntrinsicHeight(double.infinity) ?? 0.0);
        }
        if (nearRenderBox != null) {
          height +=
              (nearRenderBox?.getMaxIntrinsicHeight(double.infinity) ?? 0.0);
        }
        if (separateRenderBox != null) {
          height +=
              (separateRenderBox?.getMaxIntrinsicHeight(double.infinity) ??
                  0.0);
        }
        return height;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  // double _getMainAxisExtent(Size childSize) {
  //   return switch (direction) {
  //     Axis.horizontal => childSize.width,
  //     Axis.vertical => childSize.height,
  //   };
  // }
  //
  // double _getCrossAxisExtent(Size childSize) {
  //   return switch (direction) {
  //     Axis.horizontal => childSize.height,
  //     Axis.vertical => childSize.width,
  //   };
  // }

  Offset _getOffset(double mainAxisOffset, double crossAxisOffset) {
    return switch (direction) {
      Axis.horizontal => Offset(mainAxisOffset, crossAxisOffset),
      Axis.vertical => Offset(crossAxisOffset, mainAxisOffset),
    };
  }

  (bool flipHorizontal, bool flipVertical) get _areAxesFlipped {
    final bool flipHorizontal = switch (textDirection ?? TextDirection.ltr) {
      TextDirection.ltr => false,
      TextDirection.rtl => true,
    };
    final bool flipVertical = switch (verticalDirection) {
      VerticalDirection.down => false,
      VerticalDirection.up => true,
    };
    return switch (direction) {
      Axis.horizontal => (flipHorizontal, flipVertical),
      Axis.vertical => (flipVertical, flipHorizontal),
    };
  }

  @override
  double? computeDryBaseline(
      covariant BoxConstraints constraints, TextBaseline baseline) {
    if (firstChild == null) {
      return null;
    }
    final BoxConstraints childConstraints = switch (direction) {
      Axis.horizontal => BoxConstraints(maxWidth: constraints.maxWidth),
      Axis.vertical => BoxConstraints(maxHeight: constraints.maxHeight),
    };

    final (
      _AxisSize childrenAxisSize,
      _AxisSize onlyChildrenAxisSize,
      List<_RunMetrics> runMetrics,
      _AxisSize? nearSize,
      _AxisSize? separateSize
    ) = _computeRuns(constraints, ChildLayoutHelper.dryLayoutChild);
    final _AxisSize containerAxisSize =
        childrenAxisSize.applyConstraints(constraints, direction);

    BaselineOffset baselineOffset = BaselineOffset.noBaseline;
    void findHighestBaseline(Offset offset, RenderBox child) {
      baselineOffset = baselineOffset.minOf(
          BaselineOffset(child.getDryBaseline(childConstraints, baseline)) +
              offset.dy);
    }

    Size getChildSize(RenderBox child) => child.getDryLayout(childConstraints);
    _positionChildren(runMetrics, childrenAxisSize, containerAxisSize, nearSize,
        separateSize, findHighestBaseline, getChildSize);
    return baselineOffset.offset;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _computeDryLayout(constraints);
  }

  Size _computeDryLayout(BoxConstraints constraints,
      [ChildLayouter layoutChild = ChildLayoutHelper.dryLayoutChild]) {
    final BoxConstraints constraints = this.constraints;
    assert(_debugHasNecessaryDirections);
    if (firstChild == null) {
      return constraints.smallest;
    }

    final (
      _AxisSize childrenAxisSize,
      _AxisSize onlyChildrenAxisSize,
      List<_RunMetrics> runMetrics,
      _AxisSize? nearSize,
      _AxisSize? separateSize
    ) = _computeRuns(constraints, layoutChild);
    final _AxisSize containerAxisSize =
        childrenAxisSize.applyConstraints(constraints, direction);
    return containerAxisSize.toSize(direction);
    // final (BoxConstraints childConstraints, double mainAxisLimit) =
    //     switch (direction) {
    //   Axis.horizontal => (
    //       BoxConstraints(maxWidth: constraints.maxWidth),
    //       constraints.maxWidth
    //     ),
    //   Axis.vertical => (
    //       BoxConstraints(maxHeight: constraints.maxHeight),
    //       constraints.maxHeight
    //     ),
    // };
    //
    // double mainAxisExtent = 0.0;
    // double crossAxisExtent = 0.0;
    // double runMainAxisExtent = 0.0;
    // double runCrossAxisExtent = 0.0;
    // int childCount = 0;
    // RenderBox? child = firstChild;
    // while (child != null) {
    //   final Size childSize = layoutChild(child, childConstraints);
    //   final double childMainAxisExtent = _getMainAxisExtent(childSize);
    //   final double childCrossAxisExtent = _getCrossAxisExtent(childSize);
    //   // There must be at least one child before we move on to the next run.
    //   if (childCount > 0 &&
    //       runMainAxisExtent + childMainAxisExtent + spacing > mainAxisLimit) {
    //     mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
    //     crossAxisExtent += runCrossAxisExtent + runSpacing;
    //     runMainAxisExtent = 0.0;
    //     runCrossAxisExtent = 0.0;
    //     childCount = 0;
    //   }
    //   runMainAxisExtent += childMainAxisExtent;
    //   runCrossAxisExtent = math.max(runCrossAxisExtent, childCrossAxisExtent);
    //   if (childCount > 0) {
    //     runMainAxisExtent += spacing;
    //   }
    //   childCount += 1;
    //   child = childAfter(child);
    // }
    // crossAxisExtent += runCrossAxisExtent;
    // mainAxisExtent = math.max(mainAxisExtent, runMainAxisExtent);
    //
    // return constraints.constrain(switch (direction) {
    //   Axis.horizontal => Size(mainAxisExtent, crossAxisExtent),
    //   Axis.vertical => Size(crossAxisExtent, mainAxisExtent),
    // });
  }

  static void _resetParentData(RenderBox child) {
    final WrapMoreParentData parentData =
        child.parentData! as WrapMoreParentData;
    parentData.needPaintDropChild = false;
    parentData.isEndLineLast = false;
    parentData.showNearChild = false;
    parentData.hasNextSeparate = false;
    parentData.nextSeparateOffset = Offset.zero;
  }

  static void _setEndLineLast(RenderBox child) {
    (child.parentData! as WrapMoreParentData).isEndLineLast = true;
  }

  static void _setShowNearChild(RenderBox child) {
    (child.parentData! as WrapMoreParentData).showNearChild = true;
  }

  static Size _getChildSize(RenderBox child) => child.size;
  static void _setChildPosition(Offset offset, RenderBox child) {
    (child.parentData! as WrapMoreParentData).offset = offset;
  }

  bool _hasVisualOverflow = false;

  // 代表所有行都显示
  int? get _endLine {
    if (isExpanded) {
      if (maxLines == null) return null;
      return math.max(minLines, maxLines!);
    } else {
      return minLines;
    }
  }

  // 是否行有效
  bool get _isValidLine => maxLines == null || minLines < maxLines!;

  // 是否方向相同
  bool get _sameNearDirection =>
      axisDirectionToAxis(_nearDirection) == direction;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    assert(_debugHasNecessaryDirections);
    if (firstChild == null) {
      size = constraints.smallest;
      _hasVisualOverflow = false;
      return;
    }

    final (
      _AxisSize childrenAxisSize,
      _AxisSize onlyChildrenAxisSize,
      List<_RunMetrics> runMetrics,
      _AxisSize? nearSize,
      _AxisSize? separateSize
    ) = _computeRuns(constraints, ChildLayoutHelper.layoutChild);
    _AxisSize containerAxisSize =
        childrenAxisSize.applyConstraints(constraints, direction);
    size = containerAxisSize.toSize(direction);
    final bool sameNearDirection = _sameNearDirection;
    final _AxisSize freeAxisSize = containerAxisSize -
        onlyChildrenAxisSize -
        (nearSize != null
            ? _AxisSize(
                mainAxisExtent: sameNearDirection
                    ? (nearSize.mainAxisExtent + nearSpacing)
                    : 0.0,
                crossAxisExtent: sameNearDirection
                    ? 0.0
                    : (nearSize.crossAxisExtent + nearSpacing),
              )
            : _AxisSize.empty);
    _hasVisualOverflow =
        freeAxisSize.mainAxisExtent < 0.0 || freeAxisSize.crossAxisExtent < 0.0;
    _positionChildren(runMetrics, freeAxisSize, containerAxisSize, nearSize,
        separateSize, _setChildPosition, _getChildSize);
  }

  dynamic _layoutRuns(
    double mainAxisLimit,
    _ChildLayout? dropLayout,
    _AxisSize? separateSize,
    _GetChildSize layoutChild,
    bool lookupMore,
  ) {
    if (lookupMore && !_isValidLine) {
      return false;
    }

    final (bool flipMainAxis, _) = _areAxesFlipped;
    final double spacing = this.spacing;
    final int? endLine = lookupMore ? minLines : _endLine;
    _AxisSize childrenAxisSize = _AxisSize.empty;

    List<_RunMetrics> runMetrics = [];
    _RunMetrics? currentRun;
    RenderBox? previousChild;
    RenderBox? nextChild;
    for (RenderBox? child = firstChild; child != null; child = nextChild) {
      _resetParentData(child);
      final _AxisSize childSize =
          _AxisSize.fromSize(size: layoutChild(child), direction: direction);
      nextChild = childAfter(child);
      final _RunMetrics? newRun;
      if (currentRun == null) {
        // 代表第一次的第一个孩子，直接设置null，第一个不可能为[dropChild]
        newRun = _RunMetrics(child, childSize, null);
      } else {
        final List<_RunMetrics>? runs = currentRun.tryAddingNewChild(
          child,
          childSize,
          flipMainAxis,
          spacing,
          mainAxisLimit,
          lookupMore ? false : isExpanded,
          previousChild!,
          nextChild != null,
          runMetrics.length,
          minLines,
          maxLines,
          dropLayout,
          separateSize,
        );
        final int length = runs?.length ?? 0;
        if (runs != null && length > 1) {
          for (int i = 0; i < length - 1; i++) {
            final run = runs[i];
            // 这些逻辑是不需要了，因为[dropChild]为null，就不会存在多个
            // final int oldLine = runMetrics.length;
            // if (fixedLine != null && oldLine == fixedLine) {
            //   break;
            // }
            runMetrics.add(run);
            childrenAxisSize += run.axisSize.flipped ?? _AxisSize.empty;
          }
        }
        newRun = length <= 0 ? null : runs!.last;
      }

      final RenderBox? runDropChild =
          newRun?.dropChild ?? currentRun?.dropChild;
      if (newRun != null) {
        childrenAxisSize += currentRun?.axisSize.flipped ?? _AxisSize.empty;
        final int oldLine = runMetrics.length;
        // 存在结束行则循环到结束行末尾就跳出
        if (previousChild != null &&
            runDropChild == null &&
            endLine != null &&
            oldLine >= endLine) {
          assert(currentRun != null);
          final _RunMetrics previousRun = currentRun!;
          if (dropLayout != null) {
            if (previousRun.dropChild == null) {
              if (dropLayout.layout().hasSize) {
                // 存在[dropChild]的情况下需要将[dropChild]放到下一行
                if (lookupMore) {
                  return true;
                } else {
                  _RunMetrics._setChildNextDrop(true, previousChild);
                  currentRun = _RunMetrics(
                      dropLayout.child, dropLayout.axisSize, dropLayout.child);
                  runMetrics.add(currentRun);
                }
                break;
              }
            }
          }
          _setEndLineLast(previousChild);
          currentRun = null;
          if (lookupMore) {
            return true;
          } else {
            break;
          }
        }

        runMetrics.add(newRun);
        currentRun = newRun;
        if (runDropChild != null) {
          // 说明新行有一个[dropChild]，直接退出
          if (lookupMore) {
            return true;
          } else {
            break;
          }
        }
      } else if (runDropChild != null) {
        // 已经存在[dropChild]，直接退出
        if (lookupMore) {
          return true;
        } else {
          break;
        }
      }

      previousChild = child;
    }
    return lookupMore
        ? false
        : (
            childrenAxisSize,
            currentRun,
            runMetrics,
          );
  }

  (
    _AxisSize childrenSize,
    _AxisSize onlyChildrenAxisSize,
    List<_RunMetrics> runMetrics,
    _AxisSize? nearSize,
    _AxisSize? separateSize
  ) _computeRuns(BoxConstraints constraints, ChildLayouter layoutChild) {
    assert(firstChild != null);
    final (
      BoxConstraints childConstraints,
      double mainAxisLimit,
      double crossAxisLimit
    ) = switch (direction) {
      Axis.horizontal => (
          BoxConstraints(maxWidth: constraints.maxWidth),
          constraints.maxWidth,
          constraints.maxHeight,
        ),
      Axis.vertical => (
          BoxConstraints(maxHeight: constraints.maxHeight),
          constraints.maxHeight,
          constraints.maxWidth,
        ),
    };

    // [nearChild]的布局处理
    _ChildLayout? nearLayout;
    final bool sameNearDirection = _sameNearDirection;
    _AxisSize? nearSize;
    double tmpMainAxisLimit = mainAxisLimit;
    final Map<RenderBox, Size> layoutChildren = {};
    Size tryLayoutChild(RenderBox child, [BoxConstraints? myChildConstraints]) {
      final Size size = layoutChildren.putIfAbsent(child,
          () => layoutChild(child, myChildConstraints ?? childConstraints));
      if (nearSize == null || !sameNearDirection) return size;
      final (
        double maxMainSize,
        BoxConstraints newChildConstraints,
      ) = switch (direction) {
        Axis.horizontal => (
            size.width,
            BoxConstraints(maxWidth: tmpMainAxisLimit)
          ),
        Axis.vertical => (
            size.width,
            BoxConstraints(maxHeight: tmpMainAxisLimit)
          ),
      };
      if (maxMainSize <= tmpMainAxisLimit) return size;
      final Size newSize = layoutChild(child, newChildConstraints);
      layoutChildren[child] = newSize;
      return newSize;
    }

    final bool hasDropChild = _hasDropChild;
    // [dropChild]的布局处理
    _ChildLayout? dropLayout;
    if (hasDropChild) {
      assert(dropRenderBox != null);
      dropLayout = _ChildLayout(
        dropRenderBox!,
        tryLayoutChild,
        childConstraints,
        direction,
        spacing: dropChildSpacing ?? spacing,
      );
    }

    // [separateChild]的布局处理
    _AxisSize? separateSize;
    if (separateRenderBox != null) {
      separateSize = _ChildLayout(
        separateRenderBox!,
        tryLayoutChild,
        childConstraints,
        direction,
        spacing: 0.0,
      ).layout(force: true).axisSize;
    }

    if (nearRenderBox != null) {
      _resetParentData(nearRenderBox!);
      final bool isStretch =
          !sameNearDirection && nearAlignment == WrapMoreNearAlignment.stretch;
      nearLayout = _ChildLayout(
        nearRenderBox!,
        layoutChild,
        childConstraints,
        direction,
      ).layout(
        mainMinSize: isStretch ? mainAxisLimit : null,
        mainMaxSize: isStretch ? mainAxisLimit : null,
      );
    }

    if (nearLayout != null && nearLayout.hasSize) {
      // // 此时需要计算nearLayout
      final isShowNearChild = alwaysShowNearChild
          ? true
          : _layoutRuns(
              tmpMainAxisLimit,
              dropLayout,
              separateSize,
              tryLayoutChild,
              true,
            );
      assert(isShowNearChild != null);
      // 是否展开有效，如果有效，就需要绘制[nearChild]
      if (isShowNearChild) {
        assert(nearRenderBox != null);
        _setShowNearChild(nearRenderBox!);
        nearSize = nearLayout.axisSize;
        if (sameNearDirection) {
          tmpMainAxisLimit = math.max(0.0,
              mainAxisLimit - (nearSize?.mainAxisExtent ?? 0.0) - nearSpacing);
        }
      }
    }

    _AxisSize tmpChildrenAxisSize = _AxisSize.empty;
    final (
      _AxisSize childrenAxisSize,
      _RunMetrics? currentRun,
      List<_RunMetrics> runMetrics,
    ) = _layoutRuns(
      tmpMainAxisLimit,
      dropLayout,
      separateSize,
      tryLayoutChild,
      false,
    );
    tmpChildrenAxisSize += childrenAxisSize;
    assert(runMetrics.isNotEmpty);
    final double totalRunSpacing = runSpacing * (runMetrics.length - 1);
    tmpChildrenAxisSize += _AxisSize(
            mainAxisExtent: totalRunSpacing, crossAxisExtent: 0.0) +
        (currentRun == null ? _AxisSize.empty : currentRun.axisSize.flipped);
    final _AxisSize onlyChildrenAxisSize = tmpChildrenAxisSize.flipped;
    if (nearSize != null) {
      final bool isStretch = nearAlignment == WrapMoreNearAlignment.stretch;
      if (sameNearDirection) {
        if (isStretch ||
            nearSize.mainAxisExtent > tmpChildrenAxisSize.crossAxisExtent) {
          // 此时[tmpChildrenAxisSize]的主轴和侧轴是反向的
          final double nearMaxMainLimit =
              mainAxisLimit - tmpChildrenAxisSize.crossAxisExtent;
          final double nearMaxCrossLimit = tmpChildrenAxisSize.mainAxisExtent;
          // nearChild主轴方向显示溢出，需要重新布局[nearChild]
          nearSize = nearLayout!
              .layout(
                mainMaxSize: nearMaxMainLimit,
                crossMinSize: isStretch ? nearMaxCrossLimit : null,
                crossMaxSize: isStretch ? nearMaxCrossLimit : null,
                force: true,
              )
              .axisSize;
        }
      } else if (nearSpacing > 0.0) {
        tmpChildrenAxisSize +=
            _AxisSize(mainAxisExtent: nearSpacing, crossAxisExtent: 0.0);
      }

      // 存在[nearChild]时，需要进一步计算[tmpChildrenAxisSize]
      final _AxisSize nearTotalSize =
          _AxisSize(mainAxisExtent: nearSpacing, crossAxisExtent: 0.0) +
              nearSize;
      if (sameNearDirection) {
        tmpChildrenAxisSize = tmpChildrenAxisSize.flipped + nearTotalSize;
      } else {
        tmpChildrenAxisSize =
            (tmpChildrenAxisSize + nearTotalSize.flipped).flipped;
      }
    } else {
      tmpChildrenAxisSize = tmpChildrenAxisSize.flipped;
    }
    return (
      tmpChildrenAxisSize,
      onlyChildrenAxisSize,
      runMetrics,
      nearSize,
      separateSize
    );
  }

  // 布局[nearChild]，返回[children的偏移和尺寸]
  (
    double needChildrenMainOffset,
    double needChildrenCrossOffset,
    double needMainSize,
    double needCrossSize
  ) _positionNearChild(
    _AxisSize containerAxisSize,
    _AxisSize? nearAxisSize,
    bool flipMainAxis,
    bool flipCrossAxis,
    _PositionChild positionChild,
  ) {
    if (nearAxisSize == null) return (0.0, 0.0, 0.0, 0.0);
    assert(nearRenderBox != null);
    final AxisDirection nearDirection = _nearRealDirection;
    final WrapMoreNearAlignment nearAlignment = this.nearAlignment;

    double needChildrenMainOffset = 0.0;
    double needChildrenCrossOffset = 0.0;
    double needMainSize = 0.0;
    double needCrossSize = 0.0;
    Offset offset = Offset.zero;
    final Axis nearAxis = axisDirectionToAxis(nearDirection);

    if (nearAxis == direction) {
      final bool isStartPosition = nearDirection == AxisDirection.left ||
          nearDirection == AxisDirection.up;
      final double alignment = flipCrossAxis
          ? nearAlignment.flipped.alignment
          : nearAlignment.alignment;
      final double mainOffset = isStartPosition
          ? 0.0
          : math.max(0.0,
              containerAxisSize.mainAxisExtent - nearAxisSize.mainAxisExtent);
      final double crossOffset =
          (containerAxisSize.crossAxisExtent - nearAxisSize.crossAxisExtent) *
              alignment;
      offset = nearAxis == Axis.horizontal
          ? Offset(mainOffset, crossOffset)
          : Offset(crossOffset, mainOffset);

      needMainSize = nearAxisSize.mainAxisExtent + nearSpacing;
      needChildrenMainOffset = (isStartPosition ? needMainSize : 0.0);
      needCrossSize = 0.0;
      needChildrenCrossOffset = 0.0;
    } else {
      final bool isStarCrossPosition = nearDirection == AxisDirection.right ||
          nearDirection == AxisDirection.down;
      final double alignment = flipMainAxis
          ? nearAlignment.flipped.alignment
          : nearAlignment.alignment;
      final double mainOffset =
          (containerAxisSize.mainAxisExtent - nearAxisSize.mainAxisExtent) *
              alignment;
      final double crossOffset = isStarCrossPosition
          ? (containerAxisSize.crossAxisExtent - nearAxisSize.crossAxisExtent)
          : 0.0;
      offset = direction == Axis.horizontal
          ? Offset(mainOffset, crossOffset)
          : Offset(crossOffset, mainOffset);
      needMainSize = 0.0;
      needChildrenMainOffset = 0.0;
      needCrossSize = 0.0;
      needChildrenCrossOffset = isStarCrossPosition
          ? 0.0
          : (nearAxisSize.crossAxisExtent + nearSpacing);
    }
    positionChild(offset, nearRenderBox!);
    return (
      needChildrenMainOffset,
      needChildrenCrossOffset,
      needMainSize,
      needCrossSize
    );
  }

  void _positionChildren(
      List<_RunMetrics> runMetrics,
      _AxisSize freeAxisSize,
      _AxisSize containerAxisSize,
      _AxisSize? nearSize,
      _AxisSize? separateSize,
      _PositionChild positionChild,
      _GetChildSize getChildSize) {
    assert(runMetrics.isNotEmpty);
    final double totalSpacing =
        separateSize == null ? spacing : separateSize.mainAxisExtent;
    final double separateMainAxisExtent = separateSize?.mainAxisExtent ?? 0.0;
    final double separateCrossAxisExtent = separateSize?.crossAxisExtent ?? 0.0;

    final double crossAxisFreeSpace =
        math.max(0.0, freeAxisSize.crossAxisExtent);
    final (bool flipMainAxis, bool flipCrossAxis) = _areAxesFlipped;

    final (
      double needChildrenMainOffset,
      double needChildrenCrossOffset,
      double needMainSize,
      double needCrossSize
    ) = _positionNearChild(containerAxisSize, nearSize, flipMainAxis,
        flipCrossAxis, positionChild);

    final WrapMoreCrossAlignment effectiveCrossAlignment =
        flipCrossAxis ? crossAxisAlignment.flipped : crossAxisAlignment;
    final (double runLeadingSpace, double runBetweenSpace) =
        runAlignment.distributeSpace(
      crossAxisFreeSpace,
      runSpacing,
      runMetrics.length,
      flipCrossAxis,
    );
    final _NextChild nextChild = flipMainAxis ? childBefore : childAfter;

    double runCrossAxisOffset = runLeadingSpace + needChildrenCrossOffset;
    // [runs]中应该已经加入了[dropChild]的计算逻辑，且应该放置在最后一个中
    final Iterable<_RunMetrics> runs =
        flipCrossAxis ? runMetrics.reversed : runMetrics;
    for (final _RunMetrics run in runs) {
      final double runCrossAxisExtent = run.axisSize.crossAxisExtent;
      final int childCount = run.childCount;
      final bool hasDropChild =
          run.dropChild != null && run.dropChild == dropRenderBox;
      final int childCountWithoutDropChild =
          hasDropChild ? childCount - 1 : childCount;

      final double mainAxisFreeSpace = math.max(
          0.0,
          containerAxisSize.mainAxisExtent -
              run.axisSize.mainAxisExtent -
              needMainSize);
      final (double childLeadingSpace, double childBetweenSpace) =
          alignment.distributeSpace(mainAxisFreeSpace, totalSpacing,
              math.max(1, childCountWithoutDropChild), flipMainAxis);

      double childMainAxisOffset = childLeadingSpace + needChildrenMainOffset;
      final positionedDropChild = hasDropChild
          ? (double mainAxisOffset) {
              assert(run.dropChild != null);
              assert(run.dropChild == dropRenderBox);
              final RenderBox dropChild = run.dropChild!;
              final _AxisSize(
                mainAxisExtent: double childMainAxisExtent,
                crossAxisExtent: double childCrossAxisExtent
              ) = _AxisSize.fromSize(
                  size: getChildSize(dropChild), direction: direction);
              final double childCrossAxisOffset =
                  effectiveCrossAlignment.alignment *
                      (runCrossAxisExtent - childCrossAxisExtent);
              if (!flipMainAxis) {
                if (dropChildSpacing case final dcs?) {
                  // 重新规划[childMainAxisOffset]偏移值
                  mainAxisOffset += (-childBetweenSpace + dcs);
                }
              }

              positionChild(
                  _getOffset(mainAxisOffset,
                      runCrossAxisOffset + childCrossAxisOffset),
                  dropChild);
              if (flipMainAxis) {
                mainAxisOffset += childMainAxisExtent +
                    (dropChildSpacing == null
                        ? childBetweenSpace
                        : dropChildSpacing!);
              } else {
                mainAxisOffset += childMainAxisExtent + childBetweenSpace;
              }
              return mainAxisOffset;
            }
          : null;

      // 定位[dropChild]
      if (flipMainAxis && hasDropChild) {
        childMainAxisOffset = positionedDropChild!(childMainAxisOffset);
      }

      int remainingChildCount = childCountWithoutDropChild;
      for (RenderBox? child = run.leadingChild;
          child != null && remainingChildCount > 0;
          child = nextChild(child), remainingChildCount -= 1) {
        assert(child != dropRenderBox);
        final _AxisSize(
          mainAxisExtent: double childMainAxisExtent,
          crossAxisExtent: double childCrossAxisExtent
        ) = _AxisSize.fromSize(size: getChildSize(child), direction: direction);
        final double childCrossAxisOffset = effectiveCrossAlignment.alignment *
            (runCrossAxisExtent - childCrossAxisExtent);
        positionChild(
            _getOffset(
                childMainAxisOffset, runCrossAxisOffset + childCrossAxisOffset),
            child);
        final WrapMoreParentData parentData =
            child.parentData as WrapMoreParentData;
        if (parentData.hasNextSeparate) {
          // Next step positioned separateChild
          final double separateChildCrossAxisOffset =
              effectiveCrossAlignment.alignment *
                  (runCrossAxisExtent - separateCrossAxisExtent);
          // positioned the center of childBetweenSpace
          if (flipMainAxis) {
            parentData.nextSeparateOffset = _getOffset(
                childMainAxisOffset -
                    separateMainAxisExtent -
                    (childBetweenSpace - separateMainAxisExtent) / 2,
                runCrossAxisOffset + separateChildCrossAxisOffset);
          } else {
            parentData.nextSeparateOffset = _getOffset(
                childMainAxisOffset +
                    childMainAxisExtent +
                    (childBetweenSpace - separateMainAxisExtent) / 2,
                runCrossAxisOffset + separateChildCrossAxisOffset);
          }
        }
        childMainAxisOffset += childMainAxisExtent + childBetweenSpace;
      }

      // 定位[dropChild]
      if (!flipMainAxis && hasDropChild) {
        childMainAxisOffset = positionedDropChild!(childMainAxisOffset);
      }
      runCrossAxisOffset += runCrossAxisExtent + runBetweenSpace;
    }
  }

  bool _hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final List<RenderBox> children = [];
    RenderBox? child = firstChild;
    while (child != null) {
      final WrapMoreParentData childParentData =
          child.parentData! as WrapMoreParentData;
      children.add(child);

      if (childParentData.isEndLineLast) {
        break;
      }

      if (childParentData.needPaintDropChild) {
        if (dropRenderBox case final drb?) {
          children.add(drb);
        }
        break;
      } else if (childParentData.hasNextSeparate) {
        if (separateRenderBox case final srb?) {
          children.add(srb);
        }
      }

      child = childParentData.nextSibling;
    }

    if (nearRenderBox case final child?) {
      final WrapMoreParentData childParentData =
          child.parentData! as WrapMoreParentData;
      if (childParentData.showNearChild) {
        children.add(child);
      }
    }

    final int length = children.length;
    for (int i = length - 1; i >= 0; i--) {
      final child = children[i];
      final Offset childOffset;
      if (child == separateRenderBox) {
        assert(i > 0);
        final preChild = children[i - 1];
        final WrapMoreParentData preChildParentData =
            preChild.parentData! as WrapMoreParentData;
        childOffset = preChildParentData.nextSeparateOffset;
      } else {
        final WrapMoreParentData childParentData =
            child.parentData! as WrapMoreParentData;
        childOffset = childParentData.offset;
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childOffset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }

    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return _hitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // TODO(ianh): move the debug flex overflow paint logic somewhere common so
    // it can be reused here
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      _paint(context, offset);
    }
  }

  // 绘制
  void _paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final WrapMoreParentData childParentData =
          child.parentData! as WrapMoreParentData;
      context.paintChild(child, childParentData.offset + offset);
      if (childParentData.isEndLineLast) {
        break;
      }
      if (childParentData.needPaintDropChild) {
        final RenderBox? dropRenderBox = this.dropRenderBox;
        assert(dropRenderBox != null);
        if (dropRenderBox != null) {
          final WrapMoreParentData dropChildParentData =
              dropRenderBox.parentData! as WrapMoreParentData;
          context.paintChild(
              dropRenderBox, dropChildParentData.offset + offset);
        }
        // [dropChild]之后不会再绘制任何元素
        break;
      } else if (childParentData.hasNextSeparate) {
        final RenderBox? separateRenderBox = this.separateRenderBox;
        assert(separateRenderBox != null);
        if (separateRenderBox != null) {
          context.paintChild(
              separateRenderBox, childParentData.nextSeparateOffset + offset);
        }
      }
      child = childParentData.nextSibling;
    }

    if (nearRenderBox case final child?) {
      final WrapMoreParentData nearParentData =
          child.parentData! as WrapMoreParentData;
      if (nearParentData.showNearChild) {
        context.paintChild(child, nearParentData.offset + offset);
      }
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }
}

// Parent data for use with [RenderWrapMore].
class WrapMoreParentData extends ContainerBoxParentData<RenderBox> {
  // 是否绘制下一个[dropChild]，该变量只在绘制时有用
  bool needPaintDropChild = false;
  // 是否结束行的最后一个
  bool isEndLineLast = false;
  // 是否展示[nearChild]
  bool showNearChild = false;
  // 是否下一个有[separate]
  bool hasNextSeparate = false;
  // 下一个[separate]的偏移
  Offset nextSeparateOffset = Offset.zero;
}
