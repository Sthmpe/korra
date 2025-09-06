import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';

void showPinInputSheet(BuildContext context) {
  final bloc = context.read<PayoutBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _PinInputSheet(bloc: bloc),
    ),
  );
}

class _PinInputSheet extends StatelessWidget {
  final PayoutBloc bloc;
  const _PinInputSheet({required this.bloc});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 60.h,
      textStyle: GoogleFonts.inter(fontSize: 22.sp, color: KorraColors.text, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: KorraColors.inputFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: KorraColors.border),
      ),
    );

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter Transaction PIN', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          Text('Enter your 4-digit PIN to authorize this withdrawal.', style: GoogleFonts.inter(color: KorraColors.textMuted)),
          SizedBox(height: 24.h),
          Pinput(
            length: 4,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: KorraColors.brand),
              ),
            ),
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (pin) => bloc.add(PinSubmitted(pin)),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}