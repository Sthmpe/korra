import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'update_cubit.dart';
import 'update_required_sheet.dart';

class KorraUpdateGate extends StatefulWidget {
  final Widget child;
  const KorraUpdateGate({super.key, required this.child});

  @override
  State<KorraUpdateGate> createState() => _KorraUpdateGateState();
}

class _KorraUpdateGateState extends State<KorraUpdateGate> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
     context.read<UpdateCubit>().checkForUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🚀 Check on Resume (If they went to store and came back)
    if (state == AppLifecycleState.resumed) {
      context.read<UpdateCubit>().checkForUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        return Stack(
          children: [
            // 1. The App Content (Always underneath)
            widget.child,

            // 2. The Blocking Update Screen
            // We use AnimatedSwitcher for a smooth fade-in effect
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: state.isUpdateRequired
                  ? Container(
                      key: const ValueKey('UpdateScreen'),
                      color: Colors.white, // Ensure opacity covers app
                      child: UpdateRequiredSheet(
                        version: state.version ?? 'New',
                        url: state.updateUrl ?? '',
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('Empty')),
            ),
          ],
        );
      },
    );
  }
}