import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// 480×234 TFT üzerinde okunabilirlik için sabit piksel boyutlu metin stilleri.
///
/// Cockpit içinde sistem yazı tipi ölçeklemesi uygulanmaz (bkz. CockpitView).
abstract final class TftTextStyles {
  static const TextStyle topBar = TextStyle(
    fontSize: 12,
    height: 1.1,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 9,
    height: 1.1,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.6,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    height: 1.0,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 12,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    height: 1.15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
