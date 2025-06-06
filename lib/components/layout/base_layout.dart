import 'package:flutter/material.dart';
import '../../themes/design_tokens.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool useSafeArea;
  final EdgeInsets? padding;

  const BaseLayout({
    Key? key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.useSafeArea = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? DesignTokens.backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: useSafeArea
          ? SafeArea(
              child: Padding(
                padding: padding ?? EdgeInsets.all(DesignTokens.spacingMd),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.all(DesignTokens.spacingMd),
              child: child,
            ),
    );
  }
}

class BaseScrollLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool useSafeArea;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const BaseScrollLayout({
    Key? key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.useSafeArea = true,
    this.padding,
    this.controller,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? DesignTokens.backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: useSafeArea
          ? SafeArea(
              child: SingleChildScrollView(
                controller: controller,
                physics: physics,
                child: Padding(
                  padding: padding ?? EdgeInsets.all(DesignTokens.spacingMd),
                  child: child,
                ),
              ),
            )
          : SingleChildScrollView(
              controller: controller,
              physics: physics,
              child: Padding(
                padding: padding ?? EdgeInsets.all(DesignTokens.spacingMd),
                child: child,
              ),
            ),
    );
  }
} 