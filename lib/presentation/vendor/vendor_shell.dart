import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// VITAL: Ensure these imports are present
import '../../data/repository/vendors/vendor_repository.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_state.dart';
// import '../../logic/core/net/global_offline_banner.dart';
import '../shared/widgets/korra_bottom_nav.dart';
import 'home/home_page.dart';
import 'product/products_page.dart';
import 'profile/profile_page.dart';
import 'reservation/reservations_page.dart';

class VendorShell extends StatelessWidget {
  final String uid;
  const VendorShell({super.key, required this.uid});

  final vendorsPageIcons = const [
    NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
    NavSpec('Products', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    NavSpec(
      'Reservations',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    NavSpec('Profile', Icons.person_outline, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    // ▼ THIS IS THE ARCHITECTURAL FIX ▼
    // The repository is provided here, at the root of the shell.
    // It becomes a foundational service for all descendant widgets.
    return RepositoryProvider(
      create: (context) => VendorRepository(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // still lets inner widgets get taps
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: BlocProvider(
          create: (_) => BottomNavBloc(),
          child: BlocBuilder<BottomNavBloc, BottomNavState>(
            builder: (context, state) {
              // We now safely read the single, authoritative instance of the repository.
              final repo = context.read<VendorRepository>();
        
              // All pages now receive the same repository instance.
              final pages = [
                VendorHomePage(vendors: repo, vendorUid: uid),
                VendorProductsPage(vendors: repo, vendorUid: uid),
                VendorReservationsPage(),
                VendorProfilePage(vendors: repo, vendorUid: uid),
              ];
        
              return Scaffold(
                body: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // const GlobalOfflineBanner(),
                      Expanded(
                        child: IndexedStack(index: state.index, children: pages),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: KorraBottomNav(
                  currentIndex: state.index,
                  pageIcons: vendorsPageIcons,
                  onTap: (i) =>
                      context.read<BottomNavBloc>().add(BottomNavChanged(i)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
