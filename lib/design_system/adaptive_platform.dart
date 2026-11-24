import 'package:flutter/foundation.dart';

bool get usesCupertinoControls =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
