import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/app_header.dart';
import 'package:profit_track/features/shared/presentation/period_selector.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:profit_track/features/goals/presentation/live_goals_panel.dart';

class GoalsThresholdsScreen extends StatefulWidget {
  const GoalsThresholdsScreen({super.key});

  @override
  State<GoalsThresholdsScreen> createState() => _GoalsThresholdsScreenState();
}

class _GoalsThresholdsScreenState extends State<GoalsThresholdsScreen> {
  int section = 0;

  @override
  Widget build(BuildContext context) {
    return ProfitScaffold(
      currentIndex: 4,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader(compact: true)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/more'),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Goals & Thresholds',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
                const SizedBox(height: 10),
                PeriodSelector(
                  labels: const ['Goals', 'Thresholds'],
                  selectedIndex: section,
                  onSelected: (value) => setState(() => section = value),
                ),
                const SizedBox(height: 12),
                if (section == 0)
                  const LiveGoalsPanel()
                else
                  const _ThresholdOverview(),
                const SizedBox(height: 13),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Important thresholds',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.green,
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Verified 31 Aug 2026',
                      style: TextStyle(color: AppColors.slate, fontSize: 11),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.slate,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const _ThresholdCard(kind: _ThresholdKind.uk),
                const SizedBox(height: 8),
                const _ThresholdCard(kind: _ThresholdKind.marketplace),
                const SizedBox(height: 8),
                const _ThresholdCard(kind: _ThresholdKind.vat),
                const SizedBox(height: 12),
                const _NotificationMilestones(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUGUST PROFIT GOAL',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          '£742',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 41,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 7, left: 5),
                          child: Text(
                            'of £1,000',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: .74,
                      strokeWidth: 7,
                      backgroundColor: AppColors.line,
                      color: AppColors.green,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '74%',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _GoalStat(
                  icon: Icons.calendar_today_outlined,
                  text: '9 days remaining',
                ),
              ),
              SizedBox(height: 34, child: VerticalDivider()),
              Expanded(
                child: _GoalStat(
                  icon: Icons.track_changes_rounded,
                  text: '£28.67/day needed',
                ),
              ),
              SizedBox(height: 34, child: VerticalDivider()),
              Expanded(
                child: _GoalStat(
                  icon: Icons.trending_up_rounded,
                  text: 'You’re £114\nahead of pace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _GoalTimeline(),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.green, size: 22),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalTimeline extends StatelessWidget {
  const _GoalTimeline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Stack(
        children: [
          Positioned(
            left: 6,
            right: 6,
            top: 12,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 105,
            top: 12,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelinePoint(complete: true, label: '25%', sublabel: '£250'),
              _TimelinePoint(complete: true, label: '50%', sublabel: '£500'),
              _TimelinePoint(
                active: true,
                label: '75%',
                sublabel: 'Nearly there!',
              ),
              _TimelinePoint(label: '100%', sublabel: '£1,000'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelinePoint extends StatelessWidget {
  const _TimelinePoint({
    required this.label,
    required this.sublabel,
    this.complete = false,
    this.active = false,
  });

  final String label;
  final String sublabel;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: complete ? AppColors.green : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: complete || active
                    ? AppColors.green
                    : const Color(0xFFAFB6BF),
                width: 2,
              ),
            ),
            child: complete
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.green : AppColors.navy,
            ),
          ),
          Text(
            sublabel,
            maxLines: 1,
            style: const TextStyle(fontSize: 9, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _ThresholdOverview extends StatelessWidget {
  const _ThresholdOverview();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const ProfitIcon(Icons.shield_outlined, size: 52),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Threshold monitoring',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'Three relevant UK rules are being tracked from your recorded activity.',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '1 approaching',
              style: TextStyle(color: Color(0xFFE47D00), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ThresholdKind { uk, marketplace, vat }

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({required this.kind});

  final _ThresholdKind kind;

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      _ThresholdKind.uk => 'UK Trading Allowance',
      _ThresholdKind.marketplace => 'Vinted Marketplace Reporting',
      _ThresholdKind.vat => 'VAT Registration',
    };
    final primary = switch (kind) {
      _ThresholdKind.uk => '£742',
      _ThresholdKind.marketplace => '23',
      _ThresholdKind.vat => '£18,420',
    };
    final secondary = switch (kind) {
      _ThresholdKind.uk => ' / £1,000 gross trading income',
      _ThresholdKind.marketplace =>
        ' / 30 sales\n£1,280 / approx £1,700 proceeds',
      _ThresholdKind.vat => ' / £90,000 rolling 12 months',
    };
    final percent = switch (kind) {
      _ThresholdKind.uk => '74%',
      _ThresholdKind.marketplace => '77%',
      _ThresholdKind.vat => '20%',
    };
    final progress = switch (kind) {
      _ThresholdKind.uk => .74,
      _ThresholdKind.marketplace => .77,
      _ThresholdKind.vat => .20,
    };
    final color = switch (kind) {
      _ThresholdKind.uk => AppColors.orange,
      _ThresholdKind.marketplace => AppColors.teal,
      _ThresholdKind.vat => AppColors.purple,
    };
    final icon = switch (kind) {
      _ThresholdKind.uk => null,
      _ThresholdKind.marketplace => Icons.sell_outlined,
      _ThresholdKind.vat => Icons.description_outlined,
    };
    final detail = switch (kind) {
      _ThresholdKind.uk => 'Informational only - not tax advice',
      _ThresholdKind.marketplace => 'Marketplace reporting tracker',
      _ThresholdKind.vat => 'Based on rolling 12 months of taxable turnover',
    };
    return AppCard(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 9),
      child: Column(
        children: [
          Row(
            children: [
              kind == _ThresholdKind.uk
                  ? const Text('🇬🇧', style: TextStyle(fontSize: 32))
                  : ProfitIcon(icon!, color: color, size: 42),
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
                    const SizedBox(height: 3),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: primary,
                            style: TextStyle(
                              color: kind == _ThresholdKind.marketplace
                                  ? AppColors.teal
                                  : AppColors.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(text: secondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: AppColors.line,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Text(
                percent,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (kind == _ThresholdKind.uk) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EB),
                    border: Border.all(color: const Color(0xFFFFCC77)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Approaching',
                    style: TextStyle(color: Color(0xFFE47D00), fontSize: 10),
                  ),
                ),
              ],
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFABB2BC)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.slate,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 9, color: AppColors.slate),
                ),
              ),
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AppColors.green,
              ),
              const SizedBox(width: 4),
              const Text(
                'Verified 31 Aug 2026',
                style: TextStyle(fontSize: 9, color: AppColors.slate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationMilestones extends StatelessWidget {
  const _NotificationMilestones();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Notification milestones',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.slate,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                _MilestoneRow(
                  icon: Icons.trending_up_rounded,
                  title: 'Profit Goal\nMilestones',
                  values: [
                    '50%\n£500',
                    '75%\n£750',
                    '90%\n£900',
                    '100%\n£1,000',
                  ],
                ),
                Divider(height: 1),
                _MilestoneRow(
                  icon: Icons.sell_outlined,
                  title: 'Marketplace Reporting\nSales Milestones',
                  values: ['20 sales', '25 sales', '29 sales', '30 sales'],
                  teal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.icon,
    required this.title,
    required this.values,
    this.teal = false,
  });

  final IconData icon;
  final String title;
  final List<String> values;
  final bool teal;

  @override
  Widget build(BuildContext context) {
    final color = teal ? AppColors.teal : AppColors.green;
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Row(
        children: [
          ProfitIcon(icon, color: color, size: 34),
          const SizedBox(width: 7),
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          ...List.generate(
            values.length,
            (index) => Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? color.withValues(alpha: .1)
                          : index == 1
                          ? Colors.white
                          : const Color(0xFFF2F3F5),
                      border: index == 1
                          ? Border.all(color: color.withValues(alpha: .35))
                          : null,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      values[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: index < 2 ? color : AppColors.slate,
                        fontWeight: index < 2
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    index == 0
                        ? Icons.check_circle_outline_rounded
                        : Icons.notifications_none_rounded,
                    size: 14,
                    color: index == 0 ? color : AppColors.slate,
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
