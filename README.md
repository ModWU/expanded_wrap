<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

We use the expanded_wrap plugin to build a expanded wrap。

## Features

* support minLines
* support maxLines
* support dropChild
* support nearChild
* support separate

## Getting started

```yaml
dependencies:
  expanded_wrap: '^0.0.3'
```

## Usage

```dart
_buildExpandedWrap() async {
  return ExpandedWrap(
    spacing: 24,
    runSpacing: 24,
    minLines: minLines,
    maxLines: maxLines,
    nearChild: Text('nearChild'),
    nearAlignment: WrapMoreNearAlignment.stretch,
    alwaysShowNearChild:
    false, // When set to false, it means that [nearChild] will only be displayed when there is more unfinished data
    nearSpacing: 20,
    nearDirection: AxisDirection.left,
    separate: Container(
      width: 1,
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 4),
      color: Colors.red,
    ),
    dropBuilder: (BuildContext context, ExpandedWrapController controller,
        Widget? child) {
      return Material(
        child: Ink(
          color: Colors.red.withValues(alpha: 0.1),
          width: 100,
          height: 24,
          child: InkWell(
            onTap: controller.toggle,
            child: Center(
              child: Text(
                controller.isExpanded ? 'collapse' : 'expand',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    },
    children: textList.indexed
        .map(
          (s) => Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.01),
          border: Border.all(color: Colors.red, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12),
        height: 24,
        child: Align(
          heightFactor: 1.0,
          widthFactor: 1.0,
          child: Text(
            '${s.$1}#${s.$2}',
            textAlign: TextAlign.start,
            maxLines: 2,
            //overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    )
        .toList(),
  );
}
```
