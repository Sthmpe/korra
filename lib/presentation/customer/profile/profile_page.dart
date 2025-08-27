import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repository/customer/profile_repository.dart';
import '../../../logic/bloc/customer_shell/profile/profile_bloc.dart';
import '../../../logic/bloc/customer_shell/profile/profile_event.dart';
import '../../../logic/bloc/customer_shell/profile/profile_state.dart';
import '../../shared/notify/korra_notify.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/identity_header_card.dart';
import 'widgets/rows.dart';
import 'widgets/section_card.dart';

const _brand = Color(0xFFA54600);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(ProfileRepository())..add(ProfileStarted()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (p, c) => p.message != c.message && c.message != null,
        listener: (context, state) {
          if (state.message != null) {
            final msg = state.message;
            if (msg != null) {
              KorraNotify.info(context, msg);
            }
          }
        },
        builder: (context, state) {
          final bloc = context.read<ProfileBloc>();

          return Scaffold(
            appBar: const KorraHeader(title: 'Profile'),
            body: RefreshIndicator(
              onRefresh: () async => bloc.add(ProfileRefreshed()),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (state.status == ProfileStatus.loading)
                          Padding(
                            padding: EdgeInsets.only(top: 60.h),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (state.status == ProfileStatus.error)
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              state.error ?? 'Something went wrong',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFB3261E),
                              ),
                            ),
                          )
                        else ...[
                          // Identity
                          IdentityHeaderCard(
                            initials: state.initials,
                            name: state.name,
                            email: state.email,
                            phone: state.phone,
                            kycVerified: state.kycVerified,
                            basicTier: state.basicTier,
                            onEdit: () {}, // TODO
                          ),

                          // Wallet & payments
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wallet & payments',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E5E5E),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                RowWithChevron(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: state.walletBalanceText,
                                  subtitle: 'Wallet balance • Top up',
                                  onTap: () {}, // TODO
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                RowWithChevron(
                                  icon: Icons.credit_card,
                                  title: 'Default method',
                                  subtitle: state.defaultMethodMasked,
                                  onTap: () {}, // TODO
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                SwitchRow(
                                  icon: Icons.autorenew_rounded,
                                  title: 'AutoPay (default)',
                                  subtitle: 'Use AutoPay when available',
                                  value: state.autopayDefault,
                                  onChanged: (v) =>
                                      bloc.add(ToggleAutopayDefault(v)),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                RowWithChevron(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Statements & receipts',
                                  onTap: () {}, // TODO
                                ),
                              ],
                            ),
                          ),

                          // Preferences
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preferences',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E5E5E),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                SwitchRow(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Push notifications',
                                  value: state.pushNotif,
                                  onChanged: (v) =>
                                      bloc.add(TogglePushNotif(v)),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                SwitchRow(
                                  icon: Icons.email_outlined,
                                  title: 'Email notifications',
                                  value: state.emailNotif,
                                  onChanged: (v) =>
                                      bloc.add(ToggleEmailNotif(v)),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                SwitchRow(
                                  icon: Icons.sms_outlined,
                                  title: 'SMS notifications',
                                  value: state.smsNotif,
                                  onChanged: (v) => bloc.add(ToggleSmsNotif(v)),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reminders',
                                        style: GoogleFonts.inter(
                                          fontSize: 14.5.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Wrap(
                                        spacing: 8.w,
                                        children: [
                                          for (final c in const [
                                            'Same day',
                                            '1 day before',
                                            '3 days before',
                                          ])
                                            ChoiceChip(
                                              label: Text(
                                                c,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              selected:
                                                  state.reminderCadence == c,
                                              onSelected: (_) => bloc.add(
                                                ChangeReminderCadence(c),
                                              ),
                                              selectedColor: _brand,
                                              labelStyle: GoogleFonts.inter(
                                                color:
                                                    state.reminderCadence == c
                                                    ? Colors.white
                                                    : const Color(0xFF1B1B1B),
                                              ),
                                              backgroundColor: Colors.white,
                                              side: const BorderSide(
                                                color: Color(0xFFEAE6E2),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.brightness_6_outlined,
                                      size: 18.sp,
                                      color: _brand,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Theme',
                                            style: GoogleFonts.inter(
                                              fontSize: 14.5.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'Coming soon',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5.sp,
                                              color: const Color(0xFF5E5E5E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Security
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E5E5E),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                SwitchRow(
                                  icon: Icons.fingerprint,
                                  title: 'Biometric sign-in',
                                  value: state.biometricsEnabled,
                                  onChanged: (v) =>
                                      bloc.add(ToggleBiometrics(v)),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                RowWithChevron(
                                  icon: Icons.lock_outline,
                                  title: 'Change password',
                                  onTap: () {}, // TODO
                                ),
                              ],
                            ),
                          ),

                          // Support & legal
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Support & legal',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E5E5E),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                RowWithChevron(
                                  icon: Icons.help_outline,
                                  title: 'Help Center (FAQ)',
                                  onTap: () {}, // TODO
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                RowWithChevron(
                                  icon: Icons.description_outlined,
                                  title: 'Terms of Service',
                                  onTap: () {
                                    // TODO: show your existing Terms sheet
                                  },
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),
                                ),
                                RowWithChevron(
                                  icon: Icons.privacy_tip_outlined,
                                  title: 'Privacy Policy',
                                  onTap: () {
                                    // TODO: show your existing Privacy sheet
                                  },
                                ),
                              ],
                            ),
                          ),

                          // About
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5E5E5E),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                RowWithChevron(
                                  icon: Icons.info_outline,
                                  title: 'Version',
                                  subtitle: '1.0.0 (42)',
                                  onTap: () {},
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEAE6E2),    
                                ),
                                RowWithChevron(
                                  icon: Icons.balance_outlined,
                                  title: 'Open source licenses',
                                  onTap: () {}, // TODO
                                ),
                              ],
                            ),
                          ),

                          // Danger zone
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        bloc.add(LogoutRequested()),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size.fromHeight(48.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      side: const BorderSide(color: _brand),
                                    ),
                                    child: Text(
                                      'Logout',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _brand,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () =>
                                        _confirmDelete(context, bloc),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFB3261E),
                                      minimumSize: Size.fromHeight(48.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Delete account',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProfileBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete account',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This action is permanent. Your plans and data will be removed.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
