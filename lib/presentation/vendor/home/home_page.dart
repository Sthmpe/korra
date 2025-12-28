import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../../logic/services/notification_service.dart'; // Reuse service
import '../../shared/widgets/korra_header.dart';
import 'vendor_home_body.dart';
import 'widgets/notification_screen.dart';

class VendorHomePage extends StatefulWidget {
  final VendorRepository vendors;
  final String vendorUid;

  const VendorHomePage({
    super.key,
    required this.vendors,
    required this.vendorUid,
  });

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  
  @override
  void initState() {
    super.initState();
    // 🔔 Initialize Push Notifications
    NotificationService(widget.vendors).initialize(widget.vendorUid);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => VendorHomeBloc(
            vendors: widget.vendors,
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
            StreamBuilder<int>(
              stream: widget.vendors.streamUnreadCount(widget.vendorUid),
              initialData: 0,
              builder: (context, notifSnap) {
                final count = notifSnap.data ?? 0;
                final hasUnread = count > 0;

                return IconButton(
                  onPressed: () {
                    Get.to(() => NotificationScreen(
                      vendorUid: widget.vendorUid,
                    ));
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Iconsax.notification, color: const Color(0xFF1B1B1B), size: 24.sp),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          ],
        ),

        // --- 2. BODY ---
        body: VendorHomeBody(
          vendors: widget.vendors,
          vendorUid: widget.vendorUid,
        ),
      ),
    );
  }
}