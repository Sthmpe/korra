import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// Ensure this path matches your project structure
import '../../../../logic/bloc/vendor/payout/transaction_pin_bloc.dart';
import '../../../../config/constants/colors.dart'; // Assuming you have this for KorraColors

class TransactionPinSheet extends StatelessWidget {
  final bool isCreating;
  final Function(String pin) onSubmit;
  final VoidCallback onCancel;

  const TransactionPinSheet({
    super.key,
    required this.isCreating,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionPinBloc(isCreating: isCreating),
      child: _PinSheetContent(
        onSubmit: onSubmit, 
        onCancel: onCancel, 
        isCreating: isCreating
      ),
    );
  }
}

class _PinSheetContent extends StatefulWidget {
  final Function(String pin) onSubmit;
  final VoidCallback onCancel;
  final bool isCreating;

  const _PinSheetContent({
    required this.onSubmit, 
    required this.onCancel, 
    required this.isCreating
  });

  @override
  State<_PinSheetContent> createState() => _PinSheetContentState();
}

class _PinSheetContentState extends State<_PinSheetContent> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionPinBloc, PinState>(
      listenWhen: (previous, current) => 
          previous.stage != current.stage || 
          previous.hasError != current.hasError ||
          previous.input != current.input,
          
      listener: (context, state) {
        // 1. Handle Successful Verification/Creation
        if (state.stage == PinStage.verified) {
          widget.onSubmit(state.input);
        }
        
        // 2. Handle Immediate Submission for "Verify Mode"
        if (!widget.isCreating && state.input.length == 4) {
          widget.onSubmit(state.input);
        }

        // 3. Handle Error (Shake & Haptic)
        if (state.hasError) {
          HapticFeedback.heavyImpact();
          _shakeController.forward().then((_) => _shakeController.reset());
        }
      },
      builder: (context, state) {
        // --- UI Logic: Determine Text ---
        String title = "Enter PIN";
        String subtitle = "Authorize withdrawal";

        if (widget.isCreating) {
          if (state.stage == PinStage.confirming) {
            title = "Re-enter PIN";
            subtitle = "Confirm your new PIN";
          } else {
            title = "Create PIN";
            subtitle = "Set a secure 4-digit PIN";
          }
        }

        if (state.hasError) {
          subtitle = "PINs did not match. Restarting...";
        }

        // --- UI Render ---
        return Container(
          height: 680.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // 1. Header
              _buildHeader(context),

              SizedBox(height: 24.h),
              
              // 2. Title & Subtitle
              Text(
                title, 
                style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle, 
                style: GoogleFonts.inter(
                  fontSize: 14.sp, 
                  color: state.hasError ? Colors.red : Colors.grey.shade500
                )
              ),

              SizedBox(height: 40.h),

              // 3. Animated Dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool isFilled = index < state.input.length;
                        // Determine Color: Red if error, Green (Brand) if filled, Grey if empty
                        Color borderColor = state.hasError 
                            ? Colors.red 
                            : (isFilled ? KorraColors.brand : Colors.grey.shade300);
                        
                        Color fillColor = state.hasError 
                            ? Colors.red 
                            : (isFilled ? KorraColors.brand : Colors.transparent);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: 12.w),
                          height: 16.w, width: 16.w,
                          decoration: BoxDecoration(
                            color: fillColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const Spacer(),

              // 4. NumPad
              _buildNumPad(context),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Drag Handle
        Container(
          width: 40.w, height: 4.h, 
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))
        ),
        // Close Button
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: widget.onCancel,
            icon: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 20, color: Colors.black),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildNumPad(BuildContext context) {
    return SizedBox(
      height: 320.h,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, 
          childAspectRatio: 1.6
        ),
        itemBuilder: (context, index) {
          // Empty space for bottom left
          if (index == 9) return const SizedBox.shrink();
          
          // Backspace Button
          if (index == 11) {
            return GestureDetector(
              onTap: () => context.read<TransactionPinBloc>().add(PinDigitDeleted()),
              behavior: HitTestBehavior.opaque,
              child: const Center(child: Icon(Iconsax.arrow_left, color: Colors.black)),
            );
          }
          
          // Number Buttons
          String val = index == 10 ? "0" : "${index + 1}";
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<TransactionPinBloc>().add(PinDigitEntered(val));
            },
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Text(
                val, 
                style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828))
              ),
            ),
          );
        },
      ),
    );
  }
}