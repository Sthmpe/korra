import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const _brand = Color(0xFFA54600);

class IdentityHeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String phone;
  final bool kycVerified;
  final bool basicTier;
  final VoidCallback? onEdit;
  final VoidCallback? onMyQr;
  final VoidCallback? onShare;

  const IdentityHeaderCard({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
    required this.phone,
    required this.kycVerified,
    required this.basicTier,
    this.onMyQr,
    this.onShare,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Safety check for initials
    final safeInitials = initials.isNotEmpty ? initials : (name.isNotEmpty ? name[0] : '?');

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r), 
          border: Border.all(color: const Color(0xFFEAECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Align to center vertically
                children: [
                  // 1. PREMIUM AVATAR
                  Container(
                    width: 64.w, 
                    height: 64.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7ED), Color(0xFFFFEED5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0xFFFFE4C2), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      safeInitials.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: _brand),
                    ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // 2. DETAILS COLUMN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Verified Check
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp, 
                                  fontWeight: FontWeight.w700, 
                                  color: const Color(0xFF101828)
                                ),
                              ),
                            ),
                            if (kycVerified) ...[
                              SizedBox(width: 6.w),
                              Icon(Icons.verified, size: 18.sp, color: Colors.blue),
                            ]
                          ],
                        ),
                        
                        SizedBox(height: 4.h),
                        
                        // Email (With Tooltip for long emails)
                        Tooltip(
                          message: email,
                          child: Text(
                            email,
                            style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF667085), fontWeight: FontWeight.w500),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        SizedBox(height: 2.h),

                        // Phone
                        Text(
                          phone,
                          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF667085), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF2F4F7)),

            // 3. ACTION GRID
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.edit_outlined, "Edit Profile", onTap: onEdit),
                  _verticalDivider(),
                  _buildActionButton(Icons.qr_code_2, "My QR", onTap: onMyQr), // Feature Placeholder
                  _verticalDivider(),
                  _buildActionButton(Icons.share_outlined, "Share", onTap: onShare), // Feature Placeholder
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 24.h, width: 1, color: const Color(0xFFEAECF0));
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return Expanded( // Ensures touch targets are equal width
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20.sp, color: const Color(0xFF344054)),
              SizedBox(height: 4.h),
              Text(
                label, 
                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}