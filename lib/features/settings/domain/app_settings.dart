class AppSettings {
  const AppSettings({
    required this.displayName,
    required this.countryCode,
    required this.currencyCode,
    required this.notificationsEnabled,
    required this.automaticSync,
    required this.biometricLock,
  });

  final String displayName;
  final String countryCode;
  final String currencyCode;
  final bool notificationsEnabled;
  final bool automaticSync;
  final bool biometricLock;

  AppSettings copyWith({
    String? displayName,
    String? countryCode,
    String? currencyCode,
    bool? notificationsEnabled,
    bool? automaticSync,
    bool? biometricLock,
  }) => AppSettings(
    displayName: displayName ?? this.displayName,
    countryCode: countryCode ?? this.countryCode,
    currencyCode: currencyCode ?? this.currencyCode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    automaticSync: automaticSync ?? this.automaticSync,
    biometricLock: biometricLock ?? this.biometricLock,
  );
}
