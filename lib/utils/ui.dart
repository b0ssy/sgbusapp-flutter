import 'package:flutter/material.dart';

enum UIRouteEnterType {
  slideLeft,
  slideUp,
  fade,
}

enum UIRouteExitType {
  scaleDown,
}

class UIRoute<T> extends PageRouteBuilder<T> {
  final Widget enterChild;
  final UIRouteEnterType enterType;
  final Widget? exitChild;
  final UIRouteExitType exitType;

  UIRoute({
    required this.enterChild,
    this.enterType = UIRouteEnterType.slideUp,
    this.exitChild,
    this.exitType = UIRouteExitType.scaleDown,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              enterChild,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              Stack(
            children: [
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              if (exitChild != null && exitType == UIRouteExitType.scaleDown)
                ScaleTransition(
                  scale: Tween<double>(
                    begin: 1.0,
                    end: 0.9,
                  ).animate(animation),
                  child: exitChild,
                ),
              if (enterType == UIRouteEnterType.slideLeft) ...[
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: child,
                ),
              ] else if (enterType == UIRouteEnterType.slideUp) ...[
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCirc,
                    ),
                  ),
                  child: child,
                ),
              ] else if (enterType == UIRouteEnterType.fade) ...[
                FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              ],
            ],
          ),
        );
}
