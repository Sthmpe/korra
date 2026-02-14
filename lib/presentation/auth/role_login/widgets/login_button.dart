import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';

class LoginButton extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const LoginButton({super.key, required this.formKey});

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05, // Shrink by 5%
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleLoginBloc, RoleLoginState>(
      builder: (context, state) {
        final isLoading = state.loading; // Use your actual loading state getter
        final role = state.role;

        return GestureDetector(
          onTapDown: isLoading ? null : _onTapDown,
          onTapUp: isLoading ? null : _onTapUp,
          onTapCancel: isLoading ? null : _onTapCancel,
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  FocusScope.of(context).unfocus();
                  if (widget.formKey.currentState?.validate() ?? false) {
                    context.read<RoleLoginBloc>().add(SubmitPressed());
                  }
                },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  color: isLoading 
                      ? KorraColors.brand.withOpacity(0.7) 
                      : KorraColors.brand,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: isLoading
                      ? [] // No shadow when loading/flat
                      : [
                          BoxShadow(
                            color: KorraColors.brand.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : AutoSizeText(
                          role == KorraRole.vendor
                              ? 'Sign in as Merchant'
                              : 'Sign in as Customer',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}