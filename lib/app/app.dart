import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class MunzurMobilApp extends StatelessWidget {
  const MunzurMobilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Munzur Mobil',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}