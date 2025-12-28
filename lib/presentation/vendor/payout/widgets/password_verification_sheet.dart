// lib/presentation/vendor/payout/widgets/password_verification_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart'; // Added icons

// Ensure correct imports
import 'korra_button.dart';

class PasswordVerificationSheet extends StatefulWidget {
  final VoidCallback onVerified;

  const PasswordVerificationSheet({super.key, required this.onVerified});

  @override
  State<PasswordVerificationSheet> createState() => _PasswordVerificationSheetState();
}

class _PasswordVerificationSheetState extends State<PasswordVerificationSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscure = true; // Toggle visibility

  Future<void> _verifyPassword() async {
    if (_controller.text.isEmpty) return;
    
    setState(() { _isLoading = true; _error = null; });
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception("User session invalid");

      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _controller.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      if (mounted) {
        Navigator.pop(context); // Close Sheet
        widget.onVerified(); // Trigger Reset Flow
      }
    } on FirebaseAuthException catch (_) {
      setState(() => _error = "Incorrect password. Please try again.");
    } catch (e) {
      setState(() => _error = "Verification failed. Check your internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            SizedBox(height: 24.h),

            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(color: const Color(0xFFF2F4F7), shape: BoxShape.circle),
                  child: Icon(Iconsax.shield_tick, color: const Color(0xFF344054), size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Security Check", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                    Text("Verify it's you to reset PIN", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Password Field
            TextField(
              controller: _controller,
              obscureText: _obscure,
              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Account Password",
                labelStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: Colors.grey),
                errorStyle: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500),
                errorText: _error,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFA54600), width: 1.5)),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Iconsax.eye : Iconsax.eye_slash, size: 20, color: Colors.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Button
            KorraButton(
              text: "Verify & Reset",
              isLoading: _isLoading,
              onPressed: _verifyPassword,
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}