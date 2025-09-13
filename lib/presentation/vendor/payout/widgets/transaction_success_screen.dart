// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// import '../../../config/constants/colors.dart';

// class TransactionSuccessScreen extends StatelessWidget {
//   final String amount;
//   const TransactionSuccessScreen({super.key, required this.amount});

//   @override
//   Widget build(BuildContext context) {
//     // This assumes you have a success image in your assets.
//     final successImage = Image.asset('assets/images/success.png', height: 150.h);

//     return Scaffold(
//       backgroundColor: KorraColors.bg,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 24.w),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Spacer(),
//               successImage,
//               SizedBox(height: 24.h),
//               Text(
//                 'Payout Successful!',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w800),
//               ),
//               SizedBox(height: 12.h),
//               Text(
//                 'You have successfully withdrawn ₦$amount to your registered bank account.',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.inter(fontSize: 15.sp, color: KorraColors.textMuted, height: 1.6),
//               ),
//               const Spacer(),
//               OutlinedButton(
//                 onPressed: () { /* TODO: Implement View Details */ },
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: KorraColors.border),
//                   minimumSize: Size.fromHeight(52.h),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
//                 ),
//                 child: Text('View Details', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: KorraColors.text)),
//               ),
//               SizedBox(height: 12.h),
//               FilledButton(
//                 onPressed: () => Get.close(2), // Closes 2 routes: this screen and the payout screen
//                 style: FilledButton.styleFrom(
//                   backgroundColor: KorraColors.brand,
//                   minimumSize: Size.fromHeight(52.h),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
//                 ),
//                 child: Text('Done', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
//               ),
//               SizedBox(height: 24.h),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }