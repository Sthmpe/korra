import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';

void showSuccessSnackbar(String message) {
  Get.snackbar(
    '',
    '',
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.zero,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    borderRadius: 12,
    maxWidth: 340,
    titleText: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: KorraColors.brand, // burnt orange left border
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: KorraColors.brand,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KorraColors.text, // dark text
                height: 1.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.closeAllSnackbars(),
            child: Icon(
              Icons.close,
              color: KorraColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );
}
