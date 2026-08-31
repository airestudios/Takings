import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/core/money.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/period_selector.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:uuid/uuid.dart';

class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key, this.initialSale});

  final Sale? initialSale;

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final formKey = GlobalKey<FormState>();
  final itemController = TextEditingController(text: 'Nike Hoodie');
  final sellingController = TextEditingController(text: '40.00');
  final purchaseController = TextEditingController(text: '12.00');
  final feeController = TextEditingController(text: '2.50');
  final postageController = TextEditingController(text: '3.50');
  final packagingController = TextEditingController(text: '1.00');
  final otherController = TextEditingController(text: '0.00');
  final notesController = TextEditingController();
  int mode = 0;
  bool detailsOpen = true;
  String marketplace = 'Vinted';
  String category = 'Clothing > Hoodies';
  DateTime saleDate = DateTime.now();

  int get soldMinor => _minor(sellingController.text);
  int get purchaseMinor => _minor(purchaseController.text);
  int get feeMinor => _minor(feeController.text);
  int get postageMinor => _minor(postageController.text);
  int get packagingMinor => _minor(packagingController.text);
  int get otherMinor => _minor(otherController.text);
  int get profitMinor =>
      soldMinor -
      purchaseMinor -
      feeMinor -
      postageMinor -
      packagingMinor -
      otherMinor;
  double get margin => soldMinor == 0 ? 0 : profitMinor / soldMinor * 100;
  double? get roi =>
      purchaseMinor == 0 ? null : profitMinor / purchaseMinor * 100;

  int _minor(String value) =>
      ((double.tryParse(value.replaceAll(',', '')) ?? 0) * 100).round();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSale;
    if (initial != null) {
      itemController.text = initial.title;
      sellingController.text = (initial.sellingPriceMinor / 100)
          .toStringAsFixed(2);
      purchaseController.text = (initial.purchaseCostMinor / 100)
          .toStringAsFixed(2);
      feeController.text = (initial.feeMinor / 100).toStringAsFixed(2);
      postageController.text = (initial.postageMinor / 100).toStringAsFixed(2);
      packagingController.text = (initial.packagingMinor / 100).toStringAsFixed(
        2,
      );
      otherController.text = (initial.otherCostMinor / 100).toStringAsFixed(2);
      notesController.text = initial.notes;
      marketplace = initial.marketplace;
      category = initial.category;
      saleDate = initial.soldAt;
      mode = 1;
    }
    for (final controller in [
      sellingController,
      purchaseController,
      feeController,
      postageController,
      packagingController,
      otherController,
    ]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    itemController.dispose();
    sellingController.dispose();
    purchaseController.dispose();
    feeController.dispose();
    postageController.dispose();
    packagingController.dispose();
    otherController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfitScaffold(
      currentIndex: 2,
      body: Column(
        children: [
          _AddSaleHeader(
            title: widget.initialSale == null ? 'Add Sale' : 'Edit Sale',
            onBack: () =>
                context.go(widget.initialSale == null ? '/' : '/sales'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Column(
                children: [
                  PeriodSelector(
                    labels: const ['Quick Sale', 'Detailed'],
                    selectedIndex: mode,
                    onSelected: (value) => setState(() => mode = value),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final form = _formCard();
                      final summary = _summaryColumn();
                      if (constraints.maxWidth < 440) {
                        return Column(
                          children: [form, const SizedBox(height: 12), summary],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 59, child: form),
                          const SizedBox(width: 8),
                          Expanded(flex: 36, child: summary),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: _QuickChip(
                          icon: Icons.sell_outlined,
                          label: 'Vinted default fees',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _QuickChip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Packaging',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _QuickChip(
                          icon: Icons.bookmark_border_rounded,
                          label: 'Save preset',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => _save(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        widget.initialSale == null
                            ? 'Save Sale'
                            : 'Update Sale',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (widget.initialSale == null) ...[
                    const SizedBox(height: 7),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => _save(true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save & Add Another',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _InputBlock(
              label: 'Item name',
              required: true,
              child: TextFormField(
                controller: itemController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an item name'
                    : null,
                decoration: const InputDecoration(
                  prefixIcon: _FieldIcon(Icons.sell_outlined),
                  suffixIcon: Icon(Icons.close_rounded, color: AppColors.slate),
                ),
              ),
            ),
            _InputBlock(
              label: 'Selling price',
              required: true,
              child: _MoneyField(controller: sellingController),
            ),
            _InputBlock(
              label: 'Purchase cost',
              required: true,
              child: _MoneyField(controller: purchaseController),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => detailsOpen = !detailsOpen),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add costs/details',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(
                            detailsOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (detailsOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Column(
                        children: [
                          _InputBlock(
                            label: 'Marketplace',
                            child: DropdownButtonFormField<String>(
                              initialValue: marketplace,
                              decoration: const InputDecoration(
                                prefixIcon: _FieldIcon(
                                  Icons.sell_outlined,
                                  color: AppColors.teal,
                                ),
                              ),
                              items:
                                  const [
                                        'Vinted',
                                        'eBay',
                                        'Depop',
                                        'Etsy',
                                        'Facebook Marketplace',
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
                          ),
                          _InputBlock(
                            label: 'Marketplace fee',
                            child: _MoneyField(
                              controller: feeController,
                              suffix: soldMinor == 0
                                  ? null
                                  : '${(feeMinor / soldMinor * 100).toStringAsFixed(1)}%',
                            ),
                          ),
                          _InputBlock(
                            label: 'Postage cost',
                            child: _MoneyField(controller: postageController),
                          ),
                          _InputBlock(
                            label: 'Packaging cost',
                            child: _MoneyField(controller: packagingController),
                          ),
                          if (mode == 1)
                            _InputBlock(
                              label: 'Other cost',
                              child: _MoneyField(controller: otherController),
                            ),
                          _InputBlock(
                            label: 'Sale date',
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: _FieldIcon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          'd MMM yyyy',
                                        ).format(saleDate),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: AppColors.slate,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _InputBlock(
                            label: 'Category',
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(
                                prefixIcon: _FieldIcon(Icons.sell_outlined),
                              ),
                              items:
                                  const [
                                        'Clothing > Hoodies',
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
                              onChanged: (value) =>
                                  setState(() => category = value ?? category),
                            ),
                          ),
                          _InputBlock(
                            label: 'Notes (optional)',
                            child: TextFormField(
                              controller: notesController,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                prefixIcon: _FieldIcon(Icons.note_alt_outlined),
                                hintText: 'Add a note...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryColumn() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4FBF7),
            border: Border.all(color: const Color(0xFFDDEFE5)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1008142C),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _SummaryLine(label: 'Sold for', value: Money(soldMinor).format()),
              _SummaryLine(
                label: 'Bought for',
                value: Money(purchaseMinor).format(),
              ),
              _SummaryLine(
                label: 'Fees',
                value: Money(feeMinor).format(),
                info: true,
              ),
              _SummaryLine(
                label: 'Postage',
                value: Money(postageMinor).format(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              const Text(
                'YOUR PROFIT',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(
                  Money(profitMinor).format(),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 37,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              _Metric(
                icon: Icons.percent_rounded,
                value: '${margin.round()}%',
                label: 'margin',
              ),
              const SizedBox(height: 10),
              _Metric(
                icon: Icons.trending_up_rounded,
                value: roi == null ? '—' : '${roi!.round()}%',
                label: 'ROI',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6FCF8),
            border: Border.all(color: const Color(0xFFCFEAD9)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.star_border_rounded, color: AppColors.green),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great result!',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'You’re making a healthy margin on this sale.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slate,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: saleDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null) setState(() => saleDate = selected);
  }

  Future<void> _save(bool addAnother) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final initial = widget.initialSale;
    final sale = Sale(
      id: initial?.id ?? const Uuid().v4(),
      title: itemController.text.trim(),
      marketplace: marketplace,
      soldAt: saleDate,
      sellingPriceMinor: soldMinor,
      purchaseCostMinor: purchaseMinor,
      feeMinor: feeMinor,
      postageMinor: postageMinor,
      packagingMinor: packagingMinor,
      otherCostMinor: otherMinor,
      category: category,
      notes: notesController.text.trim(),
      importSource: initial?.importSource ?? ImportSource.manual,
      status: initial?.status ?? SaleStatus.completed,
      externalAccountId: initial?.externalAccountId,
      externalListingId: initial?.externalListingId,
      externalOrderId: initial?.externalOrderId,
      externalTransactionId: initial?.externalTransactionId,
      importedAt: initial?.importedAt,
      lastSyncedAt: initial?.lastSyncedAt,
    );
    await ref.read(salesControllerProvider.notifier).add(sale);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(initial == null ? 'Sale saved' : 'Sale updated')),
    );
    if (addAnother) {
      itemController.clear();
      sellingController.clear();
      purchaseController.clear();
      feeController.clear();
      postageController.clear();
      packagingController.text = '1.00';
      notesController.clear();
    } else {
      context.go('/sales');
    }
  }
}

class _AddSaleHeader extends StatelessWidget {
  const _AddSaleHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            label: 'Back',
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          _RoundButton(
            icon: Icons.help_outline_rounded,
            onTap: () {},
            label: 'Help',
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 21),
        ),
      ),
    );
  }
}

class _InputBlock extends StatelessWidget {
  const _InputBlock({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon(this.icon, {this.color = AppColors.green});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, this.suffix});

  final TextEditingController controller;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => value == null || double.tryParse(value) == null
          ? 'Enter a valid amount'
          : null,
      decoration: InputDecoration(
        prefixIcon: const _FieldIcon(Icons.currency_pound_rounded),
        prefixText: '£  ',
        suffixText: suffix,
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.info = false,
  });

  final String label;
  final String value;
  final bool info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          if (info)
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppColors.slate,
                size: 16,
              ),
            ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFDFF3E7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.green, size: 22),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
