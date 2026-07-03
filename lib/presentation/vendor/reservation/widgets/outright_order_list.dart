// lib/presentation/vendor/reservation/widgets/outright_order_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/vendor/outright_order.dart';
import 'outright_order_tile.dart';

class OutrightOrderList extends StatelessWidget {
  final bool loading;
  final List<OutrightOrder> items;
  final Function(String) onOpen;

  const OutrightOrderList({
    super.key,
    required this.loading,
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              "No orders found",
              style: GoogleFonts.inter(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return OutrightOrderTile(
            order: item,
            onTap: () => onOpen(item.id),
          );
        },
        childCount: items.length,
      ),
    );
  }
}
