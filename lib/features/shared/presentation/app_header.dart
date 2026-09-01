import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/settings/application/settings_controller.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(settingsControllerProvider).value?.displayName.trim() ?? '';
    final greeting = _greetingForHour(DateTime.now().hour);

    return Padding(
      padding: EdgeInsets.fromLTRB(14, compact ? 10 : 16, 14, 8),
      child: Row(
        children: [
          const _Logo(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty
                      ? '$greeting 👋'
                      : '$greeting, $displayName 👋',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 4),
                Image.asset(
                  'assets/images/takings_wordmark_header.png',
                  height: 22,
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.contain,
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
    return SizedBox(
      width: 46,
      height: 46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'assets/images/takings_icon.png',
          fit: BoxFit.cover,
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

String _greetingForHour(int hour) {
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 18) {
    return 'Good afternoon';
  }
  return 'Good evening';
}
