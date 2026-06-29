import 'package:flutter/material.dart';
import 'responsive.dart';

class ResponsivePage extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const ResponsivePage({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: Responsive.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: child,
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        child: content,
      );
    }

    return SafeArea(
      child: content,
    );
  }
}