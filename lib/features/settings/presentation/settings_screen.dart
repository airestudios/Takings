import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/ads/ad_service.dart';
import 'package:profit_track/features/settings/application/settings_controller.dart';
import 'package:profit_track/features/settings/domain/app_settings.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:profit_track/notifications/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return ProfitScaffold(
      currentIndex: 4,
      body: Column(
        children: [
          _Header(title: 'Settings', onBack: () => context.go('/more')),
          Expanded(
            child: settings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
              data: (value) => _SettingsForm(settings: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final TextEditingController name;
  late String country;
  late String currency;
  late bool notifications;
  late bool automaticSync;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.settings.displayName);
    country = widget.settings.countryCode;
    currency = widget.settings.currencyCode;
    notifications = widget.settings.notificationsEnabled;
    automaticSync = widget.settings.automaticSync;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
    children: [
      const Text(
        'Profile & region',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      AppCard(
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: country,
              decoration: const InputDecoration(labelText: 'Country'),
              items:
                  const {
                        'GB': 'United Kingdom',
                        'US': 'United States',
                        'CA': 'Canada',
                        'AU': 'Australia',
                        'OTHER': 'Other',
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => country = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: const ['GBP', 'USD', 'CAD', 'AUD', 'EUR']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => currency = value!),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Automation',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Goal notifications'),
              subtitle: const Text('Milestones and approaching goals'),
              value: notifications,
              onChanged: (value) => setState(() => notifications = value),
            ),
            const Divider(height: 1, indent: 16),
            SwitchListTile(
              title: const Text('Automatic marketplace sync'),
              subtitle: const Text('Only connected official integrations'),
              value: automaticSync,
              onChanged: (value) => setState(() => automaticSync = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FutureBuilder<bool>(
        future: AdService.privacyOptionsRequired(),
        builder: (context, snapshot) {
          if (snapshot.data != true) return const SizedBox.shrink();
          return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Advertising privacy options'),
              subtitle: const Text('Review or change your consent choices'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: AdService.showPrivacyOptions,
            ),
          );
        },
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save settings'),
      ),
    ],
  );

  Future<void> _save() async {
    if (notifications && !widget.settings.notificationsEnabled) {
      notifications = await NotificationService.instance.requestPermission();
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .save(
          widget.settings.copyWith(
            displayName: name.text.trim(),
            countryCode: country,
            currencyCode: currency,
            notificationsEnabled: notifications,
            automaticSync: automaticSync,
          ),
        );
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
