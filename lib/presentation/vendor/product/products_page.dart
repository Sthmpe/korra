import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/routes/app_routes.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_products_body.dart';

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
                    // 1. Capture the current bloc
                    final currentBloc = context.read<VendorProductsBloc>();

                    // 2. Navigate (Passing the bloc instance)
                    await Get.toNamed(
                      Routes.vendorAddProduct,
                      arguments: {
                        'repo': vendors,
                        'uid': vendorUid,
                        'listBloc': currentBloc, // 👈 PASSING THE BLOC HERE
                      },
                    );

                    // 3. Trigger Refresh when back (Optional, if your bloc didn't already handle it)
                    if (context.mounted) {
                      currentBloc.add(const VendorProductsRefresh());
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
            body: VendorProductsBody(
              vendors: vendors,
              vendorUid: vendorUid, // Placeholder, will be provided by Bloc
            ),
          );
        },
      ),
    );
  }
}