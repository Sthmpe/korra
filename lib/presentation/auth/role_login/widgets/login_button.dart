import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../../logic/bloc/auth/role_login/role_login_state.dart';

class LoginButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const LoginButton({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleLoginBloc, RoleLoginState>(
      builder: (context, state) {
        final isLoading = state.loading;
        final role = state.role;

        return Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            color: isLoading
                ? KorraColors.brand.withOpacity(0.5)
                : KorraColors.brand,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: KorraColors.brand.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: isLoading
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      if (formKey.currentState?.validate() ?? false) {
                        context.read<RoleLoginBloc>().add(SubmitPressed());
                      }
                    },
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : AutoSizeText(
                        role == KorraRole.vendor
                            ? 'Sign in as Vendor'
                            : 'Sign in as Customer',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
