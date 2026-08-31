import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/expenses/application/expenses_controller.dart';
import 'package:profit_track/features/expenses/domain/expense.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:uuid/uuid.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesControllerProvider);
    return ProfitScaffold(
      currentIndex: 4,
      body: Column(
        children: [
          _PageHeader(
            title: 'Expenses',
            onAdd: () => _openEditor(context, ref),
          ),
          Expanded(
            child: expenses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
              data: (items) => _ExpenseList(
                items: items,
                onEdit: (item) => _openEditor(context, ref, item),
                onDelete: (item) => ref
                    .read(expensesControllerProvider.notifier)
                    .remove(item.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, [
    Expense? expense,
  ]) async {
    final saved = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ExpenseEditor(expense: expense),
    );
    if (saved != null) {
      await ref.read(expensesControllerProvider.notifier).save(saved);
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => context.go('/more'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Expense> items;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthItems = items.where(
      (item) =>
          item.spentAt.year == now.year && item.spentAt.month == now.month,
    );
    final monthTotal = monthItems.fold<int>(
      0,
      (sum, item) => sum + item.amountMinor,
    );
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        subtitle: 'Add stock, postage, subscriptions and business costs.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        AppCard(
          child: Row(
            children: [
              const ProfitIcon(Icons.calendar_month_outlined, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM expenses').format(now),
                      style: const TextStyle(color: AppColors.slate),
                    ),
                    Text(
                      Money(monthTotal).format(),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${monthItems.length} entries',
                style: const TextStyle(color: AppColors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  ProfitIcon(
                    item.recurringMonthly
                        ? Icons.autorenew_rounded
                        : Icons.receipt_outlined,
                    size: 42,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${item.category} · ${DateFormat('d MMM yyyy').format(item.spentAt)}',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Money(item.amountMinor).format(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        action == 'edit' ? onEdit(item) : onDelete(item),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseEditor extends StatefulWidget {
  const _ExpenseEditor({this.expense});

  final Expense? expense;

  @override
  State<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<_ExpenseEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late String _category;
  late DateTime _date;
  late bool _recurring;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _description = TextEditingController(text: expense?.description);
    _amount = TextEditingController(
      text: expense == null
          ? ''
          : (expense.amountMinor / 100).toStringAsFixed(2),
    );
    _notes = TextEditingController(text: expense?.notes);
    _category = expense?.category ?? 'Stock';
    _date = expense?.spentAt ?? DateTime.now();
    _recurring = expense?.recurringMonthly ?? false;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.expense == null ? 'Add expense' : 'Edit expense',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '£ ',
                ),
                validator: (value) => _toMinor(value) <= 0
                    ? 'Enter an amount greater than zero'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    const [
                          'Stock',
                          'Postage',
                          'Packaging',
                          'Marketplace fees',
                          'Subscription',
                          'Travel',
                          'Other',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const ProfitIcon(Icons.calendar_today_outlined),
                title: const Text('Date'),
                subtitle: Text(DateFormat('d MMMM yyyy').format(_date)),
                onTap: _pickDate,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring monthly'),
                value: _recurring,
                onChanged: (value) => setState(() => _recurring = value),
              ),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    widget.expense == null ? 'Save expense' : 'Update expense',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Expense(
        id: widget.expense?.id ?? const Uuid().v4(),
        description: _description.text.trim(),
        amountMinor: _toMinor(_amount.text),
        spentAt: _date,
        category: _category,
        notes: _notes.text.trim(),
        recurringMonthly: _recurring,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfitIcon(icon, size: 62),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

int _toMinor(String? value) =>
    ((double.tryParse((value ?? '').replaceAll(',', '').trim()) ?? 0) * 100)
        .round();
