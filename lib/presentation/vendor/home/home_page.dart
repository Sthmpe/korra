import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/routes/app_routes.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../../logic/services/notification_service.dart'; // Reuse service
import '../../shared/widgets/korra_header.dart';
import 'vendor_home_body.dart';

class VendorHomePage extends StatefulWidget {
  final String vendorUid;

  const VendorHomePage({
    super.key,
    required this.vendorUid,
  });

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  late final VendorRepository _vendors;
  
  @override
  void initState() {
    super.initState();
    _vendors = context.read<VendorRepository>();
    // 🔔 Initialize Push Notifications
    NotificationService.to.initialize(_vendors, widget.vendorUid);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => VendorHomeBloc(
            vendors: _vendors,
            vendorUid: widget.vendorUid,
            net: context.read<NetCubit>(),
          )..add(const VendorHomeStarted()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        
        // --- 1. APP BAR (Bell Wired Up) ---
        appBar: KorraHeader(
          title: 'Home',
          trailingActions: [
            IconButton(
              onPressed: () {
                Get.toNamed(
                  Routes.vendorNotifications,
                  arguments: {'uid': widget.vendorUid},
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Iconsax.notification, color: const Color(0xFF1B1B1B), size: 24.sp),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: StreamBuilder<int>(
                      stream: _vendors.streamUnreadCount(widget.vendorUid),
                      initialData: 0,
                      builder: (context, notifSnap) {
                        final count = notifSnap.data ?? 0;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // --- 2. BODY ---
        body: VendorHomeBody(
          vendorUid: widget.vendorUid,
        ),
      ),
    );
  }
}