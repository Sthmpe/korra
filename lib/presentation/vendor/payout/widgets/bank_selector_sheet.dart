import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/bank.dart';
import 'korra_button.dart';

class BankSelectorSheet extends StatefulWidget {
  final List<Bank> banks;
  final Future<String> Function(String bankCode, String accountNumber) onValidate;
  final Function(Bank bank, String accountNumber, String accountName) onConfirm;

  const BankSelectorSheet({
    super.key,
    required this.banks,
    required this.onValidate,
    required this.onConfirm,
  });

  @override
  State<BankSelectorSheet> createState() => _BankSelectorSheetState();
}

class _BankSelectorSheetState extends State<BankSelectorSheet> {
  final _bankSearchController = TextEditingController();
  final _accNumController = TextEditingController();
  final FocusNode _bankFocus = FocusNode();

  List<Bank> _filteredBanks = [];
  Bank? _selectedBank;
  bool _isSearching = false;
  
  bool _isValidating = false;
  String? _resolvedName;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.banks;
    _bankSearchController.addListener(_onSearchChanged);
    _accNumController.addListener(_onAccountNumChanged);
    
    // Auto-hide list when focus lost
    _bankFocus.addListener(() {
      if (!_bankFocus.hasFocus) {
        // Small delay to allow tap registration on list items
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isSearching = false);
        });
      } else {
        setState(() => _isSearching = true);
      }
    });
  }

  @override
  void dispose() {
    _bankSearchController.dispose();
    _accNumController.dispose();
    _bankFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _bankSearchController.text.toLowerCase();
    setState(() {
      _filteredBanks = widget.banks
          .where((b) => b.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onAccountNumChanged() {
    // Reset validation if user types
    if (_resolvedName != null || _validationError != null) {
      setState(() {
        _resolvedName = null;
        _validationError = null;
      });
    }
    // Auto-Validate at exactly 10 digits
    if (_accNumController.text.length == 10 && _selectedBank != null) {
      _validateAccount();
    }
  }

  Future<void> _validateAccount() async {
    setState(() { _isValidating = true; _validationError = null; });

    try {
      final name = await widget.onValidate(_selectedBank!.code, _accNumController.text);
      if (mounted) {
        setState(() { _resolvedName = name; _isValidating = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _validationError = "Account not found. Check details."; 
          _isValidating = false; 
        });
      }
    }
  }

  void _selectBank(Bank bank) {
    setState(() {
      _selectedBank = bank;
      _bankSearchController.text = bank.name;
      _isSearching = false; // Hide list
      _bankFocus.unfocus();
    });
    // Re-validate if number exists
    if (_accNumController.text.length == 10) _validateAccount();
  }

  @override
  Widget build(BuildContext context) {
    // Height constraint for list
    final listHeight = (_filteredBanks.length * 60.h).clamp(0.0, 240.h).toDouble();

    return Padding(
      // Push up for keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Handle Bar
              Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 24.h),
              
              // 2. Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: const BoxDecoration(color: Color(0xFFF2F4F7), shape: BoxShape.circle),
                    child: Icon(Iconsax.bank, color: Colors.grey.shade700, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "Link Bank Account", 
                    style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828))
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // 3. BANK SEARCH INPUT
              Text("Bank Name", style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
              SizedBox(height: 8.h),
              
              TextField(
                controller: _bankSearchController,
                focusNode: _bankFocus,
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                decoration: InputDecoration(
                  hintText: "Select your bank",
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Iconsax.search_normal, size: 18, color: Color(0xFF667085)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  suffixIcon: _selectedBank != null 
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey), 
                          onPressed: () {
                            _bankSearchController.clear();
                            setState(() { _selectedBank = null; _filteredBanks = widget.banks; });
                          }
                        ) 
                      : null,
                ),
              ),

              // 4. SEARCH RESULTS (Animated)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isSearching ? listHeight : 0,
                margin: _isSearching ? EdgeInsets.only(top: 8.h) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: ListView.separated(
                  itemCount: _filteredBanks.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_,__) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final bank = _filteredBanks[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectBank(bank),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          child: Row(
                            children: [
                              bank.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: CachedNetworkImage(
                                      imageUrl: bank.logoUrl!,
                                      width: 24.w, height: 24.w,
                                      errorWidget: (_,__,___) => const Icon(Iconsax.bank, size: 20),
                                    ),
                                  )
                                : Icon(Iconsax.bank, size: 20, color: Colors.grey),
                              SizedBox(width: 12.w),
                              Expanded(child: Text(bank.name,overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20.h),

              // 5. ACCOUNT NUMBER INPUT
              Text("Account Number", style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
              SizedBox(height: 8.h),
              TextField(
                controller: _accNumController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: 2.0, color: const Color(0xFF101828)),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "0000000000",
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade300, fontWeight: FontWeight.w500, letterSpacing: 2.0),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  // Spinner inside
                  suffixIcon: _isValidating
                      ? Padding(
                          padding: EdgeInsets.all(12.r),
                          child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: KorraColors.brand)),
                        )
                      : null,
                ),
              ),

              SizedBox(height: 16.h),

              // 6. VALIDATION RESULT (Green Tick Style)
              if (_resolvedName != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1.0,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF12B76A), size: 20),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _resolvedName!,
                          style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_validationError != null)
                Row(
                  children: [
                    const Icon(Iconsax.info_circle, color: Color(0xFFD92D20), size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      _validationError!,
                      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: const Color(0xFFD92D20)),
                    ),
                  ],
                ),

              SizedBox(height: 32.h),

              // 7. ACTION BUTTON
              KorraButton(
                text: "Confirm Account",
                onPressed: (_resolvedName != null && _selectedBank != null) 
                    ? () => widget.onConfirm(_selectedBank!, _accNumController.text, _resolvedName!)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}