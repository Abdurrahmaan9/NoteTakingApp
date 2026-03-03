import 'package:flutter/widgets.dart';

class ResponsiveBreakpoints {
  // Breakpoint constants
  static const double mobile = 600;
  static const double tablet = 1200;
  
  // Device type checkers
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
  
  // Grid column counts
  static int getStatsColumns(double width) {
    if (isMobile(width)) return 2;
    if (isTablet(width)) return 3;
    return 4;
  }
  
  static int getQuickActionsColumns(double width) {
    if (isMobile(width)) return 1;
    return 2;
  }
  
  // Aspect ratios
  static double getStatsAspectRatio(double width) {
    if (isMobile(width)) return 1.2;
    if (isTablet(width)) return 1.1;
    return 1.0;
  }
  
  // Padding values
  static EdgeInsets getScreenPadding(double width) {
    if (isMobile(width)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
    } else if (isTablet(width)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 40);
    }
  }
  
  static EdgeInsets getCardPadding(double width) {
    if (isMobile(width)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(width)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  // Spacing values
  static double getSectionSpacing(double width) {
    if (isMobile(width)) return 24.0;
    if (isTablet(width)) return 32.0;
    return 40.0;
  }
  
  static double getItemSpacing(double width) {
    if (isMobile(width)) return 12.0;
    if (isTablet(width)) return 16.0;
    return 20.0;
  }
  
  // Font sizes
  static double getHeaderFontSize(double width) {
    if (isMobile(width)) return 24.0;
    if (isTablet(width)) return 28.0;
    return 32.0;
  }
  
  static double getTitleFontSize(double width) {
    if (isMobile(width)) return 20.0;
    if (isTablet(width)) return 22.0;
    return 24.0;
  }
}
