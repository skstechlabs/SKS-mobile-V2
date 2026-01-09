import 'package:flutter/material.dart';

/// Extension on BuildContext for easier responsive design
extension ResponsiveContext on BuildContext {
  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Returns true if screen is tablet/desktop size (width > 600px)
  bool get isTabletOrLarger => screenWidth > 600;
  
  /// Returns true if screen is tall (height > 700px)
  bool get isTallScreen => screenHeight > 700;
  
  /// Returns true if screen is mobile size
  bool get isMobile => screenWidth <= 600;
  
  /// Safe area padding
  EdgeInsets get safeArea => MediaQuery.of(this).padding;
  
  /// Available height considering system UI
  double get availableHeight => screenHeight - safeArea.top - safeArea.bottom;
  
  /// Available height considering app bar and system UI
  double get availableHeightWithAppBar => 
      availableHeight - AppBar().preferredSize.height;
}