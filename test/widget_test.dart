import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_track/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('shows first onboarding step', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('Know exactly what you’re making'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
