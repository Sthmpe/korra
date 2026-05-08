import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Make sure your imports match your project structure!
import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';
import '../../../config/constants/image_string.dart';
import '../../../flavors/app_config.dart';
import '../../shared/widgets/korra_failure_sheet.dart';
import 'widgets/login_header.dart';
// import 'widgets/login_header.dart'; // Keep your header import

class RoleLoginScreen extends StatelessWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get Role from Flavor
    final isVendor = AppConfig.isVendor;
    final flavorRole = isVendor ? KorraRole.vendor : KorraRole.customer;

    return BlocProvider(
      // ✅ AUTO-SELECT ROLE: Sets the role immediately based on the app flavor
      create: (_) => RoleLoginBloc()..add(RoleSelected(flavorRole)),
      child: BlocListener<RoleLoginBloc, RoleLoginState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) async {
          
          // --- SUCCESS ROUTING ---
          if (state.status == LoginStatus.success) {
            if (state.isNewUser) {
              // 🚀 NEW USER: Send to Frictionless Signup Form
              Get.offAllNamed(
                state.role == KorraRole.vendor 
                    ? Routes.vendorSignup 
                    : Routes.customerSignup,
              );
            } else {
              // 🚀 EXISTING USER: Send straight to the Dashboard
              Get.offAllNamed(
                state.role == KorraRole.vendor 
                    ? Routes.vendorShell 
                    : Routes.customerShell,
              );
            }
          }

          // --- FAILURE HANDLING ---
          if (state.status == LoginStatus.failure && state.failure != null) {
            showKorraFailureSheet(
              context,
              title: state.failure!.title,
              message: state.failure!.message,
              onCancel: () {
                context.read<RoleLoginBloc>().add(FailureAcknowledged());
              },
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: KorraSizes.gutter.w,
                  vertical: 40.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoginHeader(), 
                    
                    SizedBox(height: 40.h),
              
                    // --- 🚀 SINGLE ONE-CLICK GOOGLE BUTTON ---
                    BlocBuilder<RoleLoginBloc, RoleLoginState>(
                      buildWhen: (previous, current) => previous.status != current.status,
                      builder: (context, state) {
                        final isLoading = state.status == LoginStatus.submitting;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: OutlinedButton(
                            onPressed: isLoading 
                                ? null 
                                : () => context.read<RoleLoginBloc>().add(GoogleLoginPressed()),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              backgroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    height: 24.h, 
                                    width: 24.h, 
                                    child: const CircularProgressIndicator(strokeWidth: 2, color: KorraColors.brand),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        ImageString.gooogleLogoPng,
                                        height: 34.h,
                                        width: 34.h,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.inter(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1B1B1B),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }
                    ),
                    
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
