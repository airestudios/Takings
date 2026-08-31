import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';

class ProfitScaffold extends StatelessWidget {
  const ProfitScaffold({
    required this.body,
    required this.currentIndex,
    super.key,
    this.showBottomNavigation = true,
  });

  final Widget body;
  final int currentIndex;
  final bool showBottomNavigation;

  void _navigate(BuildContext context, int index) {
    const paths = ['/', '/sales', '/add-sale', '/insights', '/more'];
    context.go(paths[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: showBottomNavigation
          ? _BottomNavigation(
              currentIndex: currentIndex,
              onSelected: (index) => _navigate(context, index),
            )
          : null,
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1808142C),
              blurRadius: 16,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onSelected(0),
            ),
            _NavItem(
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag,
              label: 'Sales',
              selected: currentIndex == 1,
              onTap: () => onSelected(1),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Semantics(
                  button: true,
                  label: 'Add sale',
                  child: InkWell(
                    onTap: () => onSelected(2),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40079447),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              selectedIcon: Icons.bar_chart_rounded,
              label: 'Insights',
              selected: currentIndex == 3,
              onTap: () => onSelected(3),
            ),
            _NavItem(
              icon: Icons.menu_rounded,
              selectedIcon: Icons.menu_rounded,
              label: 'More',
              selected: currentIndex == 4,
              onTap: () => onSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.slate;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
              const SizedBox(height: 2),
              CircleAvatar(
                radius: 2.2,
                backgroundColor: selected
                    ? AppColors.green
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
