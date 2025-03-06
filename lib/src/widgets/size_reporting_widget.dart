import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';

class SizeReportingWidget extends StatelessWidget {
  const SizeReportingWidget({
    required this.child,
    required this.onSize,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final void Function(Size size) onSize;

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: _Delegate(onSize),
      children: [
        LayoutId(id: #child, child: child),
      ],
    );
  }
}

class _Delegate extends BoxyDelegate {
  _Delegate(this.onSize);

  final void Function(Size size) onSize;

  @override
  Size layout() {
    final child = getChild(#child);

    final size = child.layout(constraints);

    onSize(size);

    return size;
  }
}
