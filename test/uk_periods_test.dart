import 'package:flutter_test/flutter_test.dart';
import 'package:profit_track/tax_rules/domain/threshold_rule.dart';

void main() {
  test('UK tax year starts on 6 April', () {
    expect(UkPeriods.taxYearStart(DateTime(2026, 4, 5)), DateTime(2025, 4, 6));
    expect(UkPeriods.taxYearStart(DateTime(2026, 4, 6)), DateTime(2026, 4, 6));
    expect(UkPeriods.taxYearEnd(DateTime(2026, 8, 31)), DateTime(2027, 4, 5));
  });

  test('rolling twelve month range starts after same date prior year', () {
    expect(
      UkPeriods.rollingTwelveMonthStart(DateTime(2026, 8, 31)),
      DateTime(2025, 9),
    );
  });
}
