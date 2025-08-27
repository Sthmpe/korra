import 'dart:async';
import '../../models/customer/plan.dart';
import '../../models/customer/vendor.dart';
import '../../models/customer/activity_item.dart';

class HomeRepository {
  Future<String> fetchWalletBalance() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '₦75,500.00';
  }

  Future<String> fetchDefaultMethodMasked() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return '•••• 4242';
  }

  Future<List<Plan>> fetchPlans() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // e.g. in HomeRepository or a demo_data.dart file
    const demoPlans = <Plan>[
      Plan(
        id: 'p1',
        title: 'iPhone 13 128GB',
        vendor: 'GadgetPlug',
        imageUrl:
            'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=1200',
        progress: 45,
        nextDue: 'Due Fri',
        amountPaidText: '₦75,500',
        amountRemainText: '₦224,500',
        cadenceText: 'Weekly plan',
        nextAmountText: '₦12,500',
      ),
      Plan(
        id: 'p2',
        title: 'LG OLED C2 55″',
        vendor: 'HomeKraft',
        imageUrl:
            'https://images.unsplash.com/photo-1586822417800-9c7b7d79a4b5?w=1200',
        progress: 30,
        nextDue: 'Due Tue',
        amountPaidText: '₦150,000',
        amountRemainText: '₦650,000',
        cadenceText: 'Monthly plan',
        nextAmountText: '₦65,000',
      ),
      // FASHION — Sneakers
      Plan(
        id: 'p3',
        title: 'Air Max 270 Sneakers',
        vendor: 'SneakHub',
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200',
        progress: 60,
        nextDue: 'Due Mon',
        amountPaidText: '₦28,000',
        amountRemainText: '₦18,000',
        cadenceText: 'Daily plan',
        nextAmountText: '₦2,000',
      ),
      // FASHION — Denim Jacket
      Plan(
        id: 'p4',
        title: 'Men’s Denim Jacket',
        vendor: 'StyleStreet',
        imageUrl:
            'https://images.unsplash.com/photo-1548883354-7622d3f7ad24?w=1200',
        progress: 20,
        nextDue: 'Due Thu',
        amountPaidText: '₦6,500',
        amountRemainText: '₦26,000',
        cadenceText: 'Weekly plan',
        nextAmountText: '₦3,250',
      ),
      // FASHION — Leather Tote
      Plan(
        id: 'p5',
        title: 'Leather Tote Bag',
        vendor: 'BellaModa',
        imageUrl:
            'https://images.unsplash.com/photo-1547949003-9792a18a2601?w=1200',
        progress: 75,
        nextDue: 'Due Today',
        amountPaidText: '₦45,000',
        amountRemainText: '₦15,000',
        cadenceText: 'Weekly plan',
        nextAmountText: '₦5,000',
      ),
      // FASHION — Summer Dress
      Plan(
        id: 'p6',
        title: 'Floral Summer Dress',
        vendor: 'BellaModa',
        imageUrl:
            'https://images.unsplash.com/photo-1503342217505-b0a15cf70489?w=1200',
        progress: 10,
        nextDue: 'Due Sat',
        amountPaidText: '₦4,000',
        amountRemainText: '₦36,000',
        cadenceText: 'Monthly plan',
        nextAmountText: '₦6,000',
      ),
      // Electronics — PS5
      Plan(
        id: 'p7',
        title: 'PlayStation 5',
        vendor: 'TechHub NG',
        imageUrl:
            'https://images.unsplash.com/photo-1606813907291-76a5ebc5a1ab?w=1200',
        progress: 55,
        nextDue: 'Due Wed',
        amountPaidText: '₦210,000',
        amountRemainText: '₦170,000',
        cadenceText: 'Weekly plan',
        nextAmountText: '₦17,000',
      ),
      // Laptop
      Plan(
        id: 'p8',
        title: 'MacBook Air M2',
        vendor: 'GadgetPlug',
        imageUrl:
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200',
        progress: 35,
        nextDue: 'Due Fri',
        amountPaidText: '₦320,000',
        amountRemainText: '₦590,000',
        cadenceText: 'Monthly plan',
        nextAmountText: '₦59,000',
      ),
    ];
    return demoPlans;
  }

  Future<List<Vendor>> fetchSavedVendors() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return Vendor.dummies();
  }

  Future<List<ActivityItem>> fetchActivity() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ActivityItem.dummies();
  }
}
