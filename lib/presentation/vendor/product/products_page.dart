import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_products_body.dart';
import 'widgets/Add_product_page.dart';

class VendorProductsPage extends StatelessWidget {
  final VendorRepository vendors;
  final String vendorUid;
  const VendorProductsPage({
    super.key,
    required this.vendors,
    required this.vendorUid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorProductsBloc(
        vendors: vendors,
        vendorUid: vendorUid,
        net: context.read<NetCubit>(),
      )..add(const VendorProductsStarted()),
      child: Builder(
        // 👈 forces rebuild with the provider in scope
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: KorraHeader(
              title: 'Products',
              trailingActions: [
                _IconBtn(
                  icon: MdiIcons.plus,
                  onTap: () {
                    Get.to(
                      () => MultiBlocProvider(
                        providers: [
                          // Pass the existing bloc instance
                          BlocProvider.value(
                            value: context.read<VendorProductsBloc>(),
                          ),

                          // Create a new bloc instance
                          BlocProvider(create: (_) => ImageBloc()),
                        ],
                        // ✅ now works
                        child: AddProductPage(
                          vendors: vendors,
                          vendorUid: vendorUid
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: const VendorProductsBody(),
          );
        },
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100.r),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20.sp, color: const Color(0xFFA54600)),
      label: Text(
        "Add product",
        style: GoogleFonts.inter(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFA54600),
        ),
      ),
    );
  }
}
