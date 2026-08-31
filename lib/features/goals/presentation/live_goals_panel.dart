import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/expenses/application/expenses_controller.dart';
import 'package:profit_track/features/expenses/domain/expense.dart';
import 'package:profit_track/features/goals/application/goals_controller.dart';
import 'package:profit_track/features/goals/domain/earnings_goal.dart';
import 'package:profit_track/features/goals/domain/goal_calculator.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:uuid/uuid.dart';

class LiveGoalsPanel extends ConsumerStatefulWidget {
  const LiveGoalsPanel({super.key});

  @override
  ConsumerState<LiveGoalsPanel> createState() => _LiveGoalsPanelState();
}

class _LiveGoalsPanelState extends ConsumerState<LiveGoalsPanel> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(goalsControllerProvider)
        .when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => AppCard(child: Text('$error')),
          data: (goals) {
            if (goals.isEmpty) {
              return AppCard(
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create your first goal'),
                  ),
                ),
              );
            }
            final goal = goals.firstWhere(
              (item) => item.id == selectedId,
              orElse: () => goals.first,
            );
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: goals
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ChoiceChip(
                                    label: Text(item.name),
                                    selected: item.id == goal.id,
                                    onSelected: (_) =>
                                        setState(() => selectedId = item.id),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add goal',
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _LiveGoalCard(goal: goal, onEdit: () => _openEditor(goal)),
              ],
            );
          },
        );
  }

  Future<void> _openEditor([EarningsGoal? goal]) async {
    final saved = await showModalBottomSheet<EarningsGoal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GoalEditor(goal: goal),
    );
    if (saved != null) {
      await ref.read(goalsControllerProvider.notifier).save(saved);
      setState(() => selectedId = saved.id);
    }
  }
}

class _LiveGoalCard extends ConsumerWidget {
  const _LiveGoalCard({required this.goal, required this.onEdit});

  final EarningsGoal goal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final start = goal.periodStart(now);
    final end = goal.periodEnd(now);
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
    final periodSales = sales.where(
      (sale) => !sale.soldAt.isBefore(start) && !sale.soldAt.isAfter(end),
    );
    final current = switch (goal.measure) {
      GoalMeasure.revenue => periodSales.fold<int>(
        0,
        (sum, sale) => sum + sale.sellingPriceMinor,
      ),
      GoalMeasure.sales => periodSales.length,
      GoalMeasure.profit =>
        periodSales.fold<int>(0, (sum, sale) => sum + sale.netProfitMinor) -
            expenses
                .where(
                  (expense) =>
                      !expense.spentAt.isBefore(start) &&
                      !expense.spentAt.isAfter(end),
                )
                .fold<int>(0, (sum, expense) => sum + expense.amountMinor),
    };
    final progress = GoalCalculator.calculate(
      current: current,
      target: goal.target,
      periodStart: start,
      periodEnd: end,
      now: now,
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_heading(goal, now)} ${goal.measure.name.toUpperCase()} GOAL',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          _value(goal, progress.current),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 41,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7, left: 5),
                          child: Text(
                            'of ${_value(goal, progress.target)}',
                            style: const TextStyle(
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
                      value: (progress.percentage / 100).clamp(0, 1),
                      strokeWidth: 7,
                      backgroundColor: AppColors.line,
                      color: AppColors.green,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${progress.percentage.round()}%',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.slate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.calendar_today_outlined,
                  text: '${progress.remainingDays} days remaining',
                ),
              ),
              const SizedBox(height: 34, child: VerticalDivider()),
              Expanded(
                child: _Stat(
                  icon: Icons.track_changes_rounded,
                  text:
                      '${_value(goal, progress.requiredPerRemainingDay.round())}/day needed',
                ),
              ),
              const SizedBox(height: 34, child: VerticalDivider()),
              Expanded(
                child: _Stat(
                  icon: Icons.trending_up_rounded,
                  text:
                      '${_value(goal, progress.aheadBehind.abs().round())}\n${progress.aheadBehind >= 0 ? 'ahead' : 'behind'} of pace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Timeline(goal: goal, progress: progress),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.goal, required this.progress});

  final EarningsGoal goal;
  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    const milestones = [25, 50, 75, 100];
    return SizedBox(
      height: 65,
      child: Stack(
        children: [
          Positioned(
            left: 6,
            right: 6,
            top: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (progress.percentage / 100).clamp(0, 1),
                minHeight: 4,
                backgroundColor: AppColors.line,
                color: AppColors.green,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones.map((milestone) {
              final complete = progress.percentage >= milestone;
              final next =
                  !complete &&
                  progress.percentage < milestone &&
                  progress.percentage >= milestone - 25;
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
                          color: complete || next
                              ? AppColors.green
                              : const Color(0xFFAFB6BF),
                          width: 2,
                        ),
                      ),
                      child: complete
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$milestone%',
                      style: TextStyle(
                        fontSize: 11,
                        color: next ? AppColors.green : AppColors.navy,
                      ),
                    ),
                    Text(
                      _value(goal, (goal.target * milestone / 100).round()),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.slate,
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

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({this.goal});

  final EarningsGoal? goal;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController target;
  late GoalMeasure measure;
  late GoalPeriod period;
  late bool active;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    name = TextEditingController(text: goal?.name ?? 'Monthly profit');
    measure = goal?.measure ?? GoalMeasure.profit;
    period = goal?.period ?? GoalPeriod.monthly;
    active = goal?.active ?? true;
    target = TextEditingController(
      text: goal == null
          ? '1000'
          : measure == GoalMeasure.sales
          ? goal.target.toString()
          : (goal.target / 100).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal == null ? 'Add goal' : 'Edit goal',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Goal name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<GoalMeasure>(
              value: measure,
              decoration: const InputDecoration(labelText: 'Measure'),
              items: GoalMeasure.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_title(value.name)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => measure = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<GoalPeriod>(
              value: period,
              decoration: const InputDecoration(labelText: 'Period'),
              items: GoalPeriod.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_title(value.name)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => period = value!),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target',
                prefixText: measure == GoalMeasure.sales ? null : '£ ',
              ),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Enter a target greater than zero'
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active goal'),
              value: active,
              onChanged: (value) => setState(() => active = value),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(
                  widget.goal == null ? 'Create goal' : 'Update goal',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final entered = double.parse(target.text);
    Navigator.pop(
      context,
      EarningsGoal(
        id: widget.goal?.id ?? const Uuid().v4(),
        name: name.text.trim(),
        measure: measure,
        period: period,
        target: measure == GoalMeasure.sales
            ? entered.round()
            : (entered * 100).round(),
        active: active,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
      ),
    );
  }
}

String _value(EarningsGoal goal, int value) => goal.measure == GoalMeasure.sales
    ? NumberFormat.decimalPattern().format(value)
    : Money(value).format(decimals: false);

String _heading(EarningsGoal goal, DateTime now) => switch (goal.period) {
  GoalPeriod.daily => DateFormat('EEEE').format(now).toUpperCase(),
  GoalPeriod.weekly => 'THIS WEEK',
  GoalPeriod.monthly => DateFormat('MMMM').format(now).toUpperCase(),
  GoalPeriod.annual => now.year.toString(),
};

String _title(String value) => '${value[0].toUpperCase()}${value.substring(1)}';
