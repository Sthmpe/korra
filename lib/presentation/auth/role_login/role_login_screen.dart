import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:korra/presentation/auth/role_login/widgets/login_button.dart';

// import '../../../config/constants/colors.dart';
import '../../../config/constants/sizes.dart';
import '../../../logic/bloc/auth/role_login/role_login_bloc.dart';
// import '../../../logic/bloc/auth/role_login/role_login_event.dart';
// import '../../../logic/bloc/auth/role_login/role_login_state.dart';

// import '../../customer/customer_shell.dart';
// import '../../vendor/vendor_shell.dart';
import 'widgets/login_header.dart';
import 'widgets/role_selector.dart';
import 'widgets/role_divider.dart';
import 'widgets/login_fields.dart';
import 'widgets/biometric_button.dart';

class RoleLoginScreen extends StatelessWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return BlocProvider(
      create: (_) => RoleLoginBloc(),
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
                LoginFields(formKey: formKey), // ⬅ Pass formKey here
                SizedBox(height: 16.h),
                RoleDivider(),
                SizedBox(height: 40.h),
                const Center(child: BiometricButton()),
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
            child: LoginButton(formKey: formKey), // ⬅ Same formKey
          ),
        ),
      ),
    );
  }
}
