import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/payout/bank.dart';

class BankSearchField extends StatefulWidget {
  final List<Bank> bankList;
  final Bank? selectedBank;
  final Function(Bank) onBankSelected;

  const BankSearchField({
    super.key,
    required this.bankList,
    this.selectedBank,
    required this.onBankSelected,
  });

  @override
  State<BankSearchField> createState() => _BankSearchFieldState();
}

class _BankSearchFieldState extends State<BankSearchField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  OverlayEntry? _overlayEntry;
  List<Bank> _filteredBanks = [];
  final LayerLink _layerLink = LayerLink();

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
    _controller.removeListener(_onSearchChanged);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    });
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        const double itemHeight = 55.0;
        const double maxHeight = 220.0;
        final resultCount = _filteredBanks.length;
        final double calculatedHeight =
            (resultCount * itemHeight).clamp(0.0, maxHeight);

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 8.h),
            child: Material(
              elevation: 8.0,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              shadowColor: Colors.black.withOpacity(0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: calculatedHeight,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: _filteredBanks.length,
                  itemBuilder: (context, index) {
                    final bank = _filteredBanks[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: bank.logoUrl ?? '',
                          width: 36.w,
                          height: 36.w,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              Container(color: KorraColors.inputFill),
                          errorWidget: (context, url, error) => Container(
                            color: KorraColors.inputFill,
                            child: Icon(
                              Iconsax.bank,
                              color: KorraColors.textMuted.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        bank.name,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
      },
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
      link: _layerLink,
      child: TextFormField(
        focusNode: _focusNode,
        controller: _controller,
        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(
          prefixIcon: Icon(
            Iconsax.search_normal_1,
            color: KorraColors.textMuted,
            size: 20.sp,
          ),
          labelText: 'Search & Select Bank',
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String labelText, Widget? prefixIcon}) {
    return InputDecoration(
        prefixIcon: prefixIcon,
        labelText: labelText,
        labelStyle: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted),
        filled: true,
        fillColor: KorraColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: KorraColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: KorraColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: KorraColors.brand, width: 2.0)),
    );
}