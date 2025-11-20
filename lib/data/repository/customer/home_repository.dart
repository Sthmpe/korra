import 'dart:async';
import '../../models/customer/mock_plan.dart';
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
        storeName: 'GadgetPlug',
        vendorUid: 'v1',
        imageUrls: [
            'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=1200',
        ],
        progress: 45,
        nextDue: 'Due Fri',
        amountPaid: 75500,
        amountRemain: 224500,
        cadenceText: 'Weekly plan',
        nextAmount: 12500,
      ),
      Plan(
        id: 'p2',
        title: 'LG OLED C2 55″',
        storeName: 'HomeKraft',
        vendorUid: 'v2',
        imageUrls: [
            'https://images.unsplash.com/photo-1586822417800-9c7b7d79a4b5?w=1200',
        ],
        progress: 30,
        nextDue: 'Due Tue',
        amountPaid: 150000,
        amountRemain: 650000,
        cadenceText: 'Monthly plan',
        nextAmount: 65000,
      ),
      // FASHION — Sneakers
      Plan(
        id: 'p3',
        title: 'Air Max 270 Sneakers',
        storeName: 'SneakHub',
        vendorUid: 'v3',
        imageUrls: [
            'https://images.unsplash.com/photo-1513105737059-ff3d5c9e6f2b?w=1200',
        ],
        progress: 60,
        nextDue: 'Due Mon',
        amountPaid: 28000,
        amountRemain: 18000,
        cadenceText: 'Daily plan',
        nextAmount: 2000,
      ),
      // FASHION — Denim Jacket
      Plan(
        id: 'p4',
        title: 'Men’s Denim Jacket',
        storeName: 'StyleStreet',
        vendorUid: 'v4',
        imageUrls: [
            'https://images.unsplash.com/photo-1548883354-7622d3f7ad24?w=1200',
        ],
        progress: 20,
        nextDue: 'Due Thu',
        amountPaid: 6500,
        amountRemain: 26000,
        cadenceText: 'Weekly plan',
        nextAmount: 3250,
      ),
      // FASHION — Leather Tote
      Plan(
        id: 'p5',
        title: 'Leather Tote Bag',
        storeName: 'BellaModa',
        vendorUid: 'v5',
        imageUrls: [
            'https://images.unsplash.com/photo-1547949003-9792a18a2601?w=1200',
        ],
        progress: 75,
        nextDue: 'Due Today',
        amountPaid: 45000,
        amountRemain: 15000,
        cadenceText: 'Weekly plan',
        nextAmount: 5000,
      ),
      // Laptop
      Plan(
        id: 'p8',
        title: 'MacBook Air M2',
        storeName: 'GadgetPlug',
        vendorUid: 'v56',
        imageUrls: [
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200',
        ],
        progress: 35,
        nextDue: 'Due Fri',
        amountPaid: 320000,
        amountRemain: 590000,
        cadenceText: 'Monthly plan',
        nextAmount: 59000,
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
