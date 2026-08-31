import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/features/sales/domain/profit_calculator.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/app_header.dart';
import 'package:profit_track/features/shared/presentation/period_selector.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int period = 2;

  @override
  Widget build(BuildContext context) {
    final allSales = ref.watch(salesControllerProvider).value ?? const <Sale>[];
    final sales = _periodSales(allSales);
    final revenue = ProfitCalculator.revenue(sales);
    final profit = ProfitCalculator.netProfit(sales);
    final previous = _previousMonthSales(allSales);
    final previousProfit = ProfitCalculator.netProfit(previous);
    final previousRevenue = ProfitCalculator.revenue(previous);
    return ProfitScaffold(
      currentIndex: 3,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            sliver: SliverList.list(
              children: [
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                PeriodSelector(
                  labels: const ['Today', 'Week', 'Month', 'Year', 'All Time'],
                  selectedIndex: period,
                  onSelected: (value) => setState(() => period = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InsightKpi(
                        icon: Icons.trending_up_rounded,
                        label: 'Profit',
                        value: Money(profit).format(),
                        change: _change(profit, previousProfit),
                        active: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InsightKpi(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Revenue',
                        value: Money(revenue).format(),
                        change: _change(revenue, previousRevenue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InsightKpi(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Sales',
                        value: '${sales.length}',
                        change: _change(sales.length, previous.length),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ProfitChart(sales: allSales),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 440) {
                      return Column(
                        children: [
                          _MarketplaceRevenue(sales: sales),
                          const SizedBox(height: 10),
                          _TopPerformance(sales: sales),
                          const SizedBox(height: 10),
                          _CategoryProfit(sales: sales),
                          const SizedBox(height: 10),
                          _MonthlySummary(
                            sales: sales,
                            change: _change(profit, previousProfit),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _MarketplaceRevenue(sales: sales)),
                            const SizedBox(width: 10),
                            Expanded(child: _TopPerformance(sales: sales)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _CategoryProfit(sales: sales)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MonthlySummary(
                                sales: sales,
                                change: _change(profit, previousProfit),
                              ),
                            ),
                          ],
                        ),
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
    return sales
        .where(
          (sale) => switch (period) {
            0 =>
              sale.soldAt.year == now.year &&
                  sale.soldAt.month == now.month &&
                  sale.soldAt.day == now.day,
            1 => now.difference(sale.soldAt).inDays < 7,
            2 => sale.soldAt.year == now.year && sale.soldAt.month == now.month,
            3 => sale.soldAt.year == now.year,
            _ => true,
          },
        )
        .toList();
  }

  List<Sale> _previousMonthSales(List<Sale> sales) {
    final previous = DateTime(DateTime.now().year, DateTime.now().month - 1);
    return sales
        .where(
          (sale) =>
              sale.soldAt.year == previous.year &&
              sale.soldAt.month == previous.month,
        )
        .toList();
  }

  String _change(num current, num previous) {
    if (previous == 0) return current == 0 ? '0%' : '+100%';
    final percentage = ((current - previous) / previous.abs() * 100).round();
    return '${percentage >= 0 ? '+' : ''}$percentage%';
  }
}

class _InsightKpi extends StatelessWidget {
  const _InsightKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfitIcon(
                icon,
                size: 36,
                color: active ? AppColors.green : AppColors.deepGreen,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate,
                      ),
                    ),
                    FittedBox(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.green : AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: AppColors.slate),
              children: [
                TextSpan(
                  text: change,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' vs last month'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitChart extends StatelessWidget {
  const _ProfitChart({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthDates = List.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index),
    );
    final values = monthDates.map((month) {
      final monthSales = sales.where(
        (sale) =>
            sale.soldAt.year == month.year && sale.soldAt.month == month.month,
      );
      return monthSales.fold<int>(0, (sum, sale) => sum + sale.netProfitMinor) /
          100;
    }).toList();
    final highest = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final maxY = highest <= 0
        ? 100.0
        : ((highest / 100).ceil() * 100 + 100).toDouble();
    final interval = maxY / 4;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Profit by month',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  children: [
                    Text(
                      '6 months',
                      style: TextStyle(fontSize: 11, color: AppColors.slate),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.slate,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 185,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: 0,
                maxX: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => Text(
                        '£${value.toInt()}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.slate,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat(
                            'MMM',
                          ).format(monthDates[value.toInt().clamp(0, 5)]),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      values.length,
                      (index) => FlSpot(index.toDouble(), values[index]),
                    ),
                    color: AppColors.green,
                    barWidth: 2.5,
                    isCurved: false,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33079447), Color(0x00079447)],
                      ),
                    ),
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

class _MarketplaceRevenue extends StatelessWidget {
  const _MarketplaceRevenue({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final sale in sales) {
      totals.update(
        sale.marketplace,
        (value) => value + sale.sellingPriceMinor,
        ifAbsent: () => sale.sellingPriceMinor,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = entries.take(4).toList();
    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    const colors = [
      AppColors.green,
      Color(0xFF2759C5),
      Color(0xFFFF5630),
      Color(0xFFFFA000),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue by marketplace',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 34,
                        sectionsSpace: 1,
                        startDegreeOffset: -90,
                        sections: visible.isEmpty
                            ? [
                                PieChartSectionData(
                                  value: 1,
                                  color: AppColors.line,
                                  showTitle: false,
                                  radius: 18,
                                ),
                              ]
                            : List.generate(
                                visible.length,
                                (index) => PieChartSectionData(
                                  value: visible[index].value.toDouble(),
                                  color: colors[index],
                                  showTitle: false,
                                  radius: 18,
                                ),
                              ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Money(total).format(decimals: false),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: List.generate(visible.length, (index) {
                    final row = visible[index];
                    final percent = total == 0 ? 0 : row.value / total * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: colors[index],
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              row.key,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          Text(
                            Money(row.value).format(decimals: false),
                            style: const TextStyle(fontSize: 9),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${percent.round()}%',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.slate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const SizedBox(width: 125),
              const Expanded(
                child: Text('Total', style: TextStyle(fontSize: 10)),
              ),
              Text(
                Money(total).format(decimals: false),
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 8),
              const Text(
                '100%',
                style: TextStyle(fontSize: 10, color: AppColors.slate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopPerformance extends StatelessWidget {
  const _TopPerformance({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final marketplaceProfit = <String, int>{};
    final categoryProfit = <String, int>{};
    for (final sale in sales) {
      marketplaceProfit.update(
        sale.marketplace,
        (value) => value + sale.netProfitMinor,
        ifAbsent: () => sale.netProfitMinor,
      );
      categoryProfit.update(
        sale.category,
        (value) => value + sale.netProfitMinor,
        ifAbsent: () => sale.netProfitMinor,
      );
    }
    String best(Map<String, int> values) => values.isEmpty
        ? 'No data'
        : values.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final average = sales.isEmpty
        ? 0
        : ProfitCalculator.netProfit(sales) ~/ sales.length;
    final rows = [
      (
        Icons.emoji_events_outlined,
        'Best marketplace',
        best(marketplaceProfit),
      ),
      (Icons.checkroom_outlined, 'Best category', best(categoryProfit)),
      (
        Icons.currency_pound_rounded,
        'Avg profit per sale',
        Money(average).format(),
      ),
      (Icons.schedule_rounded, 'Avg days to sell', 'Not tracked'),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top performance',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  ProfitIcon(row.$1, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(row.$2, style: const TextStyle(fontSize: 10)),
                  ),
                  Text(
                    row.$3,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.green,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFABB2BC),
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

class _CategoryProfit extends StatelessWidget {
  const _CategoryProfit({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final sale in sales) {
      totals.update(
        sale.category,
        (value) => value + sale.netProfitMinor,
        ifAbsent: () => sale.netProfitMinor,
      );
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = rows.take(4).toList();
    final highest = visible.isEmpty
        ? 1
        : visible.first.value.abs().clamp(1, 1 << 62);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category profit',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No category data yet',
                  style: TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ),
            ),
          ...visible.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 67,
                    child: Text(row.key, style: const TextStyle(fontSize: 10)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (row.value.abs() / highest).clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: AppColors.line,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 35,
                    child: Text(
                      Money(row.value).format(decimals: false),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'View all categories',
                  style: TextStyle(color: AppColors.green, fontSize: 11),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.slate,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.sales, required this.change});

  final List<Sale> sales;
  final String change;

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        Icons.account_balance_wallet_outlined,
        'Revenue',
        Money(ProfitCalculator.revenue(sales)).format(decimals: false),
      ),
      (
        Icons.trending_up_rounded,
        'Profit',
        Money(ProfitCalculator.netProfit(sales)).format(decimals: false),
      ),
      (Icons.shopping_bag_outlined, 'Sales', '${sales.length}'),
      (Icons.trending_up_rounded, 'vs last month', change),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly summary',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.65,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: values.map((item) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    ProfitIcon(item.$1, size: 34),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 9,
                            ),
                          ),
                          FittedBox(
                            child: Text(
                              item.$3,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: item.$3.startsWith('+')
                                    ? AppColors.green
                                    : AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
