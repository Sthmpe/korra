import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'config/theme/app_theme.dart';
import 'logic/core/net/global_offline_banner.dart';
import 'logic/core/net/korra_offline_gate.dart';
import 'logic/core/update/korra_update_gate.dart';

class KorraApp extends StatelessWidget {
  const KorraApp({super.key, required this.startScreen});
  final Widget startScreen;

  static const double kMaxAppWidth = 450; // fintech-safe
  static const double kMinAppHeight = 900;
  static const double kMaxAppHeight = 950; 
 
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Korra',
          theme: AppTheme.light(),

          builder: (context, navigatorChild) {
            final mediaQuery = MediaQuery.of(context);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.grey.shade100,
                resizeToAvoidBottomInset: false,

                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kMaxAppWidth,
                      minHeight: kMinAppHeight,
                      maxHeight: kMaxAppHeight,
                    ),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          const GlobalOfflineBanner(),
                          Expanded(
                            child: KorraOfflineGate(
                              child: KorraUpdateGate(
                                child: GestureDetector(
                                  onTap: () =>
                                      FocusManager.instance.primaryFocus?.unfocus(),
                                  behavior: HitTestBehavior.translucent,
                                  child: navigatorChild,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },

          home: startScreen,
        );
      },
    );
  }
}