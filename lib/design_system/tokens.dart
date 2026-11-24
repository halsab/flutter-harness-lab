import 'package:flutter/widgets.dart';

abstract final class AppTokens {
  // Material palette seed only, not a resolved UI color or iOS accent.
  static const materialSeed = Color(0xFF2563EB);
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const radius = 12.0;
  static const compactWidth = 600.0;
  static const expandedWidth = 840.0;
  static const contentWidth = 720.0;
  static const iosTarget = 44.0;
  static const materialTarget = 48.0;
  static const rowHeight = 56.0;
  static const searchPullDistance = 24.0;
  static const segmentedMinWidth = 345.0;
  static const editorWidth = 480.0;
  static const shortViewportHeight = 220.0;
  static const controlIcon = 20.0;
  static const completionIcon = 24.0;
  static const sectionGap = 12.0;
  static const groupRadius = 14.0;
  static const dividerHeight = 1.0;
  static const disclosureDuration = Duration(milliseconds: 180);
  static const pagePadding = EdgeInsets.all(space16);
}
