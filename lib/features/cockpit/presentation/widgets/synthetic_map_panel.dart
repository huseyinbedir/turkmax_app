import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_dimens.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Gerçek harita yerine kullanılan, lisans riski taşımayan sentetik harita.
///
/// Google içeriği barındırmaz; her zaman açıkça etiketlenir.
class SyntheticMapPanel extends StatelessWidget {
  const SyntheticMapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _SyntheticMapPainter()),
        Positioned(
          left: AppSpacing.xs,
          bottom: AppSpacing.xs,
          child: Text(
            AppLocalizations.of(context).syntheticMapLabel,
            style: TftTextStyles.label,
          ),
        ),
      ],
    );
  }
}

class _SyntheticMapPainter extends CustomPainter {
  const _SyntheticMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.surface);

    final road = Paint()
      ..color = AppColors.elevated
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    for (final fx in const [0.18, 0.46, 0.78]) {
      canvas.drawLine(
        Offset(size.width * fx, 0),
        Offset(size.width * fx, size.height),
        road,
      );
    }
    for (final fy in const [0.22, 0.58, 0.88]) {
      canvas.drawLine(
        Offset(0, size.height * fy),
        Offset(size.width, size.height * fy),
        road,
      );
    }

    final route = Path()
      ..moveTo(size.width * 0.46, size.height)
      ..lineTo(size.width * 0.46, size.height * 0.58)
      ..lineTo(size.width * 0.78, size.height * 0.58)
      ..lineTo(size.width * 0.78, size.height * 0.08);
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final position = Offset(size.width * 0.46, size.height * 0.8);
    canvas.drawCircle(position, 8, Paint()..color = AppColors.background);
    canvas.drawCircle(position, 6, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(_SyntheticMapPainter oldDelegate) => false;
}
