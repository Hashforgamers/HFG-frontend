import 'package:flutter/material.dart';
import '../../themes/design_tokens.dart';

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight;

  const BaseAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
    this.toolbarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: DesignTokens.textPrimaryColor,
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? DesignTokens.surfaceColor,
      bottom: bottom,
      toolbarHeight: toolbarHeight,
      iconTheme: IconThemeData(
        color: DesignTokens.primaryColor,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);
}

class BaseSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight;
  final bool floating;
  final bool pinned;
  final bool snap;
  final Widget? flexibleSpace;

  const BaseSliverAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
    this.toolbarHeight,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.flexibleSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: TextStyle(
          color: DesignTokens.textPrimaryColor,
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? DesignTokens.surfaceColor,
      bottom: bottom,
      toolbarHeight: toolbarHeight,
      iconTheme: IconThemeData(
        color: DesignTokens.primaryColor,
      ),
      floating: floating,
      pinned: pinned,
      snap: snap,
      flexibleSpace: flexibleSpace,
    );
  }
} 