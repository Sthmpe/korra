import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_products_body.dart';
import 'widgets/add_product_page.dart';

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
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: KorraHeader(
              title: 'Products',
              trailingActions: [
                // Minimalist "Add" Button
                IconButton(
                  onPressed: () async {
                    // 1. ✅ Await the Navigation (Wait for it to come back)
                    await Get.to(() => MultiBlocProvider(
                      providers: [
                        // Pass existing Product Bloc
                        BlocProvider.value(
                          value: context.read<VendorProductsBloc>()
                        ),
                        // Create NEW Image Bloc for the form
                        BlocProvider(
                          create: (_) => ImageBloc(),
                        ),
                      ],
                      child: AddProductPage(
                        vendors: vendors, 
                        vendorUid: vendorUid
                      ),
                    ));

                    // 2. ✅ Trigger Refresh when back
                    if (context.mounted) {
                      context.read<VendorProductsBloc>().add(
                        const VendorProductsRefresh()
                      );
                    }
                  },
                  icon: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4ED), // Light orange bg
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.add, 
                      color: const Color(0xFFA54600), 
                      size: 24.sp
                    ),
                  ),
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