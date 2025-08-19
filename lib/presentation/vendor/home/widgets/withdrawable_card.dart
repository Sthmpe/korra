// import 'dart:ui' show FontFeature;
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:korra/config/constants/colors.dart';
// import 'package:korra/config/constants/sizes.dart';

// class WithdrawableCard extends StatelessWidget {
//   final String amountText;
//   final bool canPayout;
//   final VoidCallback onPayout;

//   const WithdrawableCard({
//     super.key,
//     required this.amountText,
//     required this.canPayout,
//     required this.onPayout,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16.r),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
//         border: Border.all(color: const Color(0xFFEAE6E2), width: 1),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text('Withdrawable balance',
//                   style: GoogleFonts.inter(
//                     fontSize: 12.5.sp,
//                     color: KorraColors.textMuted,
//                     fontWeight: FontWeight.w500,
//                   )),
//               SizedBox(height: 6.h),
//               Text(
//                 amountText,
//                 style: GoogleFonts.inter(
//                   fontSize: 28.sp,
//                   fontWeight: FontWeight.w800,
//                   fontFeatures: const [FontFeature.tabularFigures()],
//                 ),
//               ),
//               SizedBox(height: 4.h),
//               Text('Payouts go to your selected method',
//                   style: GoogleFonts.inter(fontSize: 12.sp, color: KorraColors.textMuted)),
//             ]),
//           ),
//           SizedBox(width: 12.w),
//           SizedBox(
//             height: 46.h,
//             child: ElevatedButton(
//               onPressed: canPayout ? onPayout : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: KorraColors.brand,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14.r), // pill like customer
//                 ),
//                 minimumSize: Size(116.w, 46.h),
//                 elevation: 0,
//               ),
//               child: Text('Payout',
//                 style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp, color: Colors.white)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// //