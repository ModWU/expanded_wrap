/// Who [Wrap] should align children within a run in the cross axis.
enum WrapMoreCrossAlignment {
  /// Place the children as close to the start of the run in the cross axis as
  /// possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the children as close to the end of the run in the cross axis as
  /// possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
  end,

  /// Place the children as close to the middle of the run in the cross axis as
  /// possible.
  center;

  // TODO(ianh): baseline.

  WrapMoreCrossAlignment get flipped => switch (this) {
        WrapMoreCrossAlignment.start => WrapMoreCrossAlignment.end,
        WrapMoreCrossAlignment.end => WrapMoreCrossAlignment.start,
        WrapMoreCrossAlignment.center => WrapMoreCrossAlignment.center,
      };

  double get alignment => switch (this) {
        WrapMoreCrossAlignment.start => 0,
        WrapMoreCrossAlignment.end => 1,
        WrapMoreCrossAlignment.center => 0.5,
      };
}

/// How [Wrap] should align objects.
///
/// Used both to align children within a run in the main axis as well as to
/// align the runs themselves in the cross axis.
enum WrapMoreAlignment {
  /// Place the objects as close to the start of the axis as possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the objects as close to the end of the axis as possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
  end,

  /// Place the objects as close to the middle of the axis as possible.
  center,

  /// Place the free space evenly between the objects.
  spaceBetween,

  /// Place the free space evenly between the objects as well as half of that
  /// space before and after the first and last objects.
  spaceAround,

  /// Place the free space evenly between the objects as well as before and
  /// after the first and last objects.
  spaceEvenly;

  (double leadingSpace, double betweenSpace) distributeSpace(
      double freeSpace, double itemSpacing, int itemCount, bool flipped) {
    assert(itemCount > 0);
    return switch (this) {
      WrapMoreAlignment.start => (flipped ? freeSpace : 0.0, itemSpacing),
      WrapMoreAlignment.end => WrapMoreAlignment.start
          .distributeSpace(freeSpace, itemSpacing, itemCount, !flipped),
      WrapMoreAlignment.spaceBetween when itemCount < 2 => WrapMoreAlignment
          .start
          .distributeSpace(freeSpace, itemSpacing, itemCount, flipped),
      WrapMoreAlignment.center => (freeSpace / 2.0, itemSpacing),
      WrapMoreAlignment.spaceBetween => (
          0,
          freeSpace / (itemCount - 1) + itemSpacing
        ),
      WrapMoreAlignment.spaceAround => (
          freeSpace / itemCount / 2,
          freeSpace / itemCount + itemSpacing
        ),
      WrapMoreAlignment.spaceEvenly => (
          freeSpace / (itemCount + 1),
          freeSpace / (itemCount + 1) + itemSpacing
        ),
    };
  }
}

enum WrapMoreNearAlignment {
  /// Place the children as close to the start of the run in the cross axis as
  /// possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the start is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the start is the top or the bottom.
  start,

  /// Place the children as close to the end of the run in the cross axis as
  /// possible.
  ///
  /// If this value is used in a horizontal direction, a [TextDirection] must be
  /// available to determine if the end is the left or the right.
  ///
  /// If this value is used in a vertical direction, a [VerticalDirection] must be
  /// available to determine if the end is the top or the bottom.
  end,

  /// Place the children as close to the middle of the run in the cross axis as
  /// possible.
  center,

  /// Require the children to fill the cross axis.
  ///
  /// This causes the constraints passed to the children to be tight in the
  /// cross axis.
  stretch;

  // TODO(ianh): baseline.

  WrapMoreNearAlignment get flipped => switch (this) {
        WrapMoreNearAlignment.start => WrapMoreNearAlignment.end,
        WrapMoreNearAlignment.end => WrapMoreNearAlignment.start,
        WrapMoreNearAlignment.center => WrapMoreNearAlignment.center,
        WrapMoreNearAlignment.stretch => WrapMoreNearAlignment.stretch,
      };

  double get alignment => switch (this) {
        WrapMoreNearAlignment.start => 0,
        WrapMoreNearAlignment.end => 1,
        WrapMoreNearAlignment.center => 0.5,
        WrapMoreNearAlignment.stretch => 0,
      };
}
