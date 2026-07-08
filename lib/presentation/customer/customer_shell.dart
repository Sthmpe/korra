import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'plans/widgets/clipboard_scanner_helper.dart';

import '../../data/repository/customer/customer_repository.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_bloc.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_event.dart';
import '../../logic/bloc/bottom_nav/bottom_nav_state.dart';
import 'home/home_page.dart';
import 'storefront/widgets/cart_service.dart';
import 'store/store_page.dart';
import 'plans/plans_page.dart';
import 'profile/profile_page.dart';
import '../shared/widgets/korra_bottom_nav.dart';
import '../shared/widgets/lazy_indexed_stack.dart';

class CustomerShell extends StatelessWidget {
  final String uid;
  const CustomerShell({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => CustomerRepository(),
      child: _CustomerShellBody(uid: uid),
    );
  }
}

class _CustomerShellBody extends StatefulWidget {
  final String uid;
  const _CustomerShellBody({required this.uid});

  @override
  State<_CustomerShellBody> createState() => _CustomerShellBodyState();
}

class _CustomerShellBodyState extends State<_CustomerShellBody> with WidgetsBindingObserver {
  final customerPageIcons = const [
    NavSpec('Home', Icons.home_outlined, Icons.home_rounded),
    NavSpec('Plans', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    NavSpec('Stores', Icons.storefront_outlined, Icons.storefront_rounded),
    NavSpec('Profile', Icons.person_outline, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restore saved carts (and purge >1 week old ones) so the Stores tab
    // signal badge can nudge unfinished checkouts.
    CartService.instance.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (!mounted) return;
    final repo = context.read<CustomerRepository>();
    await ClipboardScannerHelper.checkClipboardAndPrompt(context, repo, widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // still lets inner widgets get taps
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: BlocProvider(
        create: (_) => BottomNavBloc(),
        child: BlocBuilder<BottomNavBloc, BottomNavState>(
          builder: (context, state) {
            final repo = context.read<CustomerRepository>();
            final navBloc = context.read<BottomNavBloc>();
      
            final pages = [
              HomePage(customerUid: widget.uid, onJumpTo: (v) => navBloc.add(BottomNavChanged(v)), onJumpToPlan: () => navBloc.add(BottomNavChanged(1)),  ),
              PlansPage(customerUid: widget.uid, onJumpToHome: () => navBloc.add(BottomNavChanged(0)), onJumpToPlan: () => navBloc.add(BottomNavChanged(1)),),
              StorePage(customerUid: widget.uid),
              ProfilePage(customerUid: widget.uid),
            ];
      
            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // const GlobalOfflineBanner(),
                    Expanded(
                      child: LazyIndexedStack(index: state.index, children: pages),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: ValueListenableBuilder(
                valueListenable: CartService.instance.cartsNotifier,
                builder: (context, carts, _) => KorraBottomNav(
                  currentIndex: state.index,
                  pageIcons: customerPageIcons,
                  // Animated signal on the Stores tab while any cart is unfinished
                  signalBadges: carts.isNotEmpty ? const {2} : const {},
                  onTap: (i) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    navBloc.add(BottomNavChanged(i));
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
