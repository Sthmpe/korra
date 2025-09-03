import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'config/theme/app_theme.dart';
import 'logic/core/net/korra_offline_gate.dart';

class KorraApp extends StatelessWidget {
  const KorraApp({
    super.key,
    required this.startScreen,
  });

  final Widget startScreen;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (_, __) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Korra',
        theme: AppTheme.light(),
        home: KorraOfflineGate(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: startScreen,
          ),
        ),
      ),
    );
  }
}