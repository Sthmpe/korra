import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/customer_account_stats.dart';
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import 'rows.dart';

class LevelUpSlotsRow extends StatelessWidget {
  final Customer customer;

  const LevelUpSlotsRow({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final customerRepo = context.read<CustomerRepository>();
    return StreamBuilder<CustomerAccountStats?>(
      stream: customerRepo.streamCustomerStats(customer.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? CustomerAccountStats.empty(customer.uid);
        return RowWithChevron(
          icon: Iconsax.trend_up,
          title: 'Level Up Slots',
          subtitle: 'Unlock more reservation slots',
          onTap: () {
            Get.toNamed(
              Routes.customerLimitUpgrade,
              arguments: {
                'customer': customer,
                'currentMaxSlots': stats.maxSlots,
                'completedPlansCount': stats.completedPlansCount,
              },
            );
          },
        );
      },
    );
  }
}
