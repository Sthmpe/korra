import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/models/customer/customer_ui_extentsion.dart';

// REPO & MODELS
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';

// BLOC
import '../../../config/routes/app_routes.dart';
import '../../../data/models/customer/customer_account_stats.dart';
import '../../../logic/services/share_service.dart';
import '../../../logic/bloc/customer/profile/profile_bloc.dart';
import '../../../logic/bloc/customer/profile/profile_event.dart';
import '../../../logic/bloc/customer/profile/profile_state.dart';
import '../../../logic/core/net/net_cubit.dart';

// WIDGETS
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
// import 'liveness.dart';
import 'widgets/identity_header_card.dart';
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
        uid: customerUid,
      ),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.message != null) showAppSnackbar(state.message!, SnackbarType.info);
          if (state.status == ProfileStatus.logout) {
            Get.offAllNamed(Routes.roleLoginScreen);
          }
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
            return StreamBuilder<CustomerAccountStats?>(
              stream: customerRepo.streamCustomerStats(customerUid),
              builder: (context, limitSnap) {

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
                                Get.toNamed(Routes.customerQr, arguments: customer);
                              },
                              onShare: () {
                                ShareService.shareAppReferral(
                                  referrerName: customer.firstName,
                                );
                              },
                              onEdit: () {
                                Get.toNamed(
                                  Routes.customerEditProfile,
                                  arguments: {
                                    'customer': customer,
                                    'repo': customerRepo,
                                  }
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
                                      Get.toNamed(Routes.customerBankDetails, arguments: customer);
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.store_mall_directory_outlined,
                                    title: 'My Store Balance',
                                    subtitle: 'View your store balance',
                                    onTap: () {
                                      Get.toNamed(
                                        Routes.customerStoreCredits, 
                                        arguments: {'uid': customerUid}
                                      );
                                    },
                                  ),
                                  _divider(),

                                  // RowWithChevron(
                                  //   icon: Icons.receipt_long_outlined,
                                  //   title: 'Liveness',
                                  //   onTap: () {
                                  //     // Get.toNamed(
                                  //   Routes.customerLiveness,
                                  //   arguments: {
                                  //     'onSuccess': (base64Image) {
                                  //        print("Success! $base64Image");
                                  //        Navigator.pop(context);
                                  //     }
                                  //   }
                                  // );
                                  //   },
                                  // ),

                                  // _divider(),

                                  StreamBuilder(
                                    stream: customerRepo.streamCustomerStats(
                                      customer.uid,
                                    ),
                                    builder: (context, snapshot) {
                                      // 2. Define 'stats' safely (Default to empty if loading)
                                      final stats =
                                          snapshot.data ??
                                          CustomerAccountStats.empty(
                                            customer.uid,
                                          );
                                      return RowWithChevron(
                                        icon: Iconsax.trend_up,
                                        title:
                                            'Level Up Slots', // Updated title
                                        subtitle:
                                            'Unlock more reservation slots', // Updated subtitle
                                        onTap: () {
                                          Get.toNamed(
                                            Routes.customerLimitUpgrade,
                                            arguments: {
                                              'repo': customerRepo,
                                              'customer': customer,
                                              'currentMaxSlots': stats.maxSlots,
                                              'completedPlansCount': stats.completedPlansCount,
                                            }
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Iconsax.shop,
                                    title: 'My Merchants',
                                    subtitle: 'Merchants you interact with',
                                    onTap: () => Get.toNamed(
                                      Routes.customerMyVendors, 
                                      arguments: {'uid': customer.uid}
                                    ),
                                  ),
                                  _divider(),

                                  // AutoPay (Disabled)
                                  SwitchRow(
                                    icon: Icons.autorenew_rounded,
                                    title: 'AutoPay',
                                    subtitle: 'Coming soon',
                                    value: false,
                                    onChanged: (_) => showAppSnackbar('Coming soon!', SnackbarType.info)
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Statements & receipts',
                                    onTap: () {
                                      Get.toNamed(
                                        Routes.customerStatements,
                                        arguments: {
                                          'repo': customerRepo,
                                          'uid': customerUid,
                                        }
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
                                    onTap: () => showAppSnackbar(
                                      "Themes are coming soon!",
                                      SnackbarType.info,
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
                                      showAppSnackbar(
                                        "Biometrics coming soon!",
                                        SnackbarType.info,
                                      );
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.lock_outline,
                                    title: 'Change password',
                                    onTap: () {
                                      Get.toNamed(
                                        Routes.customerChangePassword,
                                        arguments: {'repo': customerRepo}
                                      );
                                    },
                                  ),
                                  _divider(),

                                  RowWithChevron(
                                    icon: Icons.description_outlined,
                                    title: 'Legal & Privacy',
                                    onTap: () {
                                      Get.toNamed(Routes.customerLegal);
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
                                      Get.toNamed(Routes.customerHelp);
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
                                      onPressed: () => _confirmLogout(context, bloc),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: const Color(0xFFD0D5DD).withOpacity(0.5),
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

   // --- ACTIONS ---

  void _confirmLogout(BuildContext context, ProfileBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Log out', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Perform logout via Auth Bloc or Repository
              Navigator.pop(context);
              bloc.add(LogoutRequested());
            },
            child: const Text("Log out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProfileBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.red),
        ),
        content: Text(
          'This action is permanent and cannot be undone.\n\n'
          'Note: You cannot delete your account if you have active orders or pending payouts.',
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            onPressed: () {
              Navigator.of(context).pop();
              // bloc.add(DeleteAccountRequested());
              // Trigger Delete Logic
              showAppSnackbar("Contact support to delete account.", SnackbarType.info);
            },
            child: Text('Delete Permanently', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}