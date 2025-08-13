import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'config/theme/app_theme.dart';

class KorraApp extends StatelessWidget {
  const KorraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, __) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Korra',
        theme: AppTheme.light(),
        home: const Placeholder(), // replace with your LoginScreen
      ),
    );
  }
}