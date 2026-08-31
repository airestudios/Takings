import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings(
      displayName: preferences.getString('display_name') ?? 'Alex',
      countryCode: preferences.getString('country_code') ?? 'GB',
      currencyCode: preferences.getString('currency_code') ?? 'GBP',
      notificationsEnabled:
          preferences.getBool('notifications_enabled') ?? true,
      automaticSync: preferences.getBool('automatic_sync') ?? false,
      biometricLock: preferences.getBool('biometric_lock') ?? false,
    );
  }

  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString('display_name', settings.displayName),
      preferences.setString('country_code', settings.countryCode),
      preferences.setString('currency_code', settings.currencyCode),
      preferences.setBool(
        'notifications_enabled',
        settings.notificationsEnabled,
      ),
      preferences.setBool('automatic_sync', settings.automaticSync),
      preferences.setBool('biometric_lock', settings.biometricLock),
    ]);
    state = AsyncData(settings);
  }
}
