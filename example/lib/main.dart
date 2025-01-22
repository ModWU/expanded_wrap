import 'dart:math';

import 'package:expanded_wrap/expanded_wrap.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isExtended = true;

  List<String> textList = [];

  int minLines = 2;
  int? maxLines;

  ExpandedWrapController controller = ExpandedWrapController();

  void setExpanded(bool value) {
    setState(() {
      isExtended = value;
    });
  }

  void _randomMinLines() {
    setState(() {
      minLines = Random().nextInt(10);
    });
  }

  void _randomMaxLines() {
    setState(() {
      final bool hasMaxLines = Random().nextDouble() > 0.2 ? true : false;
      maxLines = hasMaxLines ? ((minLines - 1) + Random().nextInt(10)) : null;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _randomChildren() {
    final int u_a = 'a'.codeUnitAt(0);
    final int u_z = 'z'.codeUnitAt(0);
    final int u_A = 'A'.codeUnitAt(0);
    final int u_Z = 'Z'.codeUnitAt(0);
    final List<String> all =
        List.generate(u_z - u_a, (i) => String.fromCharCode(u_a + i)) +
            List.generate(u_Z - u_A, (i) => String.fromCharCode(u_A + i));
    final int length = all.length;
    int count = 4 + Random().nextInt(50);
    final list = <String>[];
    while (count-- > 0) {
      int rLength = Random().nextInt(10);
      final List<String> strList = [];
      while (rLength-- > 0) {
        final int index = Random().nextInt(length);
        strList.add(all[index]);
      }
      list.add(strList.join());
    }
    setState(() {
      textList = list;
    });
  }

  Widget b(String str) {
    return Container(
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
          str,
          textAlign: TextAlign.start,
          maxLines: 2,
          //overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _button(
    String str,
    VoidCallback onTap, {
    EdgeInsetsGeometry? margin,
    Color? color,
    Color? textColor,
    double? height,
    double? width,
  }) {
    final Widget child = Material(
      child: Ink(
        color: color ?? Colors.red.withValues(alpha: 0.1),
        width: width,
        height: height ?? 34,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              str,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );

    return margin == null
        ? child
        : Padding(
            padding: margin,
            child: child,
          );
  }

  Widget buildReset(VoidCallback onTap, {String? str}) {
    return _button(
      str ?? 'reset',
      onTap,
      margin: EdgeInsets.symmetric(horizontal: 48),
    );
  }

  Widget v(double space) {
    return SizedBox(height: space);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('ExpandedWrap test'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              v(20),
              Text('count: ${textList.length}'),
              v(12),
              // ExpandedWrap
              Container(
                color: Colors.green.withValues(alpha: 0.1),
                width: double.infinity,
                child: ExpandedWrap(
                  spacing: 24,
                  runSpacing: 24,
                  minLines: minLines,
                  maxLines: maxLines,
                  nearChild: GestureDetector(
                    onTap: () {
                      print("near");
                    },
                    child: Container(
                      width: 80,
                      height: 20,
                      color: Colors.red.withValues(alpha: 0.1),
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                          animation: controller,
                          builder: (_, __) {
                            return _button(
                              controller.isExpanded ? 'collapse' : 'expand',
                              controller.toggle,
                              color: Colors.white,
                            );
                          }),
                    ),
                  ),
                  nearAlignment: WrapMoreNearAlignment.stretch,
                  alwaysShowNearChild:
                      false, // When set to false, it means that [nearChild] will only be displayed when there is more unfinished data
                  nearSpacing: 20,
                  nearDirection: AxisDirection.left,
                  controller: controller,
                  dropBuilder: (BuildContext context,
                      ExpandedWrapController controller, Widget? child) {
                    return _button(
                      controller.isExpanded ? 'collapse' : 'expand',
                      controller.toggle,
                      width: 100,
                      height: 24,
                      textColor: Colors.white,
                      color: Colors.grey,
                    );
                  },
                  children: textList.indexed
                      .map((s) => b('${s.$1}#${s.$2}'))
                      .toList(),
                ),
              ),
              v(24),
              buildReset(_randomChildren),
              v(20),
              Text('minLines: $minLines'),
              buildReset(_randomMinLines),
              v(20),
              Text('maxLines: $maxLines'),
              buildReset(_randomMaxLines),
              v(6),
              AnimatedBuilder(
                  animation: controller,
                  builder: (_, __) {
                    return buildReset(
                      controller.toggle,
                      str: controller.isExpanded ? 'collapse' : 'expand',
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
