import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/vendors/vendor_repository.dart';
import 'package:korra/logic/bloc/vendor/profile/profile_state.dart';
import 'package:korra/presentation/shared/widgets/korra_header.dart';

// --- WIDGET IMPORTS (From your snippets) ---
import '../../../config/routes/app_routes.dart';
import '../../../data/models/vendor/vendor_model.dart';
import '../../../logic/bloc/vendor/profile/profile_bloc.dart';
import '../../../logic/bloc/vendor/profile/profile_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import 'widgets/identity_header_card.dart';
import 'widgets/section_card.dart';
import 'widgets/rows.dart';
// For logout navigation

// --- MODEL ---
// import 'path/to/vendor_model.dart'; 

const _brand = Color(0xFFA54600);

class VendorProfilePage extends StatelessWidget {
  final VendorRepository vendors;
  final String vendorUid;

  const VendorProfilePage({
    super.key, 
    required this.vendors, 
    required this.vendorUid
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        vendorRepo: vendors,
        net: context.read<NetCubit>(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: KorraHeader(title:  'Profile'),
        body: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.message != null) showAppSnackbar(state.message!, SnackbarType.info);
            if (state.status == ProfileStatus.logout) {
              Get.offAllNamed(Routes.roleLoginScreen);
            }
          },
          child: StreamBuilder<Vendor?>(
            stream: vendors.streamVendor(vendorUid), 
            builder: (context, snapshot) {
              final bloc = context.read<ProfileBloc>();

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _brand));
              }
                
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Text("Vendor profile not found.", style: GoogleFonts.inter(color: Colors.grey)),
                );
              }
                
              final vendor = snapshot.data!;
                
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 1. HEADER (WIRED UP) ---
                    IdentityHeaderCard(
                      initials: vendor.storeName.isNotEmpty ? vendor.storeName[0] : 'V',
                      name: vendor.storeName,
                      email: vendor.email,
                      phone: vendor.phone,
                      kycVerified: vendor.ninVerified && vendor.bvnVerified,
                      basicTier: false,
                      onEdit: () {
                        // Navigate to Edit Profile
                        // Get.to(() => EditVendorProfileScreen(vendor: vendor));
                        showAppSnackbar("Edit Profile coming soon!", SnackbarType.info);
                      },
                      onShare: () {
                         // Share Logic
                         showAppSnackbar("Sharing coming soon!", SnackbarType.info);
                      },
                      onMyQr: () {
                        // Navigate to Vendor QR
                        // Get.to(() => VendorQrScreen(vendor: vendor));
                        showAppSnackbar("QR Code coming soon!", SnackbarType.info);
                      },
                    ),
                
                    SizedBox(height: 16.h),
                
                    // --- 2. BUSINESS INFO ---
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Business Details'),
                          SizedBox(height: 12.h),
                
                          _StaticInfoRow(
                            icon: Iconsax.briefcase,
                            title: 'Legal Name',
                            value: vendor.legalName,
                          ),
                          _divider(),
                          
                          _StaticInfoRow(
                            icon: Iconsax.document,
                            title: 'CAC Number',
                            value: vendor.cac.isNotEmpty ? vendor.cac : "Not Provided",
                          ),
                          _divider(),
                
                          _StaticInfoRow(
                            icon: Iconsax.verify,
                            title: 'Status',
                            value: vendor.status.toUpperCase(),
                            valueColor: _getStatusColor(vendor.status),
                          ),
                          _divider(),
                
                          _StaticInfoRow(
                            icon: Iconsax.category,
                            title: 'Categories',
                            value: vendor.categories.join(", "),
                          ),
                        ],
                      ),
                    ),
                
                    // --- 3. LOCATION ---
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Location & Contact'),
                          SizedBox(height: 12.h),
                
                          _StaticInfoRow(
                            icon: Iconsax.location,
                            title: 'Address',
                            // FIX: Logic for missing address
                            value: vendor.address.isNotEmpty ? vendor.address : "Not Available",
                            subtitle: vendor.city.isNotEmpty 
                                ? "${vendor.city}, ${vendor.stateName}" 
                                : null,
                          ),
                          
                          if (vendor.mapsLink.isNotEmpty) ...[
                            _divider(),
                            RowWithChevron(
                              icon: Iconsax.map,
                              title: 'View on Maps',
                              subtitle: 'Open Google Maps',
                              onTap: () {
                                // launchUrl(Uri.parse(vendor.mapsLink));
                              },
                            ),
                          ]
                        ],
                      ),
                    ),
                
                    // --- 4. PREFERENCES (ADDED) ---
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
                
                    // ====================================================
                    // 🆕 NEW FINANCE SECTION (Call Settlement Screen)
                    // ====================================================
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Finance'),
                          SizedBox(height: 12.h),
                
                          RowWithChevron(
                            icon: Iconsax.wallet_1, // Good icon for finance
                            title: 'Settlements & Ledger',
                            subtitle: 'Earnings, vault & history',
                            onTap: () {
                              // 🚀 NAVIGATE TO SETTLEMENT SCREEN
                              Get.toNamed(
                                Routes.vendorSettlement,
                                arguments: {
                                  'repo': vendors,
                                  'uid': vendorUid,
                                },
                              );
                            }
                          ),
                          
                          _divider(),
                
                          RowWithChevron(
                            icon: Iconsax.bank,
                            title: 'Payout Details',
                            subtitle: 'Manage bank account',
                            onTap: () {
                              // Future: Navigate to Payout Settings
                              showAppSnackbar("Payout settings coming soon!", SnackbarType.info);
                            },
                          ),
                        ],
                      ),
                    ),
                
                    // --- 5. SECURITY & LEGAL (ADDED) ---
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
                              showAppSnackbar("Biometrics coming soon!", SnackbarType.info);
                            },
                          ),
                          _divider(),
                          RowWithChevron(
                            icon: Icons.lock_outline,
                            title: 'Change password',
                            onTap: () {
                                       Get.toNamed(
                                        Routes.vendorChangePassword,
                                        arguments: {'repo': vendors},
                                      );
                                    },
                          ),
                          _divider(),
                          RowWithChevron(
                            icon: Icons.description_outlined,
                            title: 'Legal & Privacy',
                            onTap: () {
                                      Get.toNamed(Routes.vendorLegal);
                                    },
                          ),
                        ],
                      ),
                    ),
                
                    // --- 6. SOCIALS (CONDITIONAL) ---
                    if (!_allSocialsEmpty(vendor))
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Social Media'),
                            SizedBox(height: 12.h),
                            if (vendor.whatsappGroup != null) 
                              RowWithChevron(icon: FontAwesomeIcons.whatsapp, title: 'WhatsApp', onTap: (){}),
                            if (vendor.instagram != null) 
                              RowWithChevron(icon: FontAwesomeIcons.instagram, title: 'Instagram', onTap: (){}),
                            if (vendor.website != null) 
                              RowWithChevron(icon: FontAwesomeIcons.globe, title: 'Website', onTap: (){}),
                          ],
                        ),
                      ),
                
                    // --- 7. LOGOUT & DELETE (ADDED) ---
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: OutlinedButton(
                              onPressed: () => _confirmLogout(context, bloc),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD0D5DD)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                foregroundColor: const Color(0xFF344054),
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
              );
            },
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'suspended': return Colors.red;
      default: return Colors.grey;
    }
  }

  bool _allSocialsEmpty(Vendor vendor) {
    return vendor.whatsappGroup == null &&
        vendor.instagram == null &&
        vendor.website == null &&
        vendor.tiktok == null &&
        vendor.twitter == null &&
        vendor.facebook == null &&
        vendor.otherLink == null;
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
              // Trigger Delete Logic
              showAppSnackbar("Contact support to delete vendor account.", SnackbarType.info);
            },
            child: Text('Delete Permanently', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// --- LOCAL WIDGET: STATIC INFO ROW ---
class _StaticInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Widget? trailingIcon;

  const _StaticInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Container(
            width: 34.w, height: 34.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F4),
              borderRadius: BorderRadius.circular(10.r),
              //border: Border.all(color: const Color(0xFFEAE6E2)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18.sp, color: _brand),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF5E5E5E))),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp, 
                          fontWeight: FontWeight.w600,
                          color: valueColor ?? Colors.black87
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      SizedBox(width: 6.w),
                      trailingIcon!,
                    ]
                  ],
                ),
                if (subtitle != null) ...[
                   SizedBox(height: 2.h),
                   Text(subtitle!, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}