import 'package:flutter/material.dart';
import 'package:profit_track/app/theme.dart';

class ProfitIcon extends StatelessWidget {
  const ProfitIcon(
    this.icon, {
    super.key,
    this.color = AppColors.green,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
