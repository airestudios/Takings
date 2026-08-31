import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/app/theme.dart';
import 'package:profit_track/features/shared/presentation/app_card.dart';
import 'package:profit_track/features/shared/presentation/profit_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  String country = 'GB';
  String currency = 'GBP';
  final marketplaces = <String>{'Vinted', 'eBay'};
  String sellerProfile = 'A mixture of both';
  String importChoice = 'Start fresh';
  String goalType = 'Monthly profit';
  final goalController = TextEditingController(text: '1000');

  @override
  void dispose() {
    controller.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ProfitTrack',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${page + 1} of 8',
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
                  value: (page + 1) / 8,
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
                      onChanged: (value) =>
                          setState(() => importChoice = value),
                    ),
                  ),
                  _ChoicePage(
                    title: 'Set your first goal',
                    subtitle:
                        'Give yourself a clear target. You can manage multiple goals later.',
                    child: _GoalSetup(
                      type: goalType,
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
                  if (page > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: page == 7 ? _finish : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        page == 7 ? 'Start tracking' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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
    controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
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
        'CAD': r'C$  Canadian dollar',
        'AUD': r'A$  Australian dollar',
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
              checkmarkColor: AppColors.green,
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
  const _ImportChoices({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = [
      ('Connect eBay', Icons.link_rounded),
      ('Connect Etsy', Icons.link_rounded),
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
                      ProfitIcon(item.$2, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (selected == item.$1)
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
    required this.controller,
    required this.onChanged,
  });

  final String type;
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
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.currency_pound_rounded,
              color: AppColors.green,
            ),
            labelText: 'Target',
          ),
        ),
      ],
    );
  }
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
