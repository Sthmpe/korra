import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../logic/cubit/vendor/vendor_profile_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/vendor_identity_header_card.dart';
import 'widgets/v_section_card.dart';
import 'widgets/v_rows.dart';

class VendorProfilePage extends StatelessWidget {
  const VendorProfilePage({super.key});

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorProfileCubit()..load(),
      child: BlocBuilder<VendorProfileCubit, VendorProfileState>(
        builder: (context, s) {
          final cubit = context.read<VendorProfileCubit>();

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const KorraHeader(title: 'Profile'),
            body: s.loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Identity header with quick actions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(12.r),
                          child: VendorIdentityHeaderCard(
                            name: s.name,
                            email: s.email,
                            phone: s.phone,
                            verified: s.verified,
                            tier: s.tier,
                            onEdit: () {},         // TODO: wire
                            onShowQr: () {},
                            onShareHandle: () {},
                          ),
                        ),
                      ),

                      // Wallet & payments
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: VSectionCard(
                            title: 'Wallet & payments',
                            children: [
                              VRowNav(
                                icon: Iconsax.wallet_3,
                                title: s.walletBalanceText,
                                subtitle: 'Wallet balance • Top up',
                                onTap: () {},
                              ),
                              VDivider(),
                              VRowNav(
                                icon: Iconsax.card,
                                title: 'Default method',
                                subtitle: s.defaultMethodMasked,
                                onTap: () {},
                              ),
                              VDivider(),
                              VRowSwitch(
                                icon: Iconsax.refresh_left_square,
                                title: 'AutoPay (default)',
                                subtitle: 'Use AutoPay when available',
                                value: s.autoPay,
                                onChanged: cubit.toggleAutoPay,
                              ),
                              VDivider(),
                              VRowNav(
                                icon: Iconsax.document_text,
                                title: 'Statements & receipts',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Preferences
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
                          child: VSectionCard(
                            title: 'Preferences',
                            children: [
                              VRowSwitch(
                                icon: Iconsax.notification,
                                title: 'Push notifications',
                                value: s.push,
                                onChanged: cubit.togglePush,
                              ),
                              VDivider(),
                              VRowSwitch(
                                icon: Iconsax.sms_tracking,
                                title: 'Email notifications',
                                value: s.emailNotif,
                                onChanged: cubit.toggleEmail,
                              ),
                              VDivider(),
                              VRowSwitch(
                                icon: Iconsax.message_question,
                                title: 'SMS notifications',
                                value: s.sms,
                                onChanged: cubit.toggleSms,
                              ),
                              VDivider(space: 14.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                child: Text('Reminders',
                                  style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800)),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                                child: Wrap(spacing: 10.w, runSpacing: 10.h, children: [
                                  VRadioPill(
                                    selected: s.reminderDays == 0,
                                    text: 'Same day',
                                    onTap: () => cubit.setReminder(0),
                                  ),
                                  VRadioPill(
                                    selected: s.reminderDays == 1,
                                    text: '1 day before',
                                    leadingCheck: true,
                                    onTap: () => cubit.setReminder(1),
                                  ),
                                  VRadioPill(
                                    selected: s.reminderDays == 3,
                                    text: '3 days before',
                                    onTap: () => cubit.setReminder(3),
                                  ),
                                ]),
                              ),
                              VDivider(),
                              VRowLabel(
                                icon: Iconsax.brush_4,
                                title: 'Theme',
                                trailingText: 'Coming soon',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Security
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
                          child: VSectionCard(
                            title: 'Security',
                            children: [
                              VRowSwitch(
                                icon: Iconsax.finger_scan,
                                title: 'Biometric sign-in',
                                value: s.biometric,
                                onChanged: cubit.toggleBio,
                              ),
                              VDivider(),
                              VRowNav(
                                icon: Iconsax.lock,
                                title: 'Change password',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Support & legal
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
                          child: VSectionCard(
                            title: 'Support & legal',
                            children: [
                              VRowNav(icon: Iconsax.info_circle, title: 'Help Center (FAQ)', onTap: () {}),
                              VDivider(),
                              VRowNav(icon: Iconsax.document_text_1, title: 'Terms of Service', onTap: () {}),
                              VDivider(),
                              VRowNav(icon: Iconsax.shield_tick, title: 'Privacy Policy', onTap: () {}),
                            ],
                          ),
                        ),
                      ),

                      // About
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
                          child: VSectionCard(
                            title: 'About',
                            children: [
                              VRowNav(
                                icon: Iconsax.information,
                                title: 'Version',
                                trailingText: s.versionText,
                                onTap: () {},
                              ),
                              VDivider(),
                              VRowNav(
                                icon: Icons.scale,
                                title: 'Open source licenses',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Logout / Delete account
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 22.h),
                          child: Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _brand),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  foregroundColor: _brand,
                                ),
                                child: Text('Logout',
                                  style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                ),
                                child: Text('Delete account',
                                  style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
