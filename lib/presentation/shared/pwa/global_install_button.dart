import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'pwa_service.dart';

// ─────────────────────────────────────────────
// APP VARIANT — switch this when deploying
// ─────────────────────────────────────────────
enum KorraAppVariant { merchant, customer }

// ─────────────────────────────────────────────
// USAGE in main.dart builder:
//
// MERCHANT APP:
//   const GlobalInstallButton(variant: KorraAppVariant.merchant)
//
// CUSTOMER APP:
//   const GlobalInstallButton(variant: KorraAppVariant.customer)
// ─────────────────────────────────────────────

class GlobalInstallButton extends StatefulWidget {
  final KorraAppVariant variant;

  const GlobalInstallButton({
    super.key,
    required this.variant,
  });

  @override
  State<GlobalInstallButton> createState() => _GlobalInstallButtonState();
}

class _GlobalInstallButtonState extends State<GlobalInstallButton>
    with SingleTickerProviderStateMixin {
  bool _showButton = false;
  bool _isDismissed = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _isMerchant => widget.variant == KorraAppVariant.merchant;
  String get _title => _isMerchant ? 'Install Korra Business' : 'Install Korra';
  String get _subtitle => _isMerchant
      ? 'Manage installments from your home screen'
      : 'Pay in parts, right from your home screen';
  Color get _bgColor =>
      _isMerchant ? const Color(0xFF0D0D0D) : const Color(0xFFA54600);
  Color get _subtitleColor => _isMerchant
      ? Colors.white.withOpacity(0.55)
      : Colors.white.withOpacity(0.75);

  bool _isIos() {
    if (!kIsWeb) return false;
    try {
      return isIosBrowser();
    } catch (_) {
      return false;
    }
  }

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

    _checkInstallStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _checkInstallStatus() {
    if (kIsWeb && !isPwaInstalled()) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showButton = true);
          _animController.forward();
        }
      });
    }
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    if (mounted) setState(() => _isDismissed = true);
  }

  void _handleInstallTap() {
    if (_isIos()) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _IosInstallSheet(
          variant: widget.variant,
          bgColor: _bgColor,
        ),
      );
    } else {
      triggerInstallPrompt();
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showButton || _isDismissed) return const SizedBox.shrink();

    return Positioned(
      bottom: 24.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.mobile,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _title,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: _subtitleColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // Install button
                  GestureDetector(
                    onTap: _handleInstallTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Text(
                        'Install',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _bgColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Dismiss
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 14.sp,
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
  }
}

// ─────────────────────────────────────────────
// iOS INSTALL BOTTOM SHEET
// ─────────────────────────────────────────────
class _IosInstallSheet extends StatelessWidget {
  final KorraAppVariant variant;
  final Color bgColor;

  const _IosInstallSheet({
    required this.variant,
    required this.bgColor,
  });

  bool get _isMerchant => variant == KorraAppVariant.merchant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36.w, height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          SizedBox(height: 28.h),

          // App icon
          Container(
            width: 64.w, height: 64.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Icon(Iconsax.mobile, color: Colors.white, size: 28.sp),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            _isMerchant ? 'Install Korra Business' : 'Install Korra',
            style: GoogleFonts.inter(
              fontSize: 18.sp, fontWeight: FontWeight.w700,
              color: const Color(0xFF0D0D0D), letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),

          // 🚀 THE CHROME VS SAFARI CHECK
          if (isIosNonSafari()) ...[
            Text(
              'Apple restricts app installation to Safari. To install Korra, please open your browser menu, copy the link, and paste it into Safari.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp, color: const Color(0xFFD92D20), // Red warning
                height: 1.5, fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 32.h),
            _buildStep(
              icon: Iconsax.copy,
              title: 'Copy the Website Link',
              desc: 'Tap your address bar and copy korra.com.ng',
            ),
            SizedBox(height: 16.h),
            _buildStep(
              icon: Iconsax.global,
              title: 'Open Safari',
              desc: 'Paste the link into Safari, then tap the Share icon to install.',
            ),
          ] else ...[
            Text(
              _isMerchant
                  ? 'Add Korra Business to your home screen for quick access.'
                  : 'Add Korra to your home screen and pay in parts anytime.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp, color: const Color(0xFF6B6B6B), height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            _buildStep(
              icon: Iconsax.export_3,
              title: 'Tap the Share button',
              desc: 'Find the share icon at the bottom of your Safari browser.',
            ),
            SizedBox(height: 16.h),
            _buildStep(
              icon: Iconsax.add_square,
              title: 'Add to Home Screen',
              desc: 'Scroll down in the share menu and tap "Add to Home Screen".',
            ),
          ],

          SizedBox(height: 32.h),

          // Close button
          SizedBox(
            width: double.infinity, height: 52.h,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D0D0D),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],     
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Icon(icon, color: bgColor, size: 18.sp),
          ),
        ),

        SizedBox(width: 14.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D0D0D),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF6B6B6B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
