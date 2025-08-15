import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/bloc/customer_shell/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/customer_shell/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/customer_shell/bottom_nav/bottom_nav_state.dart';
import 'home/home_page.dart';
import 'plans/plans_page.dart';
import 'profile/profile_page.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomNavBloc(),
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, state) {
          final pages = const [HomePage(), PlansPage(), ProfilePage()];
          return Scaffold(
            body: IndexedStack(index: state.index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: state.index,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Plans',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
              onDestinationSelected: (i) =>
                  context.read<BottomNavBloc>().add(BottomNavChanged(i)),
            ),
          );
        },
      ),
    );
  }
}
