import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/seller_tools/application/seller_tools_controller.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';

class SellerToolsScreen extends ConsumerWidget {
  const SellerToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(affiliateOffersProvider);
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
                        'Seller Tools',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const AppCard(
                  child: Row(
                    children: [
                      ProfitIcon(Icons.handyman_outlined, size: 52),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Useful tools for resellers',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Partnership offers will only appear here when they are relevant, verified and available in your country.',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const _CategoryGrid(),
                const SizedBox(height: 14),
                offers.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const _NoOffers(),
                  data: (items) => items.isEmpty
                      ? const _NoOffers()
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Any compensated placement will be clearly labelled. Takings may earn a commission if you sign up through an eligible link. Sponsored content is separate from financial calculations and tax guidance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    const categories = [
      (Icons.local_shipping_outlined, 'Shipping'),
      (Icons.inventory_2_outlined, 'Packaging'),
      (Icons.calculate_outlined, 'Bookkeeping'),
      (Icons.photo_camera_outlined, 'Photography'),
      (Icons.auto_fix_high_outlined, 'Photo tools'),
      (Icons.storefront_outlined, 'Marketplace tools'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: categories
          .map(
            (item) => AppCard(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ProfitIcon(item.$1, size: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NoOffers extends StatelessWidget {
  const _NoOffers();

  @override
  Widget build(BuildContext context) => const AppCard(
    child: Column(
      children: [
        Icon(Icons.verified_outlined, color: AppColors.green, size: 34),
        SizedBox(height: 8),
        Text(
          'No active partner offers',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'We will not display placeholder deals or unverified recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate, fontSize: 11),
        ),
      ],
    ),
  );
}
