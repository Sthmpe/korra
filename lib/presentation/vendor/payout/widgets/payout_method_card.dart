import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../logic/bloc/vendor/payout/payout_state.dart';
import 'payout_display_view.dart';
import 'payout_edit_view.dart';

class PayoutMethodCard extends StatelessWidget {
  final PayoutState state;
  const PayoutMethodCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: state.isEditingMethod
              ? PayoutEditView(state: state)
              : PayoutDisplayView(state: state),
        ),
      ),
    );
  }
}