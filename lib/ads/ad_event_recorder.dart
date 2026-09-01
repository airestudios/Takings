import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class AdEventRecorder {
  static Future<void> record(
    String event,
    String placement,
    String format,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'ad_event_${event}_${placement}_$format';
    await preferences.setInt(key, (preferences.getInt(key) ?? 0) + 1);
  }

  static Future<void> recordRevenue({
    required String placement,
    required String format,
    required double micros,
    required String currency,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final key = 'ad_revenue_${placement}_${format}_$platform';
    final current =
        jsonDecode(preferences.getString(key) ?? '{}') as Map<String, dynamic>;
    await preferences.setString(
      key,
      jsonEncode({
        'micros': (current['micros'] as num? ?? 0) + micros,
        'impressions': (current['impressions'] as int? ?? 0) + 1,
        'currency': currency,
        'appVersion': '1.0.0',
      }),
    );
  }
}
