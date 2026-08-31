import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/app/router.dart';
import 'package:profit_track/app/theme.dart';

class ProfitTrackApp extends ConsumerWidget {
  const ProfitTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ProfitTrack',
      debugShowCheckedModeBanner: false,
      theme: ProfitTrackTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
