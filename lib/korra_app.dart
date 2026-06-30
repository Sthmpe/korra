import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; 
import 'package:google_fonts/google_fonts.dart';

import 'config/theme/app_theme.dart';
import 'logic/core/net/global_offline_banner.dart';
import 'logic/core/net/korra_offline_gate.dart';
import 'logic/core/update/korra_update_gate.dart';
import 'presentation/shared/not_found_screen.dart';
import 'presentation/shared/pwa/global_install_button.dart';

class KorraApp extends StatelessWidget {
  const KorraApp({
    super.key, 
    required this.initialRoute,
    required this.appPages,
    required this.isMerchant, 
  });
  
  final String initialRoute;
  final List<GetPage> appPages;
  final bool isMerchant; 

  static const double kMaxMobileWidth = 5990.0; // 🔥 Lowered to 480px to match standard wide mobile devices and stop tablet stretching

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( 
      debugShowCheckedModeBanner: false,
      title: isMerchant ? 'Korra Business' : 'Korra',
      theme: AppTheme.light(),
      initialRoute: initialRoute, 
      getPages: appPages,  
      unknownRoute: GetPage(
        name: '/not-found', 
        page: () => const NotFoundScreen(),
      ),

      builder: (context, navigatorChild) {
        final mediaQuery = MediaQuery.of(context);
        final size = mediaQuery.size;

        // 🎯 1. CLAMP GLOBAL TEXT SCALING IMMEDIATELY
        // This ensures ANY text or icon rendered below stays clean and crisp on web/desktop.
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: kIsWeb ? 0.75 : 0.85,  // Changed to 1.0 to prevent text shrinking dangerously
              maxScaleFactor: kIsWeb ? 0.9 : 1.05, // Caps text scaling completely
            ),
          ),
          child: Builder(
            builder: (context) {
              // 🎯 2. THE PREMIUM BLOCKER
              if (size.width > kMaxMobileWidth) {
                return const _PremiumDesktopBlocker();
              }

              // 📱 3. THE MOBILE APP 
              return ScreenUtilInit(
                designSize: const Size(430, 932),
                minTextAdapt: true,
                splitScreenMode: true,
                // 🔥 CRITICAL: Fixes ScreenUtil blowing up layout containers on small desktop web windows
                fontSizeResolver: (fontSize, instance) {
                  if (kIsWeb) {
                    return fontSize.toDouble() * 0.75; // 👈 WEB: 15% smaller (Change to 0.75 for even smaller)
                  } else {
                    return fontSize.toDouble() * 0.85; // 👈 MOBILE: 15% larger
                  }
                },
                builder: (context, child) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Stack(
                      children: [
                        Column(
                          children: [
                            const GlobalOfflineBanner(),
                            Expanded(
                              child: KorraOfflineGate(
                                child: KorraUpdateGate(
                                  child: GestureDetector(
                                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                                    behavior: HitTestBehavior.translucent,
                                    child: navigatorChild, 
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (kIsWeb)
                          GlobalInstallButton(
                            variant: isMerchant 
                                ? KorraAppVariant.merchant 
                                : KorraAppVariant.customer,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// =====================================================================
// 💎 PREMIUM DESKTOP LANDING SCREEN
// =====================================================================
class _PremiumDesktopBlocker extends StatelessWidget {
  const _PremiumDesktopBlocker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 440), // Made slightly tighter for crisp desktop view
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                        height: 80, 
                        width: 80,
                        errorBuilder: (c, o, s) => const Icon(
                          Icons.wallet_rounded, 
                          size: 40, // Reduced from 60 to prevent container overflows
                          color: Color(0xFFA54600)
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      "Korra is Mobile First",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24, // Optimized sizing
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "To ensure the highest security for your wallet and transactions, Korra is currently available exclusively on mobile devices.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14, // Optimized for standard desktop readability
                        color: Colors.grey.shade500,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Icon(Icons.qr_code_rounded, size: 20, color: Colors.grey.shade800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Switch to your phone",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Open this link on iOS or Android",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
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
              
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    "Secured by Korra",
                    style: GoogleFonts.inter(
                      fontSize: 12,
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