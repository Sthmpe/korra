import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/constants/buttons.dart';
import '../../../config/constants/colors.dart';
import '../../../config/constants/icons.dart';
import '../../../config/constants/sizes.dart';
import '../../../config/theme/gaps.dart';
import '../../../config/routes/app_routes.dart';
import '../../../logic/bloc/auth/forgot_password/forgot_password_bloc.dart';
import '../../../logic/bloc/auth/forgot_password/forgot_password_event.dart';
import '../../../logic/bloc/auth/forgot_password/forgot_password_state.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            'Forgot password?',
            style: GoogleFonts.inter(
              fontSize: KorraSizes.fontLg.sp,
              fontWeight: KorraSizes.weightBold,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gaps.h8,
              Text(
                'No worries. Enter your email and we’ll send a reset link.',
                style: GoogleFonts.inter(
                  fontSize: KorraSizes.fontMd.sp,
                  fontWeight: KorraSizes.weightMedium,
                ),
              ),
              Gaps.h40,
              _EmailField(),
              Gaps.h8,
              _InlineError(),
              const Spacer(),
              _PrimaryCTA(),
              Gaps.h12,
              Center(
                child: TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Get.back();
                  },
                  child: Text(
                    'Back to sign in',
                    style: GoogleFonts.inter(
                      fontSize: KorraSizes.fontMd.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Gaps.h20,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  // final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  _EmailField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(fontSize: KorraSizes.fontSmPlusH.sp),
      textInputAction: TextInputAction.send,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Email address',
        labelStyle: GoogleFonts.inter(fontSize: KorraSizes.fontSmPlusH.sp),
        prefixIcon: Icon(KorraIcons.email, size: KorraSizes.fontXl.sp),
        errorStyle: GoogleFonts.inter(fontSize: KorraSizes.fontSm.sp),
      ),
      onChanged: (v) =>
          context.read<ForgotPasswordBloc>().add(FPEmailChanged(v)),
      onSubmitted: (_) =>
          context.read<ForgotPasswordBloc>().add(const FPSubmit()),
    );
  }
}

// TextFormField(
//             controller: _emailCtl,
//             keyboardType: TextInputType.emailAddress,
//             style: GoogleFonts.inter(fontSize: 13.5.sp),
//             autofillHints: const [AutofillHints.username, AutofillHints.email],
//             decoration: InputDecoration(
//               labelText: 'Email address',
//               labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
//               prefixIcon: Icon(Iconsax.sms, size: 18.sp),
//               errorStyle: GoogleFonts.inter(fontSize: 12.sp),
//             ),
//             validator: _validateEmail,
//             textInputAction: TextInputAction.next,
//           ),

class _InlineError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      buildWhen: (p, c) => p.status != c.status || p.error != c.error,
      builder: (context, state) {
        if (state.status == FPStatus.error && state.error != null) {
          return Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PrimaryCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FPStatus.sent) {
          Get.toNamed(
            Routes.resetLinkSent,
            arguments: {'email': state.email},
          );
        }
      },
      builder: (context, state) {
        final busy = state.status == FPStatus.submitting;
        final enabled = state.isValid && !busy;
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: enabled
                ? () {
                    FocusScope.of(context).unfocus();
                    context.read<ForgotPasswordBloc>().add(const FPSubmit());
                  }
                : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: KorraSizes.s14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
              ),
            ),
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Send reset link',
                    style: GoogleFonts.inter(
                      fontSize: KorraSizes.fontLg.sp,
                      fontWeight: KorraSizes.weightBold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
