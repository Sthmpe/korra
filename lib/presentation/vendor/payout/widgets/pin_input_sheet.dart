import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import 'result_sheets.dart';

/// Shows the world-class, non-dismissible PIN input bottom sheet.
Future<void> showPinInputSheet(BuildContext context) async {
  final bloc = context.read<PayoutBloc>();

  // Ensure we don't leave other overlays blocking
  if (Get.isOverlaysOpen) {
    // safe close of existing overlays (dialog/sheet)
    Get.until((route) => !Get.isOverlaysOpen);
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // This makes the sheet non-dismissible by dragging.
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) =>
        BlocProvider.value(value: bloc, child: const _PinInputSheet()),
  );

  final current = bloc.state;
  if (current.payoutFlowStatus == PayoutFlowStatus.requiresPin ||
      current.payoutFlowStatus == PayoutFlowStatus.pinInvalid) {
    bloc.add(ResetPayoutFlow());
  }
}

class _PinInputSheet extends StatefulWidget {
  const _PinInputSheet();

  @override
  State<_PinInputSheet> createState() => _PinInputSheetState();
}

class _PinInputSheetState extends State<_PinInputSheet> {
  String _enteredPin = '';

  void _handleKeypadTap(String value) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
    });

    if (_enteredPin.length == 4) {
      Timer(const Duration(milliseconds: 10), () {
        context.read<PayoutBloc>().add(PinSubmitted(_enteredPin));
      });
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PayoutBloc, PayoutState>(
      listener: (context, state) {
        if (state.payoutFlowStatus == PayoutFlowStatus.pinInvalid) {
          setState(() {
            _enteredPin = '';
          });
          // Close the PIN sheet
          if (!Get.isOverlaysOpen) Get.back();
          showPayoutFailureSheet(
            context,
            title: 'Incorrect PIN',
            message: 'The PIN you entered is incorrect. Please try again.',
          );
          context.read<PayoutBloc>().add(ResetPayoutFlow());
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: KorraColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: KorraColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 40.w), // Spacer for centering the title
                Text(
                  'Enter Transaction PIN',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: IconButton(
                    onPressed: () {
                      context.read<PayoutBloc>().add(ResetPayoutFlow());
                      Get.back();
                    },
                    icon: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: KorraColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? KorraColors.brand
                        : KorraColors.inputFill,
                    border: Border.all(
                      color: KorraColors.border.withOpacity(0.5),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 24.h),
            // Integrated Keypad
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index < 9) {
                  // Numbers 1-9
                  final number = (index + 1).toString();
                  return _KeypadButton(
                    onTap: () => _handleKeypadTap(number),
                    child: Text(
                      number,
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: KorraColors.text,
                      ),
                    ),
                  );
                } else if (index == 9) {
                  // "Forgot PIN?" Button
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        /* TODO: Implement Forgot PIN flow */
                      },
                      child: Text(
                        'Forgot PIN?',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: KorraColors.brand,
                        ),
                      ),
                    ),
                  );
                } else if (index == 10) {
                  // Number 0
                  return _KeypadButton(
                    onTap: () => _handleKeypadTap('0'),
                    child: Text(
                      '0',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: KorraColors.text,
                      ),
                    ),
                  );
                } else {
                  // Backspace Icon
                  return _KeypadButton(
                    onTap: _handleBackspace,
                    child: const Icon(
                      Iconsax.arrow_left_1,
                      color: KorraColors.text,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// A reusable, elegantly styled button for our custom keypad.
class _KeypadButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _KeypadButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            width: 64.w,
            height: 64.w,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
