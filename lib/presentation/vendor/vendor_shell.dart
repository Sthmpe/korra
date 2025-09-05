import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

// VITAL: Ensure these imports are present
// import '../../config/constants/colors.dart';
import '../../data/repository/vendors/vendor_repository.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_state.dart';
import '../../logic/core/net/global_offline_banner.dart';
import '../auth/role_login/role_login_screen.dart';
import '../shared/widgets/korra_bottom_nav.dart';
import 'home/home_page.dart';
import 'product/products_page.dart';
import 'profile/profile_page.dart';
import 'reservation/reservations_page.dart';

class VendorShell extends StatelessWidget {
  const VendorShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => const RoleLoginScreen());
      });
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Icon
              Icon(
                Icons.wallet_rounded, // replace with your brand icon
                size: 64,
                color: Color(0xFF6A1B9A), // premium purple tone
              ),
              SizedBox(height: 24),

              // Premium Loading Indicator
              CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
              ),
              SizedBox(height: 16),

              // Beautiful Text
              Text(
                "Preparing your dashboard...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final uid = user.uid;

    // ▼ THIS IS THE ARCHITECTURAL FIX ▼
    // The repository is provided here, at the root of the shell.
    // It becomes a foundational service for all descendant widgets.
    return RepositoryProvider(
      create: (context) => VendorRepository(),
      child: BlocProvider(
        create: (_) => BottomNavBloc(),
        child: BlocBuilder<BottomNavBloc, BottomNavState>(
          builder: (context, state) {
            // We now safely read the single, authoritative instance of the repository.
            final repo = context.read<VendorRepository>();

            final items = const [
              NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
              NavSpec(
                'Products',
                Icons.inventory_2_outlined,
                Icons.inventory_2_rounded,
              ),
              NavSpec(
                'Reservations',
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
              ),
              NavSpec('Profile', Icons.person_outline, Icons.person_rounded),
            ];

            // All pages now receive the same repository instance.
            final pages = [
              VendorHomePage(vendors: repo, vendorUid: uid),
              VendorProductsPage(),
              VendorReservationsPage(),
              VendorProfilePage(),
            ];

            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const GlobalOfflineBanner(),
                    Expanded(
                      child: IndexedStack(index: state.index, children: pages),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: KorraBottomNav(
                currentIndex: state.index,
                items: items,
                onTap: (i) =>
                    context.read<BottomNavBloc>().add(BottomNavChanged(i)),
              ),
            );
          },
        ),
      ),
    );
  }
}
