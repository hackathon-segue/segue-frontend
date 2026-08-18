import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';

/// Matches the Figma "Image" component: a dashed-border square placeholder
/// (product thumbnails) or a solid-fill circle placeholder (avatars).
class StaffImagePlaceholder extends StatelessWidget {
  const StaffImagePlaceholder.square({this.size = 64, super.key})
    : isRound = false,
      label = 'Image';

  const StaffImagePlaceholder.avatar({this.size = StaffSizes.avatarSize, super.key})
    : isRound = true,
      label = 'Aa';

  final double size;
  final bool isRound;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      label,
      style: StaffText.meta11.copyWith(color: isRound ? Colors.white : StaffColors.placeholder),
    );

    if (isRound) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: StaffColors.avatarBg, shape: BoxShape.circle),
        child: text,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _DashedRRectPainter(radius: 6, color: StaffColors.inputBorder),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: StaffColors.cardBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: text,
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);
    const double dashWidth = 4;
    const double dashGap = 3;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
