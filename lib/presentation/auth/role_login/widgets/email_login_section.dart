import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/theme/gaps.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';

/// Collapsed by default: a subtle "or sign in with email" link under the
/// Google button. Expands into email + password fields — LOGIN ONLY, there is
/// deliberately no email signup path (accounts are created with Google).
class EmailLoginSection extends StatefulWidget {
  const EmailLoginSection({super.key});

  @override
  State<EmailLoginSection> createState() => _EmailLoginSectionState();
}

class _EmailLoginSectionState extends State<EmailLoginSection> {
  bool _expanded = false;

  InputDecoration _decoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: KorraSizes.fontMd.sp,
        color: KorraColors.textSecondary,
      ),
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        borderSide: const BorderSide(color: KorraColors.borderCool),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        borderSide: const BorderSide(color: KorraColors.brand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'hide email sign in' : 'or sign in with email',
              style: GoogleFonts.inter(
                fontSize: KorraSizes.fontSm.sp,
                fontWeight: KorraSizes.weightMedium,
                color: KorraColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        if (_expanded)
          BlocBuilder<RoleLoginBloc, RoleLoginState>(
            builder: (context, state) {
              final isLoading = state.status == LoginStatus.submitting;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gaps.h12,
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !isLoading,
                    onChanged: (v) =>
                        context.read<RoleLoginBloc>().add(EmailChanged(v)),
                    style: GoogleFonts.inter(fontSize: KorraSizes.fontMd.sp),
                    decoration: _decoration('Email address'),
                  ),
                  Gaps.h12,
                  TextField(
                    obscureText: state.passwordHidden,
                    enabled: !isLoading,
                    onChanged: (v) =>
                        context.read<RoleLoginBloc>().add(PasswordChanged(v)),
                    style: GoogleFonts.inter(fontSize: KorraSizes.fontMd.sp),
                    decoration: _decoration(
                      'Password',
                      suffixIcon: IconButton(
                        onPressed: () => context
                            .read<RoleLoginBloc>()
                            .add(TogglePasswordVisibility()),
                        icon: Icon(
                          state.passwordHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20.h,
                          color: KorraColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Gaps.h16,
                  SizedBox(
                    height: 54.h,
                    child: FilledButton(
                      onPressed: (isLoading || !state.isFormValid)
                          ? null
                          : () => context
                              .read<RoleLoginBloc>()
                              .add(SubmitPressed()),
                      style: FilledButton.styleFrom(
                        backgroundColor: KorraColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(KorraSizes.cardRadius.r),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24.h,
                              width: 24.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KorraColors.white,
                              ),
                            )
                          : Text(
                              'Sign in',
                              style: GoogleFonts.inter(
                                fontSize: KorraSizes.fontMdPlus.sp,
                                fontWeight: KorraSizes.weightSemiBold,
                                color: KorraColors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
