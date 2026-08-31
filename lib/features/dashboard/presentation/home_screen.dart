import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/expenses/application/expenses_controller.dart';
import 'package:profit_track/features/goals/application/goals_controller.dart';
import 'package:profit_track/features/goals/domain/earnings_goal.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/features/sales/domain/profit_calculator.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/app_header.dart';
import 'package:profit_track/features/shared/presentation/period_selector.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int period = 2;

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesControllerProvider).value ?? const <Sale>[];
    final expenses = ref.watch(expensesControllerProvider).value ?? const [];
    final currentSales = _periodSales(sales);
    final revenue = ProfitCalculator.revenue(currentSales);
    final expenseTotal = expenses
        .where((expense) => _dateInPeriod(expense.spentAt))
        .fold<int>(0, (sum, expense) => sum + expense.amountMinor);
    final profit = ProfitCalculator.netProfit(currentSales) - expenseTotal;
    final margin = revenue == 0 ? 0.0 : profit / revenue * 100;
    final averageProfit = currentSales.isEmpty
        ? 0
        : profit ~/ currentSales.length;
    final now = DateTime.now();
    final yearSales = sales
        .where((sale) => sale.soldAt.year == now.year)
        .toList();
    final yearRevenue = ProfitCalculator.revenue(yearSales);
    final rollingStart = DateTime(now.year - 1, now.month, now.day);
    final rollingRevenue = ProfitCalculator.revenue(
      sales.where((sale) => !sale.soldAt.isBefore(rollingStart)).toList(),
    );
    final vintedSales = yearSales
        .where((sale) => sale.marketplace.toLowerCase() == 'vinted')
        .toList();
    final vintedRevenue = ProfitCalculator.revenue(vintedSales);
    final goalTarget = _monthlyProfitGoal();

    return ProfitScaffold(
      currentIndex: 0,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            sliver: SliverList.list(
              children: [
                PeriodSelector(
                  labels: const ['Today', 'Week', 'Month', 'Year', 'All Time'],
                  selectedIndex: period,
                  onSelected: (value) => setState(() => period = value),
                ),
                const SizedBox(height: 12),
                _ProfitHero(profitMinor: profit, targetMinor: goalTarget),
                const SizedBox(height: 12),
                _KpiGrid(
                  revenueMinor: revenue,
                  sales: currentSales.length,
                  averageProfitMinor: averageProfit,
                  margin: margin,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Important trackers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _TrackerCard(
                  icon: '🇬🇧',
                  title: 'UK Trading Allowance',
                  value:
                      '${Money(yearRevenue).format(decimals: false)} / £1,000',
                  progress: (yearRevenue / 100000).clamp(0, 1),
                  progressColor: AppColors.orange,
                  badge: yearRevenue >= 75000 ? 'Approaching' : null,
                ),
                const SizedBox(height: 8),
                _TrackerCard(
                  leadingIcon: Icons.sell_outlined,
                  iconColor: AppColors.teal,
                  title: 'Vinted Marketplace Reporting',
                  value:
                      '${vintedSales.length} / 30 sales\n${Money(vintedRevenue).format(decimals: false)} proceeds',
                  progress: (vintedSales.length / 30).clamp(0, 1),
                  progressColor: AppColors.teal,
                ),
                const SizedBox(height: 8),
                _TrackerCard(
                  leadingIcon: Icons.description_outlined,
                  iconColor: AppColors.purple,
                  title: 'VAT Registration',
                  value:
                      '${Money(rollingRevenue).format(decimals: false)} / £90,000 rolling 12 months',
                  progress: (rollingRevenue / 9000000).clamp(0, 1),
                  progressColor: AppColors.purple,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final forecast = _ForecastCard(profitMinor: profit);
                    final recent = _RecentSalesCard(sales: sales);
                    if (constraints.maxWidth < 430) {
                      return Column(
                        children: [
                          forecast,
                          const SizedBox(height: 10),
                          recent,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: forecast),
                        const SizedBox(width: 10),
                        Expanded(flex: 5, child: recent),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Sale> _periodSales(List<Sale> sales) {
    final now = DateTime.now();
    return sales.where((sale) {
      return switch (period) {
        0 =>
          sale.soldAt.year == now.year &&
              sale.soldAt.month == now.month &&
              sale.soldAt.day == now.day,
        1 => now.difference(sale.soldAt).inDays < 7,
        2 => sale.soldAt.year == now.year && sale.soldAt.month == now.month,
        3 => sale.soldAt.year == now.year,
        _ => true,
      };
    }).toList();
  }

  bool _dateInPeriod(DateTime date) {
    final now = DateTime.now();
    return switch (period) {
      0 =>
        date.year == now.year && date.month == now.month && date.day == now.day,
      1 => now.difference(date).inDays < 7,
      2 => date.year == now.year && date.month == now.month,
      3 => date.year == now.year,
      _ => true,
    };
  }

  int _monthlyProfitGoal() {
    final goals = ref.watch(goalsControllerProvider).value ?? const [];
    for (final goal in goals) {
      if (goal.active &&
          goal.measure == GoalMeasure.profit &&
          goal.period == GoalPeriod.monthly) {
        return goal.target;
      }
    }
    return 100000;
  }
}

class _ProfitHero extends StatelessWidget {
  const _ProfitHero({required this.profitMinor, required this.targetMinor});

  final int profitMinor;
  final int targetMinor;

  @override
  Widget build(BuildContext context) {
    final progress = targetMinor <= 0
        ? 0.0
        : (profitMinor / targetMinor).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THIS MONTH',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Net Profit',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Money(profitMinor).format(),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 39,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.green,
                          size: 21,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '+18%',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'vs last month',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const ProfitIcon(Icons.trending_up_rounded, size: 48),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.line,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${Money(profitMinor).format(decimals: false)} / ${Money(targetMinor).format(decimals: false)} monthly goal',
                style: const TextStyle(fontSize: 13, color: AppColors.slate),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.green,
                size: 21,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  '9 days remaining',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 30, child: VerticalDivider()),
              SizedBox(width: 10),
              Icon(
                Icons.track_changes_rounded,
                color: AppColors.green,
                size: 23,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'You need £28.67/day\nto hit your goal',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.revenueMinor,
    required this.sales,
    required this.averageProfitMinor,
    required this.margin,
  });

  final int revenueMinor;
  final int sales;
  final int averageProfitMinor;
  final double margin;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        label: 'Revenue',
        value: Money(revenueMinor).format(decimals: false),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _KpiCard(
        label: 'Sales',
        value: '$sales',
        icon: Icons.shopping_bag_outlined,
      ),
      _KpiCard(
        label: 'Avg Profit',
        value: Money(averageProfitMinor).format(),
        icon: Icons.currency_pound_rounded,
      ),
      _KpiCard(
        label: 'Avg Margin',
        value: '${margin.round()}%',
        icon: Icons.percent_rounded,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.25,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: cards,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ProfitIcon(icon, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFABB2BC)),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    this.icon,
    this.leadingIcon,
    this.iconColor = AppColors.green,
    required this.title,
    required this.value,
    required this.progress,
    required this.progressColor,
    this.badge,
  });

  final String? icon;
  final IconData? leadingIcon;
  final Color iconColor;
  final String title;
  final String value;
  final double progress;
  final Color progressColor;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          icon != null
              ? Text(icon!, style: const TextStyle(fontSize: 29))
              : ProfitIcon(leadingIcon!, color: iconColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.line,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EB),
                border: Border.all(color: const Color(0xFFFFCC77)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: const TextStyle(color: Color(0xFFE47D00), fontSize: 11),
              ),
            ),
          ],
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFABB2BC)),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.profitMinor});

  final int profitMinor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'This month forecast',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.slate),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const ProfitIcon(Icons.trending_up_rounded, size: 42),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'At your current pace:',
                    style: TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    Money(
                      (profitMinor * 1.474).round(),
                    ).format(decimals: false),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentSalesCard extends StatelessWidget {
  const _RecentSalesCard({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final visible = sales.take(3).toList();
    final fallback = [
      Sale(
        id: 'a',
        title: 'Nike Hoodie',
        marketplace: 'Vinted',
        soldAt: DateTime.now(),
        sellingPriceMinor: 5500,
        purchaseCostMinor: 3500,
      ),
      Sale(
        id: 'b',
        title: 'Carhartt Tee',
        marketplace: 'eBay',
        soldAt: DateTime.now(),
        sellingPriceMinor: 2800,
        purchaseCostMinor: 1850,
      ),
      Sale(
        id: 'c',
        title: 'Vintage Jacket',
        marketplace: 'Vinted',
        soldAt: DateTime.now(),
        sellingPriceMinor: 7800,
        purchaseCostMinor: 5000,
      ),
    ];
    final rows = visible.length == 3 ? visible : fallback;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent sales',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/sales'),
                child: const Text('View all'),
              ),
            ],
          ),
          ...rows.map(
            (sale) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.paleGreen,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.checkroom_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sale.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Money(sale.sellingPriceMinor).format(),
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        Money(sale.netProfitMinor).format(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
