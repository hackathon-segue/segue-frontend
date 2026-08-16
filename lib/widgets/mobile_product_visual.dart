import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_design_tokens.dart';

class MobileProductVisual extends StatelessWidget {
  const MobileProductVisual({
    required this.product,
    this.colorOverride,
    this.compact = false,
    super.key,
  });

  final MobileProduct product;
  final Color? colorOverride;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color productColor = colorOverride ?? Color(product.visualValue);
    final Color accentColor = Color(product.accentValue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          productColor.withValues(alpha: 0.08),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: _ProductVisualPainter(
          bodyColor: productColor,
          accentColor: accentColor,
          compact: compact,
          isWallet: product.category == '지갑',
          isBackpack: product.category == '백팩',
        ),
      ),
    );
  }
}

class _ProductVisualPainter extends CustomPainter {
  const _ProductVisualPainter({
    required this.bodyColor,
    required this.accentColor,
    required this.compact,
    required this.isWallet,
    required this.isBackpack,
  });

  final Color bodyColor;
  final Color accentColor;
  final bool compact;
  final bool isWallet;
  final bool isBackpack;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shadowPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final Paint bodyPaint = Paint()..color = bodyColor;
    final Paint accentPaint = Paint()..color = accentColor;
    final Paint stitchPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.2 : 1.8;

    final Rect shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.72),
      width: size.width * 0.52,
      height: size.height * 0.14,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    if (isWallet) {
      _paintWallet(canvas, size, bodyPaint, accentPaint, stitchPaint);
      return;
    }

    if (isBackpack) {
      _paintBackpack(canvas, size, bodyPaint, accentPaint, stitchPaint);
      return;
    }

    _paintCrossbody(canvas, size, bodyPaint, accentPaint, stitchPaint);
  }

  void _paintBackpack(
    Canvas canvas,
    Size size,
    Paint bodyPaint,
    Paint accentPaint,
    Paint stitchPaint,
  ) {
    final Rect body = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.22,
      size.width * 0.44,
      size.height * 0.5,
    );
    final RRect bodyShape = RRect.fromRectAndRadius(
      body,
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(bodyShape, bodyPaint);

    final Rect pocket = Rect.fromLTWH(
      size.width * 0.36,
      size.height * 0.48,
      size.width * 0.28,
      size.height * 0.16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pocket, Radius.circular(size.width * 0.04)),
      Paint()..color = accentPaint.color.withValues(alpha: 0.34),
    );
    canvas.drawRRect(bodyShape.deflate(size.width * 0.035), stitchPaint);

    final Paint strapPaint = Paint()
      ..color = accentPaint.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = compact ? 4 : 7;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.12,
        size.width * 0.24,
        size.height * 0.2,
      ),
      3.25,
      2.95,
      false,
      strapPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.34),
      Offset(size.width * 0.2, size.height * 0.62),
      strapPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.34),
      Offset(size.width * 0.8, size.height * 0.62),
      strapPaint,
    );
  }

  void _paintCrossbody(
    Canvas canvas,
    Size size,
    Paint bodyPaint,
    Paint accentPaint,
    Paint stitchPaint,
  ) {
    final Paint strapPaint = Paint()
      ..color = accentPaint.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = compact ? 3 : 5;
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.18),
      Offset(size.width * 0.76, size.height * 0.72),
      strapPaint,
    );

    final Rect body = Rect.fromLTWH(
      size.width * 0.26,
      size.height * 0.36,
      size.width * 0.48,
      size.height * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(size.width * 0.05)),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(body.left + body.width * 0.08, body.top + body.height * 0.34),
      Offset(body.right - body.width * 0.08, body.top + body.height * 0.34),
      stitchPaint,
    );
  }

  void _paintWallet(
    Canvas canvas,
    Size size,
    Paint bodyPaint,
    Paint accentPaint,
    Paint stitchPaint,
  ) {
    final Rect body = Rect.fromLTWH(
      size.width * 0.22,
      size.height * 0.36,
      size.width * 0.56,
      size.height * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(size.width * 0.04)),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(body.left + body.width * 0.12, body.center.dy),
      Offset(body.right - body.width * 0.12, body.center.dy),
      stitchPaint,
    );
    canvas.drawCircle(
      body.centerRight - Offset(body.width * 0.2, 0),
      3,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_ProductVisualPainter oldDelegate) {
    return bodyColor != oldDelegate.bodyColor ||
        accentColor != oldDelegate.accentColor ||
        compact != oldDelegate.compact ||
        isWallet != oldDelegate.isWallet ||
        isBackpack != oldDelegate.isBackpack;
  }
}
