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

Future<void> showCreatePinSheet(BuildContext context) async {
  final bloc = context.read<PayoutBloc>();

  if (Get.isOverlaysOpen) {
    Get.until((route) => !Get.isOverlaysOpen);
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) =>
        BlocProvider.value(value: bloc, child: const _CreatePinSheet()),
  );
}

class _CreatePinSheet extends StatefulWidget {
  const _CreatePinSheet();

  @override
  State<_CreatePinSheet> createState() => _CreatePinSheetState();
}

class _CreatePinSheetState extends State<_CreatePinSheet>
    with SingleTickerProviderStateMixin {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleKeypadTap(String value) {
    setState(() {
      _hasError = false; // clear error once user starts typing again
      if (!_isConfirming) {
        if (_firstPin.length < 4) _firstPin += value;
        if (_firstPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() => _isConfirming = true);
          });
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += value;
        if (_confirmPin.length == 4) {
          _validatePins();
        }
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      _hasError = false;
      if (!_isConfirming) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _validatePins() {
    if (_firstPin == _confirmPin) {
      context.read<PayoutBloc>().add(NewPinCreated(_firstPin));
      Get.back();
    } else {
      setState(() {
        _hasError = true;
        _confirmPin = ''; // clear only confirm pin
      });
      _shakeController.forward(from: 0); // trigger shake
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _isConfirming ? _confirmPin : _firstPin;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: KorraColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Handle bar ----
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: KorraColors.border,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          SizedBox(height: 32.h),

          // ---- Title Row ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 40.w),
                  Text(
                    _isConfirming ? "Confirm New PIN" : "Create New PIN",
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

          // ---- PIN indicators (with shake + error state) ----
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset = 10 * (1 - _shakeController.value) * 
                  (_shakeController.value % 0.2 > 0.1 ? -1 : 1);
              return Transform.translate(
                offset: Offset(_hasError ? offset : 0, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < currentInput.length
                        ? (_hasError ? Colors.redAccent : KorraColors.brand)
                        : KorraColors.inputFill,
                    border: Border.all(color: KorraColors.border.withOpacity(0.5)),
                  ),
                );
              }),
            ),
          ),

          if (_hasError) ...[
            SizedBox(height: 12.h),
            Text(
              "PINs do not match. Try again or Reset.",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.redAccent,
              ),
            ),
          ],

          SizedBox(height: 24.h),

          // ---- Keypad remains same ----
          _buildKeypad(),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index < 9) {
          final number = (index + 1).toString();
          return _KeypadButton(
            onTap: () => _handleKeypadTap(number),
            child: Text(number,
                style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: KorraColors.text)),
          );
        } else if (index == 9) {
          return _isConfirming
              ? TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _firstPin = '';
                      _confirmPin = '';
                      _isConfirming = false;
                      _hasError = false;
                    });
                  },
                  icon: const Icon(Iconsax.refresh, color: KorraColors.textMuted),
                  label: Text("Reset",
                      style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: KorraColors.textMuted)),
                )
              : const SizedBox.shrink();
        } else if (index == 10) {
          return _KeypadButton(
            onTap: () => _handleKeypadTap('0'),
            child: Text('0',
                style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: KorraColors.text)),
          );
        } else {
          return _KeypadButton(
            onTap: _handleBackspace,
            child: const Icon(Iconsax.arrow_left_1, color: KorraColors.text),
          );
        }
      },
    );
  }
}

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
