import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repository/customer/customer_repository.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_state.dart';
// import '../../logic/core/net/global_offline_banner.dart';
import 'home/home_page.dart';
import 'plans/plans_page.dart';
import 'profile/profile_page.dart';
import '../shared/widgets/korra_bottom_nav.dart';

class CustomerShell extends StatelessWidget {
  final String uid;
  const CustomerShell({super.key, required this.uid});

  final customerPageIcons = const [
    NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
    NavSpec('Plans', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    NavSpec('Profile', Icons.person_outline, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => CustomerRepository(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // still lets inner widgets get taps
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: BlocProvider(
          create: (_) => BottomNavBloc(),
          child: BlocBuilder<BottomNavBloc, BottomNavState>(
            builder: (context, state) {
              final repo = context.read<CustomerRepository>();
        
              final pages = [
                HomePage(customerRepo: repo, customerUid: uid),
                PlansPage(),
                ProfilePage(),
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
                  pageIcons: customerPageIcons,
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
