import 'package:intl/intl.dart';

class Money {
  const Money(this.minorUnits, {this.currencyCode = 'GBP'});

  final int minorUnits;
  final String currencyCode;

  double get majorUnits => minorUnits / 100;

  String format({bool decimals = true}) {
    final pattern = decimals ? '£#,##0.00' : '£#,##0';
    return NumberFormat(pattern, 'en_GB').format(majorUnits);
  }
}
