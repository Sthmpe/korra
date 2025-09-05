// lib/presentation/vendor/payout/widgets/payout_method_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/bank.dart';
import '../../../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../../../logic/bloc/vendor/payout/payout_event.dart';
import '../../../../logic/bloc/vendor/payout/payout_state.dart';

// The main card widget remains the same, orchestrating the views.
class PayoutMethodCard extends StatelessWidget {
  final PayoutState state;
  const PayoutMethodCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFECECEC), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: state.isEditingMethod
              ? _EditView(state: state)
              : _DisplayView(state: state),
        ),
      ),
    );
  }
}

//== VIEW 1: READ-ONLY DISPLAY ==//
class _DisplayView extends StatelessWidget {
  final PayoutState state;
  const _DisplayView({required this.state});

  @override
  Widget build(BuildContext context) {
    final details = state.payoutDetails;
    final accNum = details.bankAccountNumber;
    final maskedAcc = accNum.length > 4 ? accNum.substring(accNum.length - 4) : accNum;

    return Row(
      children: [
        Icon(Iconsax.bank, color: KorraColors.textMuted, size: 24.sp),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text( 
                details.bankAccountNumber.isNotEmpty ? details.bankName : 'No Bank Details Added',
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: KorraColors.text),
              ),
              if (details.bankAccountNumber.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  '${details.bankAccountName} •••$maskedAcc',
                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12.w),
        TextButton(
          onPressed: () => context.read<PayoutBloc>().add(EditMethodToggled()),
          child: Text(
            details.bankAccountNumber.isNotEmpty ? 'Update' : 'Add',
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.brand),
          ),
        ),
      ],
    );
  }
}

//== VIEW 2: IN-PLACE EDITING (UPGRADED) ==//
class _EditView extends StatelessWidget {
  final PayoutState state;
  const _EditView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update Payout Method', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 20.h),
        // ▼ UPGRADED: Custom searchable bank dropdown
        _BankSearchField(
          bankList: state.bankList,
          selectedBank: state.selectedBank,
          onBankSelected: (bank) => context.read<PayoutBloc>().add(BankSelected(bank)),
        ),
        SizedBox(height: 16.h),
        // ▼ UPGRADED: Account number field with strict validation
        TextFormField(
          initialValue: state.tempAccountNumber,
          onChanged: (value) => context.read<PayoutBloc>().add(AccountNumberChanged(value)),
          keyboardType: TextInputType.number,
          // This is the core of the validation logic
          inputFormatters: [
            LengthLimitingTextInputFormatter(10), // Enforces 10-digit limit
            FilteringTextInputFormatter.digitsOnly, // Allows only numbers
          ],
          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            prefixIcon: Icon(Iconsax.card, color: KorraColors.textMuted, size: 20.sp),
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
  // ... (Helper widgets: _buildVerificationSuffix, _buildVerifiedName, _buildActionButtons)
}

//== THE WORLD-CLASS BANK SEARCH FIELD ==//
// This widget is a masterclass in custom UI, using an Overlay to create
// a seamless, integrated search experience.
class _BankSearchField extends StatefulWidget {
  final List<Bank> bankList;
  final Bank? selectedBank;
  final Function(Bank) onBankSelected;

  const _BankSearchField({required this.bankList, this.selectedBank, required this.onBankSelected});

  @override
  State<_BankSearchField> createState() => __BankSearchFieldState();
}

class __BankSearchFieldState extends State<_BankSearchField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  OverlayEntry? _overlayEntry;
  List<Bank> _filteredBanks = [];

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.bankList;
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onSearchChanged);
    if (widget.selectedBank != null) {
      _controller.text = widget.selectedBank!.name;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filteredBanks = widget.bankList
          .where((bank) =>
              bank.name.toLowerCase().contains(_controller.text.toLowerCase()))
          .toList();
      _overlayEntry?.markNeedsBuild(); // Rebuild the overlay with the filtered list
    });
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 8.h,
        width: size.width,
        child: Material(
          color: Colors.grey[200],
          elevation: 4.0,
          borderRadius: BorderRadius.circular(12.r),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200.h),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _filteredBanks.length,
              itemBuilder: (context, index) {
                final bank = _filteredBanks[index];
                return ListTile(
                  title: Text(bank.name, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted)),
                  onTap: () {
                    _controller.text = bank.name;
                    widget.onBankSelected(bank);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: LayerLink(),
      child: TextFormField(
        focusNode: _focusNode,
        controller: _controller,
        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(
          prefixIcon: Icon(Iconsax.bank, color: KorraColors.textMuted, size: 20.sp),
          labelText: 'Search & Select Bank',
        ),
      ),
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