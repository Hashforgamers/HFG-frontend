import 'package:flutter/material.dart';
import '../../themes/design_tokens.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isLoading;

  const BaseCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? EdgeInsets.all(DesignTokens.spacingMd),
      elevation: elevation ?? 0,
      color: backgroundColor ?? DesignTokens.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.borderRadiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.borderRadiusMd),
        child: Stack(
          children: [
            Padding(
              padding: padding ?? EdgeInsets.all(DesignTokens.spacingMd),
              child: child,
            ),
            if (isLoading)
              Container(
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceColor.withOpacity(0.7),
                  borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.borderRadiusMd),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 