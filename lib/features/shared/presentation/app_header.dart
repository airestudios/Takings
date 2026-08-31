import 'package:flutter/material.dart';
import 'package:profit_track/app/theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, compact ? 10 : 16, 14, 8),
      child: Row(
        children: [
          const _Logo(),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Alex 👋',
                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                ),
                Text(
                  'ProfitTrack',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            showDot: true,
            label: 'Notifications',
          ),
          const SizedBox(width: 10),
          _HeaderAction(
            icon: Icons.person_outline_rounded,
            onTap: () {},
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: AppColors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x26079447),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    required this.label,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, size: 25, color: AppColors.navy)),
              if (showDot)
                const Positioned(
                  right: 3,
                  top: 2,
                  child: CircleAvatar(
                    radius: 3.5,
                    backgroundColor: AppColors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
