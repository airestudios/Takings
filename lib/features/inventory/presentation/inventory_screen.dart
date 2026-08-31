import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/inventory/application/inventory_controller.dart';
import 'package:profit_track/features/inventory/domain/inventory_item.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  InventoryStatus? filter;

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryControllerProvider);
    return ProfitScaffold(
      currentIndex: 4,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => context.go('/more'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Inventory',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () => setState(() => filter = null),
                ),
                ...InventoryStatus.values.map(
                  (status) => _FilterChip(
                    label: _statusLabel(status),
                    selected: filter == status,
                    onTap: () => setState(() => filter = status),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inventory.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
              data: (items) {
                final visible = filter == null
                    ? items
                    : items.where((item) => item.status == filter).toList();
                return _InventoryList(
                  items: visible,
                  onEdit: _openEditor,
                  onDelete: (item) => ref
                      .read(inventoryControllerProvider.notifier)
                      .remove(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor([InventoryItem? item]) async {
    final saved = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _InventoryEditor(item: item),
    );
    if (saved != null) {
      await ref.read(inventoryControllerProvider.notifier).save(saved);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No inventory items in this view.',
          style: TextStyle(color: AppColors.slate),
        ),
      );
    }
    final invested = items
        .where((item) => item.status != InventoryStatus.sold)
        .fold<int>(0, (sum, item) => sum + item.purchaseCostMinor);
    final potential = items
        .where((item) => item.status != InventoryStatus.sold)
        .fold<int>(0, (sum, item) => sum + item.potentialProfitMinor);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Stock invested',
                value: Money(invested).format(),
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Potential profit',
                value: Money(potential).format(),
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  const ProfitIcon(Icons.inventory_2_outlined, size: 42),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.item,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _StatusPill(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.marketplace} · ${item.category} · ${DateFormat('d MMM').format(item.purchaseDate)}',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cost ${Money(item.purchaseCostMinor).format()}  List ${Money(item.listingPriceMinor).format()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.slate, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final InventoryStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.paleGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _statusLabel(status),
      style: const TextStyle(
        color: AppColors.deepGreen,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _InventoryEditor extends StatefulWidget {
  const _InventoryEditor({this.item});

  final InventoryItem? item;

  @override
  State<_InventoryEditor> createState() => _InventoryEditorState();
}

class _InventoryEditorState extends State<_InventoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _item;
  late final TextEditingController _cost;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late String _marketplace;
  late String _category;
  late InventoryStatus _status;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.item;
    _item = TextEditingController(text: existing?.item);
    _cost = TextEditingController(
      text: existing == null
          ? ''
          : (existing.purchaseCostMinor / 100).toStringAsFixed(2),
    );
    _price = TextEditingController(
      text: existing == null
          ? ''
          : (existing.listingPriceMinor / 100).toStringAsFixed(2),
    );
    _notes = TextEditingController(text: existing?.notes);
    _marketplace = existing?.marketplace ?? 'Vinted';
    _category = existing?.category ?? 'Other';
    _status = existing?.status ?? InventoryStatus.unlisted;
    _date = existing?.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _item.dispose();
    _cost.dispose();
    _price.dispose();
    _notes.dispose();
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
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item == null ? 'Add inventory' : 'Edit inventory',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _item,
              decoration: const InputDecoration(labelText: 'Item name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an item name'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MoneyField(controller: _cost, label: 'Purchase cost'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MoneyField(
                    controller: _price,
                    label: 'Listing price',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _marketplace,
                    decoration: const InputDecoration(labelText: 'Marketplace'),
                    items: const ['Vinted', 'eBay', 'Depop', 'Etsy', 'Other']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _marketplace = value!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        const [
                              'Outerwear',
                              'T-Shirts',
                              'Footwear',
                              'Accessories',
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<InventoryStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: InventoryStatus.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_statusLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const ProfitIcon(Icons.calendar_today_outlined),
              title: const Text('Purchase date'),
              subtitle: Text(DateFormat('d MMMM yyyy').format(_date)),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.item == null ? 'Save item' : 'Update item'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

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
      InventoryItem(
        id: widget.item?.id ?? const Uuid().v4(),
        item: _item.text.trim(),
        purchaseCostMinor: _minor(_cost.text),
        purchaseDate: _date,
        marketplace: _marketplace,
        listingPriceMinor: _minor(_price.text),
        category: _category,
        status: _status,
        externalListingId: widget.item?.externalListingId,
        notes: _notes.text.trim(),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, prefixText: '£ '),
    validator: (value) => _minor(value ?? '') < 0 ? 'Invalid amount' : null,
  );
}

String _statusLabel(InventoryStatus status) => switch (status) {
  InventoryStatus.unlisted => 'Unlisted',
  InventoryStatus.listed => 'Listed',
  InventoryStatus.sold => 'Sold',
};

int _minor(String value) =>
    ((double.tryParse(value.replaceAll(',', '').trim()) ?? 0) * 100).round();
