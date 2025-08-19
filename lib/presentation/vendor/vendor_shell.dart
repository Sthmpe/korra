import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/bloc/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_state.dart';

// Placeholder pages
import '../shared/widgets/korra_bottom_nav.dart';
import 'home/home_page.dart';
import 'product/products_page.dart';
import 'profile/profile_page.dart';
import 'reservation/reservations_page.dart';

class VendorShell extends StatelessWidget {
  const VendorShell({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      NavSpec('Home',         Icons.home_outlined,         Icons.home_rounded),
      NavSpec('Products',     Icons.inventory_2_outlined,  Icons.inventory_2_rounded),
      NavSpec('Reservations', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      NavSpec('Profile',      Icons.person_outline,        Icons.person_rounded),
    ];

    final pages = const [
      VendorHomePage(),
      VendorProductsPage(),
      VendorReservationsPage(),
      VendorProfilePage(),
    ];

    return BlocProvider(
      create: (_) => BottomNavBloc(),
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, state) {
          return Scaffold(
            body: IndexedStack(index: state.index, children: pages),
            bottomNavigationBar: KorraBottomNav(
              currentIndex: state.index,
              items: items,
              onTap: (i) => context.read<BottomNavBloc>().add(BottomNavChanged(i)),
              // optional badges:
              // countBadges: {2: reservationsCount},
              // dotBadges: {0},
            ),
          );
        },
      ),
    );
  }
}
