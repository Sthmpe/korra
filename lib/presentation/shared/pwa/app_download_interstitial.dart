import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global_install_button.dart'; // For KorraAppVariant

class AppDownloadInterstitial extends StatefulWidget {
  final KorraAppVariant variant;

  const AppDownloadInterstitial({
    super.key,
    required this.variant,
  });

  @override
  State<AppDownloadInterstitial> createState() => _AppDownloadInterstitialState();
}

class _AppDownloadInterstitialState extends State<AppDownloadInterstitial> with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _isMerchant => widget.variant == KorraAppVariant.merchant;

  // The download links for internal testing
  String get _downloadUrl => _isMerchant
      ? 'https://play.google.com/apps/internaltest/4701757247504272153' // Play Store merchant closed test track
      : 'https://play.google.com/apps/internaltest/4701282801352627527'; // Play Store customer closed test track

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Cubic(0.16, 1, 0.3, 1),
    ));

    _checkEligibility();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    // Only show on Mobile Web (Android/iOS)
    final bool isMobileWeb = kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobileWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isDismissed = prefs.getBool('dismiss_download_interstitial') ?? false;
      if (isDismissed) return;

      // Delay slightly for smooth entry
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _isVisible = true);
        _animController.forward();
      }
    } catch (_) {}
  }

  Future<void> _dismiss(bool permanently) async {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
    if (permanently) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('dismiss_download_interstitial', true);
      } catch (_) {}
    }
  }

  Future<void> _launchDownload() async {
    final uri = Uri.parse(_downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    // Warm colors matching Korra's design tokens
    final primaryColor = _isMerchant ? const Color(0xFF0D0D0D) : const Color(0xFFA54600);
    final secondaryColor = _isMerchant ? const Color(0xFF262626) : const Color(0xFFF9E8DC);

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              margin: EdgeInsets.all(16.r),
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull/Drag line placeholder
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Header with Icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: _isMerchant ? Colors.grey.shade100 : secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.mobile,
                          color: primaryColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isMerchant ? "Get Korra Business App" : "Get the Korra App",
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Download the testing app for a faster native experience.",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: () {
                      _launchDownload();
                      _dismiss(false); // Dismiss overlay but not permanently in case they return
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(double.infinity, 54.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27.r),
                      ),
                    ),
                    child: Text(
                      "Download Test App",
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () => _dismiss(true), // Dismiss permanently for this session
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, 44.h),
                    ),
                    child: Text(
                      "Continue to Web App",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
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
  }
}
