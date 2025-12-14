import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/models/customer/customer_ui_extentsion.dart';

// REPO & MODELS
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';

// BLOC
import '../../../data/models/customer/cutomer_limit.dart';
import '../../../logic/services/share_service.dart';
import '../../../logic/bloc/customer/profile/profile_bloc.dart';
import '../../../logic/bloc/customer/profile/profile_event.dart';
import '../../../logic/bloc/customer/profile/profile_state.dart';
import '../../../logic/core/net/net_cubit.dart';

// WIDGETS
import '../../auth/role_login/role_login_screen.dart';
import '../../shared/notify/korra_notify.dart';
import '../../shared/widgets/korra_header.dart';
import 'bank_details_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'legal_screen.dart';
import 'limit_upgrade_screen.dart';
import 'liveness.dart';
import 'statements_screen.dart';
import 'widgets/identity_header_card.dart';
import 'my_qr_screen.dart';
import 'widgets/rows.dart';
import 'widgets/section_card.dart';

const _brand = Color(0xFFA54600);

class ProfilePage extends StatelessWidget {
  final CustomerRepository customerRepo;
  final String customerUid;

  const ProfilePage({
    super.key,
    required this.customerRepo,
    required this.customerUid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        customerRepo: customerRepo,
        net: context.read<NetCubit>(),
      ),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.message != null) KorraNotify.info(context, state.message!);
          if (state.status == ProfileStatus.logout)
            Get.offAll(() => const RoleLoginScreen());
        },
        // REAL-TIME DATA STREAM
        child: StreamBuilder<Customer?>(
          stream: customerRepo.streamCustomer(customerUid),
          builder: (context, snapshot) {
            final bloc = context.read<ProfileBloc>();

            // 1. LOADING
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: _brand)),
              );
            }

            final customer = snapshot.data;

            // 2. ERROR / NO DATA
            if (customer == null) {
              return const Scaffold(
                body: Center(child: Text("Profile not found")),
              );
            }

            // 3. SUCCESS UI
            return StreamBuilder<CustomerLimit?>(
              stream: customerRepo.streamCustomerLimit(customerUid),
              builder: (context, limitSnap) {
                final limitData = limitSnap.data;
                final totalLimit = limitData?.totalCreditLimit ?? 15000.0;
                final activeDebt = limitData?.activeDebt ?? 0.0;

                return Scaffold(
                  backgroundColor: const Color(0xFFF9FAFB),
                  appBar: const KorraHeader(title: 'Profile'),
                  body: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // IDENTITY CARD (Using Extension Getters)
                            IdentityHeaderCard(
                              initials: customer.initials, // 👈 Extension
                              name: customer.displayName, // 👈 Extension
                              email: customer.email,
                              phone: customer.phone,
                              kycVerified:
                                  customer.isFullyVerified, // 👈 Extension
                              basicTier: true,
                              onMyQr: () {
                                Get.to(() => MyQrScreen(customer: customer));
                              },
                              onShare: () {
                                ShareService.shareAppReferral(
                                  referrerName: customer.firstName,
                                );
                              },
                              onEdit: () {
                                Get.to(
                                  () => EditProfileScreen(
                                    customer:
                                        customer, // Pass the current customer data
                                    repo: customerRepo, // Pass the repo
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 16.h),

                            // WALLET SECTION
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('Wallet & payments'),
                                  SizedBox(height: 6.h),

                                  // Bank Details (Real Data from Extension)
                                  RowWithChevron(
                                    icon: Icons.account_balance_rounded,
                                    title: 'Bank Details',
                                    subtitle:
                                        customer.bankDisplay, // 👈 Extension
                                    onTap: () {
                                      Get.to(
                                        () => BankDetailsScreen(
                                          customer: customer,
                                        ),
                                      );
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Liveness',
                                    onTap: () {
                                      Get.to(
                                        () => LivenessScreen(
                                          onVerificationSuccess: (base64Image) {
                                            print(
                                              "Success! Image data length: ${base64Image.length}",
                                            );
                                            // Send to Firebase/Backend here
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                  ),

                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons
                                        .trending_up, // Use an "Upgrade" icon
                                    title: 'Increase Limit',
                                    subtitle: 'Check your buying power',
                                    onTap: () {
                                      Get.to(
                                        () => LimitUpgradeScreen(
                                          repo: customerRepo,
                                          customer: customer,
                                          currentTotalLimit: totalLimit,
                                          activeDebt: activeDebt,
                                        ),
                                      );
                                    },
                                  ),
                                  _divider(),

                                  // AutoPay (Disabled)
                                  SwitchRow(
                                    icon: Icons.autorenew_rounded,
                                    title: 'AutoPay',
                                    subtitle: 'Coming soon',
                                    value: false,
                                    onChanged: (_) => KorraNotify.info(
                                      context,
                                      "Coming soon!",
                                    ),
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Statements & receipts',
                                    onTap: () {
                                      Get.to(
                                        () => StatementsScreen(
                                          repo: customerRepo,
                                          customerUid: customerUid,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // PREFERENCES
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('Preferences'),
                                  SizedBox(height: 6.h),

                                  RowWithChevron(
                                    icon: Icons.brightness_6_outlined,
                                    title: 'App Theme',
                                    subtitle: 'Coming soon',
                                    onTap: () => KorraNotify.info(
                                      context,
                                      "Themes are coming soon!",
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. SECURITY & LEGAL
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('Security'),
                                  SizedBox(height: 6.h),

                                  SwitchRow(
                                    icon: Icons.fingerprint,
                                    title: 'Biometric Sign-in',
                                    subtitle: 'Coming soon',
                                    value: false,
                                    onChanged: (v) {
                                      KorraNotify.info(
                                        context,
                                        "Biometrics coming soon!",
                                      );
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.lock_outline,
                                    title: 'Change password',
                                    onTap: () {
                                      Get.to(
                                        () => ChangePasswordScreen(
                                          repo: customerRepo,
                                        ),
                                      );
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.description_outlined,
                                    title: 'Legal & Privacy',
                                    onTap: () {
                                      Get.to(() => const LegalMenuScreen());
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // HELP CENTER
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('Help Center'),
                                  SizedBox(height: 6.h),

                                  RowWithChevron(
                                    icon: Icons.question_mark_outlined,
                                    title: 'Help Center',
                                    onTap: () {
                                      Get.to(() => const HelpCenterScreen());
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // LOGOUT
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                16.h,
                                16.w,
                                40.h,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50.h,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          bloc.add(LogoutRequested()),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFFD0D5DD),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        foregroundColor: const Color(
                                          0xFF344054,
                                        ),
                                      ),
                                      child: Text(
                                        'Log out',
                                        style: GoogleFonts.inter(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(context, bloc),
                                    child: Text(
                                      "Delete account",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF98A2B3),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 24.h, color: const Color(0xFFF2F4F7), thickness: 1);
  }

  void _confirmDelete(BuildContext context, ProfileBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.red,
          ),
        ),
        content: Text(
          'This action is permanent and cannot be undone.\n\n'
          'Note: You cannot delete your account if you have any active plans or unpaid debts.',
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Account',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              bloc.add(DeleteAccountRequested());
            },
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
