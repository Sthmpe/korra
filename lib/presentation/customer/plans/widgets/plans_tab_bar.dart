// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:korra/logic/bloc/customer/plans/plans_event.dart';

// import '../plans_page.dart';

// // Ensure this matches where your Enum is defined
// class PlansTabBar extends StatelessWidget {
//   final PlansTab currentTab;
//   final ValueChanged<PlansTab> onChanged;

//   const PlansTabBar({
//     super.key,
//     required this.currentTab,
//     required this.onChanged,
//   });

//   static const _brand = Color(0xFFA54600);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         _buildTab("Active", PlansTab.active),
//         _buildTab("Completed", PlansTab.completed),
//         _buildTab("Overdue", PlansTab.overdue),
//         _buildTab("Cancelled", PlansTab.cancelled), // ✅ Added
//       ],
//     );
//   }

//   Widget _buildTab(String text, PlansTab tab) {
//     final selected = currentTab == tab;
    
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => onChanged(tab),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           // Reduced horizontal margin slightly so 4 items fit comfortably
//           margin: EdgeInsets.symmetric(horizontal: 2.w), 
//           padding: EdgeInsets.symmetric(vertical: 10.h),
//           decoration: BoxDecoration(
//             color: selected ? _brand : Colors.white,
//             borderRadius: BorderRadius.circular(12.r),
//             border: Border.all(
//               color: selected ? _brand : const Color(0xFFEAE6E2),
//             ),
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             text,
//             maxLines: 1,
//             style: GoogleFonts.inter(
//               // Reduced font slightly (12.sp) to prevent overflow for "Completed"
//               fontSize: 12.sp, 
//               fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
//               color: selected ? Colors.white : const Color(0xFF101828),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }