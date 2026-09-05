import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:share_plus/share_plus.dart';

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
import 'widgets/static_info_row.dart';
import 'widgets/store_qr_sheet.dart';
// For logout navigation

// --- MODEL ---
// import 'path/to/vendor_model.dart'; 

const _brand = Color(0xFFA54600);

class VendorProfilePage extends StatelessWidget {
  final String vendorUid;

  const VendorProfilePage({
    super.key, 
    required this.vendorUid
  });

  @override
  Widget build(BuildContext context) {
    final vendors = context.read<VendorRepository>();
    return BlocProvider(
      create: (context) => ProfileBloc(
        vendorRepo: vendors,
        net: context.read<NetCubit>(),
        vendorUid: vendorUid,
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
                        Get.toNamed(Routes.vendorEditProfile, arguments: {'vendor': vendor});
                      },
                      onShare: () => _shareStore(vendor),
                      onMyQr: () => _showStoreQr(context, vendor),
                    ),
                
                    SizedBox(height: 16.h),

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
                                  'uid': vendorUid,
                                },
                              );
                            }
                          ),

                          _divider(),
                          // 🚀 NEW STORE BALANCE ROW ADDED HERE
                          RowWithChevron(
                            icon: Iconsax.receipt_2_1, // A good icon for ledgers/liabilities
                            title: 'Customer Store Balances',
                            subtitle: 'Track retained customer balances',
                            onTap: () {
                              Get.toNamed(
                                Routes.vendorStoreBalances,
                                arguments: {
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
                              Get.toNamed(
                                  Routes.vendorPayoutSettings,
                                  arguments: {
                                    'uid': vendorUid,
                                  },
                                );
                            },
                          ),
                        ],
                      ),
                    ),
                
                    // --- 2. BUSINESS INFO ---
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Business Details'),
                          SizedBox(height: 12.h),
                
                          StaticInfoRow(
                            icon: Iconsax.briefcase,
                            title: 'Legal Name',
                            value: vendor.legalName,
                          ),
                          _divider(),
                          
                          StaticInfoRow(
                            icon: Iconsax.document,
                            title: 'CAC Number',
                            value: vendor.cac.isNotEmpty ? vendor.cac : "Not Provided",
                          ),
                          _divider(),
                
                          StaticInfoRow(
                            icon: Iconsax.verify,
                            title: 'Status',
                            value: vendor.status.toUpperCase(),
                            valueColor: _getStatusColor(vendor.status),
                          ),
                          _divider(),
                
                          StaticInfoRow(
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
                
                          StaticInfoRow(
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
                
                    // --- 4. SECURITY & LEGAL (ADDED) ---
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
                          // Change password removed — accounts use Google
                          // sign-in (David, 5 July 2026)
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

                     // --- 5. PREFERENCES (ADDED) ---
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
                
                    // --- 6. SOCIALS (CONDITIONAL) ---
                    if (!_allSocialsEmpty(vendor))
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Social Media'),
                            SizedBox(height: 12.h),
                            if (vendor.whatsappGroup != null) 
                              RowWithChevron(iconWidget: FaIcon(FontAwesomeIcons.whatsapp, size: 18.sp, color: const Color(0xFF25D366)), title: 'WhatsApp', onTap: (){}),
                            if (vendor.instagram != null) 
                              RowWithChevron(iconWidget: FaIcon(FontAwesomeIcons.instagram, size: 18.sp, color: const Color(0xFFE1306C)), title: 'Instagram', onTap: (){}),
                            if (vendor.website != null) 
                              RowWithChevron(iconWidget: FaIcon(FontAwesomeIcons.globe, size: 18.sp, color: const Color(0xFF000000)), title: 'Website', onTap: (){}),
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

  /// Storefront link built from the store slug (falls back to the uid, which
  /// the customer storefront also resolves).
  Future<String> _storeLink() async {
    String slug = vendorUid;
    try {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(vendorUid).get();
      final store = doc.data()?['store'] as Map<String, dynamic>? ?? {};
      final s = (store['slug'] ?? '').toString().trim();
      if (s.isNotEmpty) slug = s;
    } catch (e) {
      debugPrint("Could not resolve store slug: $e");
    }
    return "https://korra.com.ng/store/$slug";
  }

  Future<void> _shareStore(Vendor vendor) async {
    final link = await _storeLink();
    await Share.share(
      "Shop with ${vendor.storeName} on Korra.\n\n"
      "Reserve today. Complete at your pace.\n\n"
      "$link",
      subject: vendor.storeName,
    );
  }

  Future<void> _showStoreQr(BuildContext context, Vendor vendor) async {
    final link = await _storeLink();
    if (!context.mounted) return;
    StoreQrSheet.show(context, storeName: vendor.storeName, storeLink: link);
  }

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
