import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // ✅ Import GetX
import 'package:google_fonts/google_fonts.dart';
//import 'config/routes/app_pages.dart'; // ✅ Import AppPages
// import 'config/routes/app_routes.dart'; // Optional, if needed for unknownRoute

import 'config/theme/app_theme.dart';
import 'logic/core/net/global_offline_banner.dart';
import 'logic/core/net/korra_offline_gate.dart';
import 'logic/core/update/korra_update_gate.dart';
import 'presentation/shared/not_found_screen.dart';

class KorraApp extends StatelessWidget {
  // 🔄 CHANGED: Now accepts a String Route Name
  const KorraApp({
    super.key, 
    required this.initialRoute,
    required this.appPages
  });
  final String initialRoute;
  final List<GetPage> appPages;

  // 🔒 Threshold: Any screen wider than this gets the "Blocker"
  static const double kMaxMobileWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // ✅ Use GetMaterialApp
      debugShowCheckedModeBanner: false,
      title: 'Korra',
      theme: AppTheme.light(),
      
      // 🚀 NAVIGATION SETUP
      initialRoute: initialRoute, // 1. Set the start route
      getPages: appPages,  // 2. Load the route map
      
      // Fallback for bad URLs
      unknownRoute: GetPage(
        name: '/not-found', 
        page: () => const NotFoundScreen(),
      ),

      // 🏗️ THE LAYOUT MANAGER
      builder: (context, navigatorChild) {
        final size = MediaQuery.of(context).size;

        // 🛑 1. CHECK: IS IT A DESKTOP/TABLET?
        if (size.width > kMaxMobileWidth) {
          return const _PremiumDesktopBlocker();
        }

        // ✅ 2. IS IT MOBILE?
        return ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            
            // Text Scaling Safety
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.16,
                ),
              ),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: Column(
                  children: [
                    const GlobalOfflineBanner(),
                    Expanded(
                      child: KorraOfflineGate(
                        child: KorraUpdateGate(
                          child: GestureDetector(
                            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                            behavior: HitTestBehavior.translucent,
                            // navigatorChild is the page GetX is showing
                            child: navigatorChild, 
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      // ❌ REMOVED: home: startScreen (conflicts with initialRoute)
    );
  }
}

// 💎 THE NEW PREMIUM DESKTOP LANDING SCREEN (Unchanged)
class _PremiumDesktopBlocker extends StatelessWidget {
  const _PremiumDesktopBlocker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Soft luxurious grey-white
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Main Card with "Glass" Feel
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // LOGO / ICON
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/korra_logo_icon.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (c, o, s) => const Icon(
                          Icons.wallet_rounded, 
                          size: 40, 
                          color: Color(0xFFA54600)
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // HEADLINE
                    Text(
                      "Korra is Mobile First",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SUBTITLE
                    Text(
                      "To ensure the highest security for your wallet and transactions, Korra is currently available exclusively on mobile devices.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // VISUAL CUE: Phone Mockup / QR Placeholder
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Icon(Icons.qr_code_rounded, color: Colors.grey.shade800),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Switch to your phone",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Open this link on iOS or Android",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 2. Footer Brand
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    "Secured by Korra Financial",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}