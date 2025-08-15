import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/bloc/customer_shell/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/customer_shell/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/customer_shell/bottom_nav/bottom_nav_state.dart';
import 'home/home_page.dart';
import 'plans/plans_page.dart';
import 'profile/profile_page.dart';
import 'widgets/korra_bottom_nav.dart';

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
            bottomNavigationBar: KorraBottomNav(
              currentIndex: state.index,
              onTap: (i) => context.read<BottomNavBloc>().add(BottomNavChanged(i)),
            ),
          );
        },
      ),
    );
  }
}
