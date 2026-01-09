import 'package:flutter/material.dart';

/// Utility class for responsive design helpers
class ResponsiveUtils {
  /// Returns true if the screen width is greater than 600px (tablet/desktop)
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// Returns true if the screen height is greater than 700px (tall screen)
  static bool isTallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height > 700;
  }

  /// Returns responsive height based on screen size
  static double getResponsiveHeight(BuildContext context, {
    required double baseHeight,
    double? tabletHeight,
  }) {
    if (isTabletOrLarger(context)) {
      return tabletHeight ?? baseHeight;
    }
    return baseHeight;
  }

  /// Returns responsive width based on screen size
  static double getResponsiveWidth(BuildContext context, {
    required double baseWidth,
    double? tabletWidth,
  }) {
    if (isTabletOrLarger(context)) {
      return tabletWidth ?? baseWidth;
    }
    return baseWidth;
  }

  /// Returns responsive spacing based on screen height
  static double getResponsiveSpacing(BuildContext context, {
    required double baseSpacing,
    double? tallScreenSpacing,
  }) {
    if (isTallScreen(context)) {
      return tallScreenSpacing ?? baseSpacing;
    }
    return baseSpacing;
  }

  /// Returns responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {
    required double baseFontSize,
    double? tabletFontSize,
  }) {
    if (isTabletOrLarger(context)) {
      return tabletFontSize ?? baseFontSize;
    }
    return baseFontSize;
  }

  /// Returns the available height considering app bar and system UI
  static double getAvailableHeight(BuildContext context, {
    bool hasAppBar = true,
  }) {
    double totalHeight = MediaQuery.of(context).size.height;
    double topPadding = MediaQuery.of(context).padding.top;
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    double appBarHeight = hasAppBar ? AppBar().preferredSize.height : 0;
    
    return totalHeight - topPadding - bottomPadding - appBarHeight;
  }

  /// Creates a responsive container with minimum height to prevent overflow
  static Widget createScrollableContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    bool hasAppBar = true,
  }) {
    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: getAvailableHeight(context, hasAppBar: hasAppBar),
        ),
        child: child,
      ),
    );
  }
}