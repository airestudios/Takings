import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:profit_track/marketplace_integrations/ebay/ebay_connection_controller.dart';
import 'package:profit_track/marketplace_integrations/etsy/etsy_connection_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  final nameController = TextEditingController();
  String country = 'GB';
  String currency = 'GBP';
  final marketplaces = <String>{};
  String sellerProfile = 'A mixture of both';
  String importChoice = 'Start fresh';
  String goalType = 'Monthly profit';
  final goalController = TextEditingController(text: '1000');
  bool connectingMarketplace = false;

  @override
  void dispose() {
    controller.dispose();
    nameController.dispose();
    goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    '${page + 1} of 9',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (page + 1) / 9,
                  minHeight: 5,
                  backgroundColor: AppColors.line,
                  color: AppColors.green,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => page = value),
                children: [
                  const _WelcomePage(),
                  _ChoicePage(
                    title: 'What should we call you?',
                    subtitle:
                        'We’ll use your name to personalise your dashboard.',
                    child: _NameSetup(
                      controller: nameController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _ChoicePage(
                    title: 'Where are you based?',
                    subtitle:
                        'This helps us show the right currency and relevant tracking rules.',
                    child: _CountryPicker(
                      value: country,
                      onChanged: (value) => setState(() => country = value),
                    ),
                  ),
                  _ChoicePage(
                    title: 'Choose your currency',
                    subtitle:
                        'We’ve suggested one from your country. You can change it any time.',
                    child: _CurrencyPicker(
                      value: currency,
                      onChanged: (value) => setState(() => currency = value),
                    ),
                  ),
                  _ChoicePage(
                    title: 'How do you sell?',
                    subtitle: 'Select every marketplace you use.',
                    child: _MarketplacePicker(
                      values: marketplaces,
                      onChanged: (value) => setState(
                        () => marketplaces.contains(value)
                            ? marketplaces.remove(value)
                            : marketplaces.add(value),
                      ),
                    ),
                  ),
                  _ChoicePage(
                    title: 'Which best describes your selling?',
                    subtitle:
                        'This helps tailor the experience. It does not determine your tax status.',
                    child: _RadioChoices(
                      values: const [
                        'I buy items specifically to resell',
                        'I mainly sell my own unwanted items',
                        'A mixture of both',
                      ],
                      selected: sellerProfile,
                      onChanged: (value) =>
                          setState(() => sellerProfile = value),
                    ),
                  ),
                  _ChoicePage(
                    title: 'Bring your sales with you',
                    subtitle: 'Connections are optional and never block setup.',
                    child: _ImportChoices(
                      selected: importChoice,
                      connectingMarketplace: connectingMarketplace,
                      onChanged: _selectImportChoice,
                    ),
                  ),
                  _ChoicePage(
                    title: 'Set your first goal',
                    subtitle:
                        'Give yourself a clear target. You can manage multiple goals later.',
                    child: _GoalSetup(
                      type: goalType,
                      currency: currency,
                      controller: goalController,
                      onChanged: (value) => setState(() => goalType = value),
                    ),
                  ),
                  const _ThresholdIntro(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  if (page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previous,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: page == 1 && nameController.text.trim().isEmpty
                        ? null
                        : page == 8
                        ? _finish
                        : _next,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      foregroundColor: AppColors.green,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    label: Text(page == 8 ? 'Start tracking' : 'Next'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    FocusManager.instance.primaryFocus?.unfocus();
    controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _selectImportChoice(String value) async {
    if (connectingMarketplace) return;
    setState(() => importChoice = value);
    if (value != 'Connect Etsy' && value != 'Connect eBay') return;

    setState(() => connectingMarketplace = true);
    try {
      final accountName = value == 'Connect eBay'
          ? await _connectEbay()
          : await _connectEtsy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$accountName connected.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => connectingMarketplace = false);
    }
  }

  Future<String> _connectEbay() async {
    await ref.read(ebayConnectionControllerProvider.future);
    await ref.read(ebayConnectionControllerProvider.notifier).connect();
    return 'eBay';
  }

  Future<String> _connectEtsy() async {
    await ref.read(etsyConnectionControllerProvider.future);
    final account = await ref
        .read(etsyConnectionControllerProvider.notifier)
        .connect();
    return account.shopName ?? 'Etsy';
  }

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
    await preferences.setString('display_name', nameController.text.trim());
    await preferences.setString('country_code', country);
    await preferences.setString('currency_code', currency);
    await preferences.setStringList('marketplaces', marketplaces.toList());
    await preferences.setString('seller_profile', sellerProfile);
    await preferences.setString('goal_type', goalType);
    await preferences.setInt(
      'goal_target_minor',
      ((double.tryParse(goalController.text) ?? 1000) * 100).round(),
    );
    if (mounted) context.go('/');
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return _ChoicePage(
      title: 'Know exactly what you’re making',
      subtitle:
          'Fast, private reseller tracking that works even when you’re offline.',
      child: Column(
        children: [
          const SizedBox(height: 12),
          const _Benefit(
            icon: Icons.trending_up_rounded,
            title: 'Track reseller earnings',
            text:
                'See real profit after purchase costs, fees, postage and packaging.',
          ),
          const SizedBox(height: 10),
          const _Benefit(
            icon: Icons.track_changes_rounded,
            title: 'Reach profit goals',
            text: 'Know if you’re on pace and what you need each day.',
          ),
          const SizedBox(height: 10),
          const _Benefit(
            icon: Icons.shield_outlined,
            title: 'Monitor important thresholds',
            text:
                'Get general guidance as your recorded activity approaches relevant rules.',
          ),
        ],
      ),
    );
  }
}

class _ChoicePage extends StatelessWidget {
  const _ChoicePage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ProfitIcon(icon, size: 50),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
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
    );
  }
}

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const countries = {
      'GB': '🇬🇧  United Kingdom',
      'US': '🇺🇸  United States',
      'CA': '🇨🇦  Canada',
      'AU': '🇦🇺  Australia',
      'OTHER': '🌍  Other',
    };
    return _RadioChoices(
      values: countries.keys.toList(),
      labels: countries,
      selected: value,
      onChanged: onChanged,
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RadioChoices(
      values: const ['GBP', 'USD', 'CAD', 'AUD', 'EUR'],
      labels: const {
        'GBP': '£  British pound',
        'USD': r'$  US dollar',
        'CAD': r'$  Canadian dollar',
        'AUD': r'$  Australian dollar',
        'EUR': '€  Euro',
      },
      selected: value,
      onChanged: onChanged,
    );
  }
}

class _MarketplacePicker extends StatelessWidget {
  const _MarketplacePicker({required this.values, required this.onChanged});

  final Set<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      'Vinted',
      'eBay',
      'Depop',
      'Etsy',
      'Facebook Marketplace',
      'Grailed',
      'StockX',
      'Whatnot',
      'Other',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (value) => FilterChip(
              label: Text(value),
              selected: values.contains(value),
              onSelected: (_) => onChanged(value),
              selectedColor: AppColors.paleGreen,
              showCheckmark: false,
              side: BorderSide(
                color: values.contains(value)
                    ? AppColors.green
                    : AppColors.line,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RadioChoices extends StatelessWidget {
  const _RadioChoices({
    required this.values,
    required this.selected,
    required this.onChanged,
    this.labels = const {},
  });

  final List<String> values;
  final Map<String, String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (choice) {
        if (choice != null) onChanged(choice);
      },
      child: Column(
        children: values
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: InkWell(
                  onTap: () => onChanged(value),
                  borderRadius: BorderRadius.circular(12),
                  child: AppCard(
                    borderColor: selected == value
                        ? AppColors.green
                        : AppColors.line,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labels[value] ?? value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Radio<String>(
                          value: value,
                          activeColor: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ImportChoices extends StatelessWidget {
  const _ImportChoices({
    required this.selected,
    required this.connectingMarketplace,
    required this.onChanged,
  });

  final String selected;
  final bool connectingMarketplace;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = [
      ('Connect eBay', Icons.storefront_outlined),
      ('Connect Etsy', Icons.storefront_outlined),
      ('Import sales file', Icons.upload_file_outlined),
      ('Start fresh', Icons.auto_awesome_outlined),
    ];
    return Column(
      children: values
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: () => onChanged(item.$1),
                borderRadius: BorderRadius.circular(12),
                child: AppCard(
                  borderColor: selected == item.$1
                      ? AppColors.green
                      : AppColors.line,
                  child: Row(
                    children: [
                      if (item.$1 == 'Connect eBay')
                        const _EbayLogo()
                      else if (item.$1 == 'Connect Etsy')
                        const _EtsyLogo()
                      else
                        ProfitIcon(item.$2, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (item.$1 == selected &&
                          item.$1.startsWith('Connect ') &&
                          connectingMarketplace)
                        const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (selected == item.$1)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.green,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GoalSetup extends StatelessWidget {
  const _GoalSetup({
    required this.type,
    required this.currency,
    required this.controller,
    required this.onChanged,
  });

  final String type;
  final String currency;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          items:
              const [
                    'Monthly profit',
                    'Monthly revenue',
                    'Yearly profit',
                    'Yearly revenue',
                  ]
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '${_currencySymbol(currency)} ',
            prefixStyle: const TextStyle(
              color: AppColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            labelText: 'Target',
          ),
        ),
      ],
    );
  }
}

class _NameSetup extends StatelessWidget {
  const _NameSetup({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      decoration: const InputDecoration(labelText: 'Your name'),
    );
  }
}

class _EbayLogo extends StatelessWidget {
  const _EbayLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            children: [
              TextSpan(
                text: 'e',
                style: TextStyle(color: Color(0xFFE53238)),
              ),
              TextSpan(
                text: 'b',
                style: TextStyle(color: Color(0xFF0064D2)),
              ),
              TextSpan(
                text: 'a',
                style: TextStyle(color: Color(0xFFF5AF02)),
              ),
              TextSpan(
                text: 'y',
                style: TextStyle(color: Color(0xFF86B817)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtsyLogo extends StatelessWidget {
  const _EtsyLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Text(
          'Etsy',
          style: TextStyle(
            color: Color(0xFFF1641E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
}

String _currencySymbol(String currency) {
  return switch (currency) {
    'EUR' => '€',
    'GBP' => '£',
    _ => r'$',
  };
}

class _ThresholdIntro extends StatelessWidget {
  const _ThresholdIntro();

  @override
  Widget build(BuildContext context) {
    return const _ChoicePage(
      title: 'Stay aware as you grow',
      subtitle:
          'We’ll keep an eye on relevant selling, reporting and registration thresholds for your country.',
      child: Column(
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfitIcon(Icons.shield_outlined, size: 52),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guidance, not a verdict',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'We’ll show recorded progress and link you to official guidance. We won’t tell you that you owe tax or definitively determine whether a rule applies.',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Information in this app is for tracking and general guidance only and is not tax, accounting or legal advice. Rules depend on individual circumstances and can change.',
            style: TextStyle(
              color: AppColors.slate,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
