import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/bloc/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_state.dart';
import 'home/home_page.dart';
import 'plans/plans_page.dart';
import 'profile/profile_page.dart';
import '../shared/widgets/korra_bottom_nav.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  final customerItems = const [
    NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
    NavSpec('Plans', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    NavSpec('Profile', Icons.person_outline, Icons.person_rounded),
  ];

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
              items: customerItems,
              currentIndex: state.index,
              onTap: (i) => context.read<BottomNavBloc>().add(BottomNavChanged(i)),
            ),
          );
        },
      ),
    );
  }
}
