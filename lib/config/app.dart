import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes.dart';

class LivoraRootApp extends StatelessWidget {
  const LivoraRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naarixa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.root,
    );
  }
}