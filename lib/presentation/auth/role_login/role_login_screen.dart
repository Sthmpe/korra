import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../config/constants/sizes.dart';
import '../../../config/routes/app_routes.dart';
import '../../../flavors/app_config.dart';
import '../../../logic/bloc/auth/role_login/role_login_bloc.dart';
import '../../../logic/bloc/auth/role_login/role_login_event.dart';
import '../../../logic/bloc/auth/role_login/role_login_state.dart';
import '../../shared/widgets/korra_failure_sheet.dart';
import 'widgets/login_button.dart';
import 'widgets/login_fields.dart';
import 'widgets/login_header.dart';
//import 'widgets/role_selector.dart';

class RoleLoginScreen extends StatelessWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    // 1. Get Role from Flavor
    final isVendor = AppConfig.isVendor;
    final flavorRole = isVendor ? KorraRole.vendor : KorraRole.customer;

    return BlocProvider(
      // ✅ AUTO-SELECT ROLE: We set the role immediately so the logic works same as before
      create: (_) => RoleLoginBloc()..add(RoleSelected(flavorRole)),
      child: BlocListener<RoleLoginBloc, RoleLoginState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) async {
          if (state.status == LoginStatus.success) {
            // ✅ NAVIGATION: Go to correct shell based on Flavor
            if (isVendor) {
              Get.offAllNamed(Routes.vendorShell);
            } else {
              Get.offAllNamed(Routes.customerShell);
            }
          }

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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: KorraSizes.gutter.w,
                vertical: 40.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoginHeader(), // We can tweak the text inside this widget later if needed
                  SizedBox(height: 50.h),
                  
                  // 🗑️ RoleSelector() REMOVED
                  
                  LoginFields(formKey: formKey),
                  
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoginButton(formKey: formKey),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}