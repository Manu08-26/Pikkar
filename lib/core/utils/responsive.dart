import 'package:flutter/material.dart';

class Responsive {
  // Base width for design (iPhone 12/13 standard - 375px)
  static const double _baseWidth = 375.0;

  // Get screen width
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  
  // Get screen height
  static double height(BuildContext context) => MediaQuery.of(context).size.height;
  
  // Get screen size
  static Size size(BuildContext context) => MediaQuery.of(context).size;

  // Get scale factor based on width
  static double _scaleFactor(BuildContext context) {
    final screenWidth = width(context);
    final scaleFactor = screenWidth / _baseWidth;
    // Limit scaling to reasonable bounds (0.85 to 1.15)
    return scaleFactor.clamp(0.85, 1.15);
  }

  // Responsive width (percentage of screen width)
  static double wp(BuildContext context, double percent) {
    return width(context) * (percent / 100);
  }

  // Responsive height (percentage of screen height)
  static double hp(BuildContext context, double percent) {
    return height(context) * (percent / 100);
  }

  // Responsive font size (scales based on screen width)
  static double fontSize(BuildContext context, double size) {
    return size * _scaleFactor(context);
  }

  // Responsive spacing (scales based on screen width)
  static double spacing(BuildContext context, double size) {
    return size * _scaleFactor(context);
  }

  // Responsive padding (scales based on screen width)
  static double padding(BuildContext context, double size) {
    final scaleFactor = _scaleFactor(context);
    // For very small screens, ensure minimum padding
    if (width(context) < 360) {
      return (size * scaleFactor).clamp(size * 0.75, size * 1.0);
    }
    return size * scaleFactor;
  }

  // Responsive icon size
  static double iconSize(BuildContext context, double size) {
    return size * _scaleFactor(context);
  }

  // Check screen size categories
  static bool isSmallScreen(BuildContext context) => width(context) < 360;
  static bool isMediumScreen(BuildContext context) => width(context) >= 360 && width(context) < 414;
  static bool isLargeScreen(BuildContext context) => width(context) >= 414;

  // Safe area insets
  static EdgeInsets safeArea(BuildContext context) => MediaQuery.of(context).padding;
  
  // Viewport height excluding keyboard
  static double viewportHeight(BuildContext context) {
    return height(context) - MediaQuery.of(context).viewInsets.bottom;
  }
}

