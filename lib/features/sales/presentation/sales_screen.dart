import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/ads/ad_banner.dart';
import 'package:profit_track/ads/ad_service.dart';
import 'package:profit_track/ads/native_ad_card.dart';
import 'package:intl/intl.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/app_header.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  String query = '';
  String marketplace = 'All marketplaces';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesControllerProvider);
    return ProfitScaffold(
      currentIndex: 1,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ErrorState(
                onRetry: () =>
                    ref.read(salesControllerProvider.notifier).load(),
              ),
              data: (sales) {
                final filtered = sales.where((sale) {
                  final matchesQuery = sale.title.toLowerCase().contains(
                    query.toLowerCase(),
                  );
                  final matchesMarketplace =
                      marketplace == 'All marketplaces' ||
                      sale.marketplace == marketplace;
                  return matchesQuery && matchesMarketplace;
                }).toList();
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      sliver: SliverList.list(
                        children: [
                          const Text(
                            'Sales',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            onChanged: (value) => setState(() => query = value),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Search sales',
                              suffixIcon: Icon(Icons.tune_rounded),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: marketplace,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.sell_outlined,
                                color: AppColors.green,
                              ),
                            ),
                            items:
                                const [
                                      'All marketplaces',
                                      'Vinted',
                                      'eBay',
                                      'Depop',
                                      'Etsy',
                                      'Other',
                                    ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) => setState(
                              () => marketplace = value ?? marketplace,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${filtered.length} completed sales',
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (filtered.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptySales(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        sliver: SliverList.separated(
                          itemCount:
                              filtered.length + (filtered.length >= 6 ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (filtered.length >= 6 && index == 6) {
                              return const NativeAdCard(
                                placement: AdPlacements.salesNative,
                              );
                            }
                            final saleIndex = filtered.length >= 6 && index > 6
                                ? index - 1
                                : index;
                            return _SaleRow(
                              sale: filtered[saleIndex],
                              onEdit: () => context.push(
                                '/edit-sale',
                                extra: filtered[saleIndex],
                              ),
                              onDelete: () =>
                                  _confirmDelete(filtered[saleIndex]),
                            );
                          },
                        ),
                      ),
                    if (filtered.isNotEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 20),
                        sliver: SliverToBoxAdapter(
                          child: ProfitTrackAdBanner(
                            placement: AdPlacements.salesBanner,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sale?'),
        content: Text(
          '${sale.title} will be removed from local totals and reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(salesControllerProvider.notifier).remove(sale.id);
    }
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.sale,
    required this.onEdit,
    required this.onDelete,
  });

  final Sale sale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imported = sale.importSource != ImportSource.manual;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProfitIcon(
            Icons.checkroom_outlined,
            size: 42,
            color: sale.marketplace == 'Vinted'
                ? AppColors.teal
                : AppColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sale.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (imported)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sale.importSource.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${sale.marketplace}  •  ${DateFormat('d MMM yyyy').format(sale.soldAt)}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money(sale.sellingPriceMinor).format(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                Money(sale.netProfitMinor).format(),
                style: TextStyle(
                  color: sale.netProfitMinor >= 0
                      ? AppColors.green
                      : Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.slate),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySales extends StatelessWidget {
  const _EmptySales();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfitIcon(Icons.shopping_bag_outlined, size: 64),
          SizedBox(height: 12),
          Text(
            'No sales found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing your search or filters.',
            style: TextStyle(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Local sales could not be loaded.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
