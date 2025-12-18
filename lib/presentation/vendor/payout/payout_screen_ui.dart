import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/vendors/bank_repository.dart';

import '../../../../config/utils/currency_formatters.dart' hide CurrencyInputFormatter;
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import '../../../config/constants/colors.dart';
import '../../shared/widgets/korra_failure_sheet.dart';
import '../../shared/widgets/korra_header.dart';

// Your Widgets
import 'widgets/bank_selector_sheet.dart';
import 'widgets/decimal_input_formatter.dart';
import 'widgets/korra_button.dart';
import 'widgets/korra_loading_overlay.dart';
import 'widgets/password_verification_sheet.dart';
import 'widgets/payout_balance_card.dart';
import 'widgets/payout_success_screen.dart';
import 'widgets/transaction_pin_sheet.dart';


class PayoutScreen extends StatelessWidget {
  const PayoutScreen({super.key});

  void closeAllOverlays() {
    while (Get.isOverlaysOpen) {
      Get.close(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayoutBloc, PayoutState>(
      listenWhen: (prev, curr) =>
          prev.step != curr.step || prev.status != curr.status,
      listener: (context, state) {
        
        // Handle Side Effects (Dialogs, Bottom Sheets, Navigation)
        // BLOCK 1: CREATE PIN (User has no PIN)
        if (state.step == PayoutStep.createPin) {
          FocusManager.instance.primaryFocus?.unfocus();
          //closeAllOverlays();
          //if (Navigator.canPop(context)) Navigator.pop(context);
          showModalBottomSheet(
            enableDrag: false,
            isDismissible: false,
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionPinSheet(
              isCreating: true, // <--- Enable "Create" Mode
              // ✅ HANDLE CANCEL
              onCancel: () {
                Navigator.pop(context);
                context.read<PayoutBloc>().add(PayoutReset());
              },
              onSubmit: (newPin) {
                Navigator.pop(context);
                context.read<PayoutBloc>().add(NewPinCreated(newPin));
              },
            ),
          );
        }

        // BLOCK 2: VERIFY PIN (User has PIN)
        if (state.step == PayoutStep.verifyPin) {
          FocusManager.instance.primaryFocus?.unfocus();
          //closeAllOverlays();
          //if (Navigator.canPop(context)) Navigator.pop(context);
          showModalBottomSheet(
            enableDrag: false,
            isDismissible: false,
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionPinSheet(
              isCreating: false, // <--- Enable "Verify" Mode
              // ✅ HANDLE CANCEL
              onCancel: () {
                Navigator.pop(context);
                context.read<PayoutBloc>().add(PayoutReset());
              },
              onSubmit: (pin) {
                Navigator.pop(context);
                context.read<PayoutBloc>().add(PinSubmitted(pin));
              },
            ),
          );
        }
        
        if (state.step == PayoutStep.completed) {
          // 1. Hide Keyboard (Vital for smooth UI)
          FocusManager.instance.primaryFocus?.unfocus();
          closeAllOverlays();

          // 2. Prepare Data
          // Strip commas from "5,000.00" to get 5000.00
          final amountVal = double.tryParse(state.amountInput.replaceAll(',', '')) ?? 0.0;
          
          // 3. Navigate
          Get.to(() => PayoutSuccessScreen(
            amount: amountVal,
            // Use the Ref from backend, or generate a temporary one if null
            reference: state.transactionRef ?? "REF-${DateTime.now().millisecondsSinceEpoch}",
            bankName: state.bankName,
            accountNumber: state.accountNumber,
            accountName: state.accountName, 
          ));
        } else if (state.status == PayoutStatus.failure) {
          FocusManager.instance.primaryFocus?.unfocus();
          closeAllOverlays();
          final errorMsg = state.errorMessage?.toLowerCase() ?? "";
          
          if (errorMsg.contains("incorrect") && errorMsg.contains("pin")) {
            // 🛑 OPTION A: WRONG PIN (Show Choice Dialog)
            _showWrongPinDialog(context);
          } else {
            // 🛑 OPTION B: GENERIC FAILURE
            showKorraFailureSheet(context, title: 'Withdrawal Failed', message: state.errorMessage ?? "Error", onCancel: () {
            closeAllOverlays();
              context.read<PayoutBloc>().add(PayoutReset());
            });
          }
        }
      },
      builder: (context, state) {
        bool showLoader = state.status == PayoutStatus.loading &&
                        state.step == PayoutStep.processing;

        if (state.status == PayoutStatus.initial || (state.status == PayoutStatus.loading  && !showLoader)) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const KorraHeader(title: "Withdraw Funds", showLeadingIcon: true),
            body: const Center(
              child: CircularProgressIndicator(color: KorraColors.brand),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const KorraHeader(
            title: "Withdraw Funds",
            showLeadingIcon: true,
          ),
          body:  KorraLoadingOverlay(
            isLoading: showLoader,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Balance Card (Premium)
                  PayoutBalanceCard(state: state),
                      
                  SizedBox(height: 32.h),
                      
                  // 2. Bank Selector
                  Text(
                    "Send to",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildBankSelector(context, state),
                      
                  SizedBox(height: 24.h),
                    
                  SizedBox(height: 8.h),
                  _buildAmountInput(context, state),
                      
                  SizedBox(height: 40.h),
                      
                  // 4. Action Button
                  KorraButton(
                    text: "Withdraw",
                    isLoading: state.step == PayoutStep.processing,
                    onPressed: state.canWithdraw
                        ? () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            context.read<PayoutBloc>().add(WithdrawClicked());
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widget Components ---

  Widget _buildBankSelector(BuildContext context, PayoutState state) {
    final hasBank = state.accountNumber.isNotEmpty;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => BankSelectorSheet(
            banks: state.bankList,

            // ✅ FIXED VALIDATION LOGIC
            onValidate: (code, number) async {
              // The repo method returns Map<String, dynamic>
              final result = await context
                  .read<PayoutBloc>()
                  .repo
                  .validateBankAccount(accountNumber: number, bankCode: code);

              // Handle potential null safely
              final name = result['accountName'];
              if (name == null || name.isEmpty) {
                throw Exception("Account name not found");
              }

              return name; // Returns non-nullable String
            },

            onConfirm: (bank, accNum, accName) {
              Navigator.pop(context);
              context.read<PayoutBloc>().add(
                BankDetailsUpdated(
                  bankName: bank.name,
                  bankCode: bank.code,
                  accountNumber: accNum,
                  accountName: accName,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Row(
          children: [
            // Bank Icon or Logo
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: const Icon(
                Icons.account_balance,
                color: Color(0xFFA54600),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: hasBank
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.bankName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "${state.accountNumber} • ${state.accountName}",
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      "Select Bank Account",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

 Widget _buildAmountInput(BuildContext context, PayoutState state) {
    // Logic to determine the specific error message
    String? getErrorText() {
      if (state.amountInput.isEmpty) return null;
      
      final amount = double.tryParse(state.amountInput) ?? 0.0;
      
      if (amount <= 0) return null; // Don't show error while typing 0
      if (amount > state.withdrawableBalance) return "Insufficient balance";
      
      return null; // Valid
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Amount", 
          style: GoogleFonts.inter(
            fontSize: 13.sp, 
            fontWeight: FontWeight.w600, 
            color: const Color(0xFF344054) // Cool Grey
          )
        ),
        SizedBox(height: 8.h),
        
        TextFormField(
          // Ensure keyboard allows decimals
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          
          // Enforce 2 Decimal Places
          inputFormatters: [
            CurrencyInputFormatter(),
          ],
          
          onChanged: (val) => context.read<PayoutBloc>().add(AmountChanged(val)),
          
          // Big, Bold Text for the Amount
          style: GoogleFonts.inter(
            fontSize: 20.sp, 
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF101828),
            letterSpacing: 0.5
          ),
          
          decoration: InputDecoration(
            // Permanent Naira Sign
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: Text(
                '₦', 
                style: GoogleFonts.inter(
                  fontSize: 20.sp, 
                  fontWeight: FontWeight.w700, 
                  color: const Color(0xFF98A2B3) // Muted Grey for currency symbol
                )
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            
            hintText: "0.00",
            hintStyle: GoogleFonts.inter(color: const Color(0xFFD0D5DD)),
            
            filled: true,
            fillColor: Colors.white,
            
            // Clean, Premium Borders
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
            ),
            
            // Error Styling (Small & Clean)
            errorText: getErrorText(),
            errorStyle: GoogleFonts.inter(
              fontSize: 11.sp, 
              fontWeight: FontWeight.w500, 
              color: const Color(0xFFD92D20) // Premium Alert Red
            ),
            // Remove the default red border on error to keep it clean? 
            // Or keep it subtle. Flutter adds red border by default if errorText != null.
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD92D20)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 1. SHOW "WRONG PIN" DIALOG
  // ---------------------------------------------------------
  void _showWrongPinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: Icon(Iconsax.lock_circle, size: 32.sp, color: const Color(0xFFD92D20)),
            ),
            SizedBox(height: 16.h),
            
            Text("Incorrect PIN", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 8.h),
            
            Text(
              "The PIN you entered is incorrect. You can try again or reset it securely.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF667085), height: 1.4),
            ),
            SizedBox(height: 32.h),
            
            // Button: Try Again
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA54600),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  _openPinSheet(context, isCreating: false); // Re-open Verify
                },
                child: Text("Try Again", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15.sp)),
              ),
            ),
            SizedBox(height: 12.h),

            // Button: Forgot PIN
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  _openPasswordVerification(context); // Open Password Check
                },
                child: Text("Forgot PIN? Reset it", style: GoogleFonts.inter(color: const Color(0xFF475467), fontWeight: FontWeight.w600, fontSize: 15.sp)),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 2. OPEN PASSWORD CHECKER
  // ---------------------------------------------------------
  void _openPasswordVerification(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PasswordVerificationSheet(
        onVerified: () {
          // If password correct -> Open Create PIN Sheet
          // We wait a tiny bit for the sheet animation to close
          Future.delayed(const Duration(milliseconds: 300), () {
             _openPinSheet(context, isCreating: true);
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // 3. OPEN PIN SHEET (REUSED)
  // ---------------------------------------------------------
  void _openPinSheet(BuildContext context, {required bool isCreating}) {
    showModalBottomSheet(
      enableDrag: false,
      isDismissible: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinSheet(
        isCreating: isCreating,
        onCancel: () {
          Navigator.pop(context);
          context.read<PayoutBloc>().add(PayoutReset());
        },
        onSubmit: (pin) {
          Navigator.pop(context);
          if (isCreating) {
            context.read<PayoutBloc>().add(NewPinCreated(pin));
          } else {
            context.read<PayoutBloc>().add(PinSubmitted(pin));
          }
        },
      ),
    );
  }
}
