import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';
import '../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../logic/bloc/auth/role_login/role_login_state.dart';
import '../../customer/customer_shell.dart';
import '../../shared/widgets/korra_failure_sheet.dart';
import '../../vendor/vendor_shell.dart';
import 'widgets/biometric_button.dart';
import 'widgets/login_button.dart';
import 'widgets/login_fields.dart';
import 'widgets/login_header.dart';
import 'widgets/role_divider.dart';
import 'widgets/role_selector.dart';

class RoleLoginScreen extends StatelessWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return BlocProvider(
      create: (_) => RoleLoginBloc(),
      child: BlocListener<RoleLoginBloc, RoleLoginState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) async {
          if (state.status == LoginStatus.success) {
            final Widget destination =
                state.role == KorraRole.vendor ? VendorShell(uid: state.uid) : CustomerShell(uid: state.uid);
            // Using Get.offAll to prevent returning to the login screen.
            Get.offAll(() => destination);
          }

          if (state.status == LoginStatus.failure && state.failure != null) {
            showKorraFailureSheet(
              context,
              title: state.failure!.title,   // Map title from failure object
              message: state.failure!.message, // Map message from failure object
              onCancel: () {
                // Clear the error state when sheet closes
                context.read<RoleLoginBloc>().add(FailureAcknowledged());
              },
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
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
                  SizedBox(height: 50.h),
                  const RoleSelector(),
                  SizedBox(height: 40.h),
                  LoginFields(formKey: formKey),
                  //SizedBox(height: 16.h),
                  //const RoleDivider(),
                  //SizedBox(height: 40.h),
                  //const Center(child: BiometricButton()),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                KorraSizes.gutter.w,
                0,
                KorraSizes.gutter.w,
                14.h,
              ),
              child: LoginButton(formKey: formKey),
            ),
          ),
        ),
      ),
    );
  }
}
