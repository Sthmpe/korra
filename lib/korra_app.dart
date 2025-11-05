import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'config/theme/app_theme.dart';
import 'logic/core/net/global_offline_banner.dart';
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
        /// 💡 Wrap entire navigation tree using [builder]
        builder: (context, child) {
          return Stack(
            children: [
              /// Everything in the app (GetX routes, pages, etc.)
              KorraOfflineGate(
                child: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),

              /// 👇🏽 Always-visible global offline banner
              const Align(
                alignment: Alignment.topCenter,
                child: SafeArea(child: GlobalOfflineBanner()),
              ),
            ],
          );
        },

        home: startScreen,
      ),
    );
  }
}