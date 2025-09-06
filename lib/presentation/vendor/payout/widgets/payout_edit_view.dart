import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import 'bank_search_field.dart';

class PayoutEditView extends StatelessWidget {
  final PayoutState state;
  const PayoutEditView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update Payout Method', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 16.h),
        BankSearchField(
          bankList: state.bankList,
          selectedBank: state.selectedBank,
          onBankSelected: (bank) => context.read<PayoutBloc>().add(BankSelected(bank)),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          initialValue: state.tempAccountNumber,
          onChanged: (value) => context.read<PayoutBloc>().add(AccountNumberChanged(value)),
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            labelText: 'Account Number (10 digits)',
            suffixIcon: _buildVerificationSuffix(state.bankDetailsVerificationStatus),
          ),
        ),
        SizedBox(height: 8.h),
        _buildVerifiedName(state),
        SizedBox(height: 20.h),
        _buildActionButtons(context, state),
      ],
    );
  }
}

//== SUB-WIDGETS FOR THE EDIT VIEW ==//

Widget _buildVerificationSuffix(BankDetailsVerificationStatus status) {
  switch (status) {
    case BankDetailsVerificationStatus.verifying:
      return Container(
        padding: EdgeInsets.all(12.r),
        child: SizedBox(
          width: 16.r,
          height: 16.r,
          child: const CircularProgressIndicator(strokeWidth: 2, color: KorraColors.brand),
        ),
      );
    case BankDetailsVerificationStatus.verified:
      return Icon(Icons.check_circle, color: KorraColors.success, size: 20.sp);
    case BankDetailsVerificationStatus.error:
      return Icon(Icons.error, color: KorraColors.danger, size: 20.sp);
    case BankDetailsVerificationStatus.idle:
      return const SizedBox.shrink();
  }
}

Widget _buildVerifiedName(PayoutState state) {
  final bool isVerified = state.bankDetailsVerificationStatus == BankDetailsVerificationStatus.verified && state.verifiedAccountName != null;
  return AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: isVerified ? 1.0 : 0.0,
    child: isVerified
        ? Padding(
            padding: EdgeInsets.only(left: 12.w, top: 4.h),
            child: Text(
              state.verifiedAccountName!,
              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: KorraColors.brand),
            ),
          )
        : const SizedBox.shrink(),
  );
}

Widget _buildActionButtons(BuildContext context, PayoutState state) {
  bool canConfirm = state.bankDetailsVerificationStatus == BankDetailsVerificationStatus.verified;

  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: () => context.read<PayoutBloc>().add(EditMethodToggled()),
        child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: KorraColors.textMuted)),
      ),
      SizedBox(width: 8.w),
      SizedBox(
        height: 44.h,
        child: FilledButton(
          onPressed: canConfirm ? () => context.read<PayoutBloc>().add(ConfirmAndSaveMethodTapped()) : null,
          style: FilledButton.styleFrom(
            backgroundColor: KorraColors.brand,
            disabledBackgroundColor: KorraColors.brand.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: state.status == PayoutStatus.updating
              ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  canConfirm ? 'Confirm' : 'Save Changes',
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
        ),
      ),
    ],
  );
}

// Helper for styling input decorations consistently
InputDecoration _inputDecoration({required String labelText, Widget? suffixIcon, Widget? prefixIcon}) {
    return InputDecoration(
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelText: labelText,
        labelStyle: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted),
        filled: true,
        fillColor: KorraColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: KorraColors.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: KorraColors.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: KorraColors.brand)),
    );
}