import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/settings/application/settings_controller.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/features/shared/presentation/profit_scaffold.dart';
import 'package:profit_track/security/biometric_service.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return ProfitScaffold(
      currentIndex: 4,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => context.go('/more'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Privacy & security',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AppCard(
            child: Row(
              children: [
                ProfitIcon(Icons.phone_android_rounded, size: 52),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local-first storage',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sales, expenses, inventory and goals stay in the app database on this device.',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          settings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('$error'),
            data: (value) => AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.green,
                  size: 30,
                ),
                title: const Text('Biometric app lock'),
                subtitle: const Text(
                  'Use the device biometric prompt to enable protection',
                ),
                value: value.biometricLock,
                onChanged: (enabled) => _setBiometric(context, ref, enabled),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data handling',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                _PrivacyPoint(
                  icon: Icons.cloud_off_outlined,
                  text: 'Manual tracking works offline.',
                ),
                _PrivacyPoint(
                  icon: Icons.key_off_outlined,
                  text: 'Marketplace passwords are never requested.',
                ),
                _PrivacyPoint(
                  icon: Icons.upload_file_outlined,
                  text:
                      'Data leaves the device only when you explicitly connect or export.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final current = ref.read(settingsControllerProvider).value;
    if (current == null) return;
    if (enabled) {
      try {
        final confirmed = await BiometricService().enable();
        if (!confirmed) {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric protection is unavailable or was not confirmed.',
                ),
              ),
            );
          return;
        }
      } catch (error) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not enable biometric lock: $error')),
          );
        return;
      }
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .save(current.copyWith(biometricLock: enabled));
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Icon(icon, color: AppColors.green, size: 20),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}
