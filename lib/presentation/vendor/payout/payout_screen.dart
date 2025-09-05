// lib/presentation/vendor/payout/payout_screen.dart


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/colors.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../shared/widgets/korra_header.dart';
import 'widgets/payout_balance_card.dart';
import 'widgets/payout_method_card.dart';

class PayoutScreen extends StatelessWidget {
  final String vendorUid;
  final VendorRepository vendors;

  const PayoutScreen({
    super.key,
    required this.vendorUid,
    required this.vendors,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PayoutBloc(vendorUid: vendorUid, vendors: vendors)
            ..add(PayoutStarted()),
      child: Scaffold(
        backgroundColor: KorraColors.bg,
        appBar: const KorraHeader(
          title: 'Manage Payout',
          trailingActions: [],
          showLeadingIcon: true,
        ),
        body: BlocBuilder<PayoutBloc, PayoutState>(
          builder: (context, state) {
            debugPrint('PayoutState: $state');
            debugPrint('vendorUid: $vendorUid');
            if (state.status == PayoutStatus.loading ||
                state.status == PayoutStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: KorraColors.brand),
              );
            }

            if (state.status == PayoutStatus.failure) {
              return Center(
                child: Text(state.errorMessage ?? 'An error occurred.'),
              );
            }
            debugPrint('Payout Details: ${state.payoutDetails.toMap()}');
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              children: [
                PayoutBalanceCard(state: state),
                SizedBox(height: 24.h),
                PayoutMethodCard(state: state),
                SizedBox(height: 24.h),
                _buildAmountInput(context, state),
                SizedBox(height: 32.h),
                SizedBox(
                  height: 52.h,
                  child: FilledButton(
                    onPressed: () =>
                        context.read<PayoutBloc>().add(WithdrawTapped()),
                    style: FilledButton.styleFrom(
                      backgroundColor: KorraColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Withdraw Funds',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


// Widget _buildMethodCard(BuildContext context, PayoutState state) {
//   final details = state.payoutDetails;
//   final accNum = details.bankAccountNumber;
//   final maskedAcc = accNum.length > 4 ? accNum.substring(accNum.length - 4) : accNum;

//   final isEditing = state.isEditingMethod; // <- add this flag to your state

//   // Controllers only when editing
//   final bankNameController = TextEditingController(text: details.bankName);
//   final accNumController = TextEditingController(text: details.bankAccountNumber);

//   return Container(
//     padding: EdgeInsets.all(16.r),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16.r),
//       border: Border.all(color: Colors.grey.shade200),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.grey.withOpacity(0.05),
//           blurRadius: 8,
//           offset: const Offset(0, 4),
//         )
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Iconsax.bank, color: KorraColors.textMuted, size: 24.sp),
//             SizedBox(width: 16.w),

//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     details.bankName.isEmpty
//                         ? 'No payout method'
//                         : 'Payout Method',
//                     style: GoogleFonts.inter(
//                       fontSize: 14.sp,
//                       fontWeight: FontWeight.w600,
//                       color: KorraColors.text,
//                     ),
//                   ),
//                   SizedBox(height: 4.h),

//                   if (!isEditing) ...[
//                     Text(
//                       '${details.bankAccountName} ••$maskedAcc',
//                       style: GoogleFonts.inter(
//                         fontSize: 13.sp,
//                         fontWeight: FontWeight.w500,
//                         color: KorraColors.textMuted,
//                       ),
//                     ),
//                   ] else ...[
//                     TextFormField(
//                       controller: bankNameController,
//                       decoration: InputDecoration(
//                         labelText: "Bank Name",
//                         labelStyle: TextStyle(
//                           fontSize: 12.sp,
//                           color: KorraColors.textMuted,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8.r),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 8.h,
//                           horizontal: 12.w,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 8.h),
//                     TextFormField(
//                       controller: accNumController,
//                       keyboardType: TextInputType.number,
//                       decoration: InputDecoration(
//                         labelText: "Account Number",
//                         labelStyle: TextStyle(
//                           fontSize: 12.sp,
//                           color: KorraColors.textMuted,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8.r),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 8.h,
//                           horizontal: 12.w,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),

//             SizedBox(width: 12.w),

//             TextButton(
//               onPressed: () {
//                 if (isEditing) {
//                   // Dispatch save event with new details
//                   context.read<PayoutBloc>().add(
//                         SaveMethodTapped(
//                           bankNameController.text,
//                           accNumController.text,
//                         ),
//                       );
//                 } else {
//                   context.read<PayoutBloc>().add(UpdateMethodTapped());
//                 }
//               },
//               child: Text(
//                 isEditing ? 'Done' : 'Update',
//                 style: GoogleFonts.inter(
//                   fontSize: 14.sp,
//                   fontWeight: FontWeight.w700,
//                   color: KorraColors.brand,
//                 ),
//               ),
//             ),
//           ],
//         ),

//         if (isEditing) ...[
//           SizedBox(height: 12.h),
//           Container(
//             padding: EdgeInsets.all(8.r),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius: BorderRadius.circular(8.r),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning_amber_rounded,
//                     color: Colors.orange, size: 18.sp),
//                 SizedBox(width: 8.w),
//                 Expanded(
//                   child: Text(
//                     "Ensure details match your bank records.",
//                     style: GoogleFonts.inter(
//                       fontSize: 12.sp,
//                       color: Colors.orange.shade800,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ],
//     ),
//   );
// }



  // Widget _buildMethodCard(BuildContext context, PayoutState state) {
  //   final details = state.payoutDetails;
  //   final accNum = details.bankAccountNumber;
  //   final maskedAcc = accNum.length > 4
  //       ? accNum.substring(accNum.length - 4)
  //       : accNum;

  //   return Container(
  //     padding: EdgeInsets.all(16.r),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16.r),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(Iconsax.bank, color: KorraColors.textMuted, size: 24.sp),
  //         SizedBox(width: 16.w),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 details.bankName.isEmpty ? 'No payout method' : 'Payout Method',
  //                 style: GoogleFonts.inter(
  //                   fontSize: 14.sp,
  //                   fontWeight: FontWeight.w600,
  //                   color: KorraColors.text,
  //                 ),
  //               ),
  //               SizedBox(height: 4.h),
  //               Text(
  //                 '${details.bankAccountName} ••$maskedAcc',
  //                 style: GoogleFonts.inter(
  //                   fontSize: 13.sp,
  //                   fontWeight: FontWeight.w500,
  //                   color: KorraColors.textMuted,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(width: 12.w),
  //         TextButton(
  //           onPressed: () =>
  //               context.read<PayoutBloc>().add(UpdateMethodTapped()),
  //           child: Text(
  //             'Update',
  //             style: GoogleFonts.inter(
  //               fontSize: 14.sp,
  //               fontWeight: FontWeight.w700,
  //               color: KorraColors.brand,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildAmountInput(BuildContext context, PayoutState state) {
    return TextFormField(
      onChanged: (value) =>
          context.read<PayoutBloc>().add(AmountChanged(value)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: KorraColors.text,
      ),
      decoration: InputDecoration(
        labelText: 'Amount to Withdraw',
        labelStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: KorraColors.textMuted,
        ),
        prefixText: '₦ ',
        prefixStyle: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: KorraColors.text,
        ),
        filled: true,
        fillColor: KorraColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KorraColors.brand, width: 2.0),
        ),
        helperText: 'Enter the amount you wish to transfer.',
        helperStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          color: KorraColors.textMuted,
        ),
      ),
    );
  }
}
