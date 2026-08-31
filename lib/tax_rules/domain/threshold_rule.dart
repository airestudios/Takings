enum ThresholdType {
  tradingAllowance,
  marketplaceReporting,
  taxRegistration,
  vatGstRegistration,
  informationOnly,
  custom,
}

enum MeasurementBasis {
  grossTradingIncome,
  revenue,
  taxableTurnover,
  transactionCount,
  profit,
  rollingTwelveMonthTurnover,
  calendarYearRevenue,
  taxYearRevenue,
  calendarQuarterRevenue,
  fourConsecutiveQuarterRevenue,
  manualQualifyingIncome,
}

class ThresholdRule {
  const ThresholdRule({
    required this.id,
    required this.name,
    required this.jurisdiction,
    required this.type,
    required this.measurementBasis,
    required this.threshold,
    required this.effectiveFrom,
    required this.lastVerified,
    required this.sourceLabel,
    required this.sourceUri,
    required this.version,
    this.effectiveUntil,
    this.notificationMilestones = const [50, 75, 90, 100],
  });

  final String id;
  final String name;
  final String jurisdiction;
  final ThresholdType type;
  final MeasurementBasis measurementBasis;
  final int threshold;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final DateTime lastVerified;
  final String sourceLabel;
  final Uri sourceUri;
  final String version;
  final List<int> notificationMilestones;

  double percentage(int trackedAmount) =>
      threshold <= 0 ? 0 : trackedAmount / threshold * 100;
  bool isOutdated(DateTime now) =>
      effectiveUntil != null && now.isAfter(effectiveUntil!);
}

abstract final class UkPeriods {
  static DateTime taxYearStart(DateTime date) {
    final currentYearStart = DateTime(date.year, 4, 6);
    return date.isBefore(currentYearStart)
        ? DateTime(date.year - 1, 4, 6)
        : currentYearStart;
  }

  static DateTime taxYearEnd(DateTime date) {
    final start = taxYearStart(date);
    return DateTime(start.year + 1, 4, 5);
  }

  static DateTime rollingTwelveMonthStart(DateTime end) =>
      DateTime(end.year - 1, end.month, end.day).add(const Duration(days: 1));
}
