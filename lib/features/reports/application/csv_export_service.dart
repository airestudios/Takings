import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:profit_track/features/expenses/domain/expense.dart';
import 'package:profit_track/features/inventory/domain/inventory_item.dart';
import 'package:profit_track/features/sales/domain/sale.dart';

class CsvExportService {
  Future<File> exportSales(List<Sale> sales) {
    return _write('sales', [
      [
        'ID',
        'Item',
        'Marketplace',
        'Sale date',
        'Selling price',
        'Purchase cost',
        'Fees',
        'Postage',
        'Packaging',
        'Other costs',
        'Net profit',
        'Category',
        'Notes',
        'Import source',
        'Transaction ID',
      ],
      ...sales.map(
        (sale) => [
          sale.id,
          sale.title,
          sale.marketplace,
          DateFormat('yyyy-MM-dd').format(sale.soldAt),
          _major(sale.sellingPriceMinor),
          _major(sale.purchaseCostMinor),
          _major(sale.feeMinor),
          _major(sale.postageMinor),
          _major(sale.packagingMinor),
          _major(sale.otherCostMinor),
          _major(sale.netProfitMinor),
          sale.category,
          sale.notes,
          sale.importSource.name,
          sale.externalTransactionId,
        ],
      ),
    ]);
  }

  Future<File> exportExpenses(List<Expense> expenses) {
    return _write('expenses', [
      ['ID', 'Description', 'Amount', 'Date', 'Category', 'Recurring', 'Notes'],
      ...expenses.map(
        (expense) => [
          expense.id,
          expense.description,
          _major(expense.amountMinor),
          DateFormat('yyyy-MM-dd').format(expense.spentAt),
          expense.category,
          expense.recurringMonthly,
          expense.notes,
        ],
      ),
    ]);
  }

  Future<File> exportInventory(List<InventoryItem> items) {
    return _write('inventory', [
      [
        'ID',
        'Item',
        'Purchase cost',
        'Purchase date',
        'Marketplace',
        'Listing price',
        'Category',
        'Status',
        'Listing ID',
        'Notes',
      ],
      ...items.map(
        (item) => [
          item.id,
          item.item,
          _major(item.purchaseCostMinor),
          DateFormat('yyyy-MM-dd').format(item.purchaseDate),
          item.marketplace,
          _major(item.listingPriceMinor),
          item.category,
          item.status.name,
          item.externalListingId,
          item.notes,
        ],
      ),
    ]);
  }

  Future<File> _write(String label, List<List<Object?>> rows) async {
    final documents = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${documents.path}/exports');
    await exportDirectory.create(recursive: true);
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final file = File('${exportDirectory.path}/profittrack-$label-$stamp.csv');
    final csv = rows.map((row) => row.map(_escape).join(',')).join('\r\n');
    return file.writeAsString('\uFEFF$csv', flush: true);
  }

  String _escape(Object? value) {
    final text = value?.toString() ?? '';
    final quote = String.fromCharCode(34);
    return '$quote${text.replaceAll(quote, quote + quote)}$quote';
  }

  String _major(int minor) => (minor / 100).toStringAsFixed(2);
}
