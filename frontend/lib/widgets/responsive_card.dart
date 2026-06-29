import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import '../utils/app_spacing.dart';

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      elevation: elevation ?? 3,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ??
            BorderRadius.circular(
              Responsive.isMobile(context) ? 12 : 16,
            ),
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    return SizedBox(
      width: Responsive.cardWidth(context),
      child: onTap == null
          ? card
          : InkWell(
              borderRadius: borderRadius ??
                  BorderRadius.circular(
                    Responsive.isMobile(context) ? 12 : 16,
                  ),
              onTap: onTap,
              child: card,
            ),
    );
  }
}