import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/constants/vendor_categories.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';

class StepStoreDetails extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepStoreDetails({super.key, required this.formKey});

  @override
  State<StepStoreDetails> createState() => _StepStoreDetailsState();
}

class _StepStoreDetailsState extends State<StepStoreDetails> {
  late final TextEditingController _storeCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    _storeCtl = TextEditingController(text: s.storeName)..addListener(() => _on(StoreNameChanged(_storeCtl.text)));
  }
  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);
  @override void dispose() { _storeCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(16.r),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store details', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 12.h),
          
              TextFormField(
                controller: _storeCtl,
                validator: (v) => KorraValidators.name(v, field: 'Store name'),
                style: GoogleFonts.inter(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  labelText: 'Store name',
                  labelStyle: GoogleFonts.inter(fontSize: 13.5.sp),
                  errorStyle: GoogleFonts.inter(fontSize: 12.sp),
                  prefixIcon: Icon(Iconsax.shop, size: 18.sp),
                  filled: true,
                ),
              ),
              SizedBox(height: 12.h),
          
              Text('Presence', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _presenceChip('Online', Presence.online, s.presence),
                  SizedBox(width: 8.w),
                  _presenceChip('Physical', Presence.physical, s.presence),
                  SizedBox(width: 8.w),
                  _presenceChip('Both', Presence.both, s.presence),
                ],
              ),
              SizedBox(height: 14.h),
          
              Text('Product categories (select 1–5)', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w, runSpacing: 8.h,
                children: [
                  for (final c in korraVendorCategories)
                    FilterChip(
                      showCheckmark: false,
                      label: Text(c, style: GoogleFonts.inter(fontSize: 12.5.sp)),
                      selected: s.categories.contains(c),
                      onSelected: (sel) {
                        if (!sel && !s.categories.contains(c)) return;
                        if (sel && s.categories.length >= 5 && !s.categories.contains(c)) return;
                        _on(CategoryToggled(c));
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              if (s.categories.isEmpty)
                Text('Pick at least one category.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presenceChip(String label, Presence value, Presence group) {
    final selected = value == group;
    return InkWell(
      onTap: () => _on(PresenceChanged(value)),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: selected ? Colors.black87 : Colors.grey.shade300),
          color: selected ? Colors.grey.shade50 : Colors.white,
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
