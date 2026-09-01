import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/ads/interstitial_manager.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/app_header.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InterstitialManager.instance.showPendingIfReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProfitScaffold(
      currentIndex: 4,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            sliver: SliverList.list(
              children: [
                const Text(
                  'More',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.track_changes_rounded,
                        label: 'Goals & Thresholds',
                        onTap: () => context.go('/goals'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.link_rounded,
                        label: 'Connected Accounts',
                        onTap: () => _showAccounts(context),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.receipt_long_outlined,
                        label: 'Expenses',
                        onTap: () => context.go('/expenses'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Inventory',
                        onTap: () => context.go('/inventory'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.handyman_outlined,
                        label: 'Seller Tools',
                        onTap: () => context.go('/seller-tools'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.upload_file_outlined,
                        label: 'Import sales file',
                        onTap: () => _comingSoon(context, 'CSV import'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.summarize_outlined,
                        label: 'Reports & export',
                        onTap: () => context.go('/reports'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.backup_outlined,
                        label: 'Backup & restore',
                        onTap: () => _comingSoon(context, 'Backup'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => context.go('/settings'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Privacy & biometric lock',
                        onTap: () => context.go('/privacy'),
                      ),
                      const Divider(height: 1, indent: 62),
                      _MenuRow(
                        icon: Icons.info_outline_rounded,
                        label: 'Tax information & rules',
                        onTap: () => _showDisclaimer(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Information in this app is for tracking and general guidance only and is not tax, accounting or legal advice. Rules depend on individual circumstances and can change.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is prepared for the next implementation phase.',
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('General guidance only'),
        content: const Text(
          'ProfitTrack monitors recorded activity. It does not determine tax liability or whether you must register. Review official guidance for your circumstances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAccounts(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _ConnectedAccountsSheet(),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProfitIcon(icon, size: 38),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
      onTap: onTap,
    );
  }
}

class _ConnectedAccountsSheet extends StatelessWidget {
  const _ConnectedAccountsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Accounts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect through each marketplace’s official authorisation flow.',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const _AccountRow(
              name: 'eBay',
              status: 'Connect',
              color: Color(0xFFE53238),
              available: true,
            ),
            const SizedBox(height: 8),
            const _AccountRow(
              name: 'Etsy',
              status: 'Requires approval',
              color: Color(0xFFF1641E),
            ),
            const SizedBox(height: 8),
            const _AccountRow(
              name: 'Vinted',
              status: 'Manual / Import',
              color: AppColors.teal,
            ),
            const SizedBox(height: 8),
            const _AccountRow(
              name: 'Depop',
              status: 'Coming soon',
              color: Color(0xFFFF2B2B),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.status,
    required this.color,
    this.available = false,
  });

  final String name;
  final String status;
  final Color color;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProfitIcon(Icons.storefront_outlined, color: color, size: 42),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  status,
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          if (available)
            OutlinedButton(onPressed: () {}, child: const Text('Connect'))
          else
            const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
        ],
      ),
    );
  }
}
