import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/sizes.dart';
import '../../../logic/bloc/auth/forgot_password/forgot_password_bloc.dart';
import '../../../logic/bloc/auth/forgot_password/forgot_password_event.dart';
import '../../../logic/bloc/auth/forgot_password/forgot_password_state.dart';
import 'reset_link_sent_screen.dart';

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
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Text(
                'No worries. Enter your email and we’ll send a reset link.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 40.h),
              _EmailField(),
              SizedBox(height: 8.h),
              _InlineError(),
              const Spacer(),
              _PrimaryCTA(),
              SizedBox(height: 12.h),
              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Back to sign in',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
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
      style: GoogleFonts.inter(fontSize: 13.5.sp),
      textInputAction: TextInputAction.send,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Email address',
        labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
        prefixIcon: Icon(Iconsax.sms, size: 18.sp),
        errorStyle: GoogleFonts.inter(fontSize: 12.sp),
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
          Get.to(() => ResetLinkSentScreen(email: state.email));
        }
      },
      builder: (context, state) {
        final busy = state.status == FPStatus.submitting;
        final enabled = state.isValid && !busy;
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: enabled
                ? () => context.read<ForgotPasswordBloc>().add(const FPSubmit())
                : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
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
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
