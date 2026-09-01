import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profit_track/features/dashboard/presentation/home_screen.dart';
import 'package:profit_track/features/expenses/presentation/expenses_screen.dart';
import 'package:profit_track/features/goals/presentation/goals_thresholds_screen.dart';
import 'package:profit_track/features/insights/presentation/insights_screen.dart';
import 'package:profit_track/features/inventory/presentation/inventory_screen.dart';
import 'package:profit_track/features/onboarding/presentation/onboarding_screen.dart';
import 'package:profit_track/features/reports/presentation/reports_screen.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/features/sales/presentation/add_sale_screen.dart';
import 'package:profit_track/features/sales/presentation/sales_screen.dart';
import 'package:profit_track/features/seller_tools/presentation/seller_tools_screen.dart';
import 'package:profit_track/features/settings/presentation/more_screen.dart';
import 'package:profit_track/features/settings/presentation/privacy_screen.dart';
import 'package:profit_track/features/settings/presentation/settings_screen.dart';

final onboardingCompletedProvider = Provider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);
  return GoRouter(
    initialLocation: onboardingCompleted ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/sales', builder: (context, state) => const SalesScreen()),
      GoRoute(
        path: '/add-sale',
        builder: (context, state) => const AddSaleScreen(),
      ),
      GoRoute(
        path: '/edit-sale',
        builder: (context, state) =>
            AddSaleScreen(initialSale: state.extra as Sale?),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsThresholdsScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/seller-tools',
        builder: (context, state) => const SellerToolsScreen(),
      ),
    ],
  );
});
