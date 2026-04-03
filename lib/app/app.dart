import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';

class NaarixaApp extends ConsumerWidget {
  const NaarixaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Naarixa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.root,
    );
  }
}
