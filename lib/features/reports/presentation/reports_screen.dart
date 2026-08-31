import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/expenses/application/expenses_controller.dart';
import 'package:profit_track/features/expenses/domain/expense.dart';
import 'package:profit_track/features/inventory/application/inventory_controller.dart';
import 'package:profit_track/features/inventory/domain/inventory_item.dart';
import 'package:profit_track/features/reports/application/csv_export_service.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Sale> sales = ref
        .watch(salesControllerProvider)
        .when(
          data: (value) => value,
          loading: () => const <Sale>[],
          error: (error, stack) => const <Sale>[],
        );
    final List<Expense> expenses = ref
        .watch(expensesControllerProvider)
        .when(
          data: (value) => value,
          loading: () => const <Expense>[],
          error: (error, stack) => const <Expense>[],
        );
    final List<InventoryItem> inventory = ref
        .watch(inventoryControllerProvider)
        .when(
          data: (value) => value,
          loading: () => const <InventoryItem>[],
          error: (error, stack) => const <InventoryItem>[],
        );
    final revenue = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.sellingPriceMinor,
    );
    final saleProfit = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.netProfitMinor,
    );
    final expenseTotal = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountMinor,
    );
    final stockValue = inventory
        .where((item) => item.status != InventoryStatus.sold)
        .fold<int>(0, (sum, item) => sum + item.purchaseCostMinor);
    final exporter = CsvExportService();
    return ProfitScaffold(
      currentIndex: 4,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => context.go('/more'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Reports & export',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'All-time summary',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Kpi(
                      label: 'Revenue',
                      value: Money(revenue).format(),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _Kpi(
                      label: 'Net profit',
                      value: Money(saleProfit - expenseTotal).format(),
                      icon: Icons.trending_up_rounded,
                    ),
                    _Kpi(
                      label: 'Expenses',
                      value: Money(expenseTotal).format(),
                      icon: Icons.receipt_long_outlined,
                    ),
                    _Kpi(
                      label: 'Stock invested',
                      value: Money(stockValue).format(),
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create local CSV',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ExportRow(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Sales CSV',
                        subtitle: '${sales.length} sales',
                        onTap: sales.isEmpty
                            ? null
                            : () => _export(
                                context,
                                () => exporter.exportSales(sales),
                              ),
                      ),
                      const Divider(height: 1, indent: 62),
                      _ExportRow(
                        icon: Icons.receipt_long_outlined,
                        title: 'Expenses CSV',
                        subtitle: '${expenses.length} expenses',
                        onTap: expenses.isEmpty
                            ? null
                            : () => _export(
                                context,
                                () => exporter.exportExpenses(expenses),
                              ),
                      ),
                      const Divider(height: 1, indent: 62),
                      _ExportRow(
                        icon: Icons.inventory_2_outlined,
                        title: 'Inventory CSV',
                        subtitle: '${inventory.length} items',
                        onTap: inventory.isEmpty
                            ? null
                            : () => _export(
                                context,
                                () => exporter.exportInventory(inventory),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'CSV files are created in ProfitTrack private app storage and are not uploaded.',
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

  Future<void> _export(
    BuildContext context,
    Future<File> Function() action,
  ) async {
    try {
      final file = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${file.uri.pathSegments.last} locally.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
      }
    }
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        ProfitIcon(icon, size: 40),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.slate, fontSize: 11),
              ),
              FittedBox(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExportRow extends StatelessWidget {
  const _ExportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: ProfitIcon(icon, size: 40),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: Icon(
      Icons.download_outlined,
      color: onTap == null ? AppColors.line : AppColors.green,
    ),
    enabled: onTap != null,
    onTap: onTap,
  );
}
