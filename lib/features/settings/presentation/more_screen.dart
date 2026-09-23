import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/ads/interstitial_manager.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/app_header.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:profit_track/marketplace_integrations/ebay/ebay_connection_controller.dart';
import 'package:profit_track/marketplace_integrations/etsy/etsy_connection_controller.dart';

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
                        onTap: () => context.go('/import-sales'),
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
                        onTap: () => context.go('/backup-restore'),
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

class _ConnectedAccountsSheet extends ConsumerWidget {
  const _ConnectedAccountsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ebayValue = ref.watch(ebayConnectionControllerProvider);
    final ebay = ebayValue.value;
    final ebayStatus = ebayValue.isLoading
        ? 'Checking connection…'
        : ebay?.busy == true
        ? ebay!.connected
              ? 'Syncing eBay sales…'
              : 'Opening eBay sign-in…'
        : ebay?.connected == true
        ? 'Connected · tap to sync'
        : 'Connect and import sales';
    final etsyValue = ref.watch(etsyConnectionControllerProvider);
    final etsy = etsyValue.value;
    final etsyStatus = etsyValue.isLoading
        ? 'Checking connection…'
        : etsy?.busy == true
        ? etsy!.connected
              ? 'Syncing Etsy sales…'
              : 'Opening Etsy sign-in…'
        : etsy?.connected == true
        ? etsy!.shopName == null
              ? 'Connected · tap to sync'
              : 'Connected to ${etsy.shopName} · tap to sync'
        : 'Connect and import sales';
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
            _AccountRow(
              name: 'eBay',
              status: ebayStatus,
              color: const Color(0xFFE53238),
              onTap: ebayValue.isLoading || ebay?.busy == true
                  ? null
                  : () => _connectOrSyncEbay(
                      context,
                      ref,
                      ebay?.connected == true,
                    ),
              trailing: ebay?.busy == true || ebayValue.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ebay?.connected == true
                  ? PopupMenuButton<String>(
                      tooltip: 'eBay account options',
                      onSelected: (action) {
                        if (action == 'sync') {
                          _connectOrSyncEbay(context, ref, true);
                        } else if (action == 'disconnect') {
                          _disconnectEbay(context, ref);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'sync', child: Text('Sync now')),
                        PopupMenuItem(
                          value: 'disconnect',
                          child: Text('Disconnect'),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            _AccountRow(
              name: 'Etsy',
              status: etsyStatus,
              color: const Color(0xFFF1641E),
              onTap: etsyValue.isLoading || etsy?.busy == true
                  ? null
                  : () => _connectOrSync(context, ref, etsy?.connected == true),
              trailing: etsy?.busy == true || etsyValue.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : etsy?.connected == true
                  ? PopupMenuButton<String>(
                      tooltip: 'Etsy account options',
                      onSelected: (action) {
                        if (action == 'sync') {
                          _connectOrSync(context, ref, true);
                        } else if (action == 'disconnect') {
                          _disconnect(context, ref);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'sync', child: Text('Sync now')),
                        PopupMenuItem(
                          value: 'disconnect',
                          child: Text('Disconnect'),
                        ),
                      ],
                    )
                  : null,
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

  Future<void> _connectOrSyncEbay(
    BuildContext context,
    WidgetRef ref,
    bool connected,
  ) async {
    try {
      if (connected) {
        final result = await ref
            .read(ebayConnectionControllerProvider.notifier)
            .sync();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.imported == 0
                  ? 'eBay is up to date.'
                  : '${result.imported} eBay sale${result.imported == 1 ? '' : 's'} imported. Add purchase costs and fees for accurate profit.',
            ),
          ),
        );
      } else {
        await ref.read(ebayConnectionControllerProvider.notifier).connect();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('eBay connected. Tap again to import sales.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _disconnectEbay(BuildContext context, WidgetRef ref) async {
    await ref.read(ebayConnectionControllerProvider.notifier).disconnect();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('eBay disconnected. Imported sales were kept.'),
      ),
    );
  }

  Future<void> _connectOrSync(
    BuildContext context,
    WidgetRef ref,
    bool connected,
  ) async {
    try {
      if (connected) {
        final result = await ref
            .read(etsyConnectionControllerProvider.notifier)
            .sync();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.imported == 0
                  ? 'Etsy is up to date.'
                  : '${result.imported} Etsy sale${result.imported == 1 ? '' : 's'} imported.',
            ),
          ),
        );
      } else {
        final account = await ref
            .read(etsyConnectionControllerProvider.notifier)
            .connect();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${account.shopName ?? 'Etsy'} connected.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await ref.read(etsyConnectionControllerProvider.notifier).disconnect();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Etsy disconnected. Imported sales were kept.'),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.status,
    required this.color,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String status;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
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
          trailing ??
              const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }
}
