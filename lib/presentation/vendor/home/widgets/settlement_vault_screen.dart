import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart'; // Adjust path

class SettlementVaultScreen extends StatefulWidget {
  const SettlementVaultScreen({super.key});

  @override
  State<SettlementVaultScreen> createState() => _SettlementVaultScreenState();
}

class _SettlementVaultScreenState extends State<SettlementVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- MOCK DATA ---
  final List<VaultItem> _mockItems = [
    // UPCOMING (LOCKED)
    VaultItem(
      title: "Iphone 14 Pro Max - Gold",
      amount: 450000,
      releaseDate: DateTime.now().add(const Duration(days: 2)),
      status: VaultStatus.locked,
      ref: "ORD-9928",
    ),
    VaultItem(
      title: "Nike Air Jordan 1",
      amount: 45000,
      releaseDate: DateTime.now().add(const Duration(days: 5)),
      status: VaultStatus.locked,
      ref: "ORD-1102",
    ),
    VaultItem(
      title: "Samsung 65' TV",
      amount: 120000,
      releaseDate: DateTime.now().add(const Duration(days: 9)),
      status: VaultStatus.locked,
      ref: "ORD-3321",
    ),
    // PAST (RELEASED)
    VaultItem(
      title: "PlayStation 5 Console",
      amount: 500000,
      releaseDate: DateTime.now().subtract(const Duration(days: 2)),
      status: VaultStatus.released,
      ref: "ORD-0012",
    ),
    VaultItem(
      title: "Gucci Handbag",
      amount: 85000,
      releaseDate: DateTime.now().subtract(const Duration(days: 5)),
      status: VaultStatus.released,
      ref: "ORD-8821",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Separate Lists
    final locked = _mockItems.where((e) => e.status == VaultStatus.locked).toList();
    final released = _mockItems.where((e) => e.status == VaultStatus.released).toList();
    
    // Calculate Total Locked
    final totalLocked = locked.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light Grey Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Settlement Vault", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16.sp)),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. HERO CARD (Total Locked)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.r),
            color: Colors.white,
            child: Column(
              children: [
                Text("Total Locked Funds", style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500)),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("₦", style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade400)),
                    Text(
                      NumberFormat("#,##0.00").format(totalLocked),
                      style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: const Color(0xFF101828)),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4ED), // Light Orange
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.clock, size: 14.sp, color: const Color(0xFFA54600)),
                      SizedBox(width: 6.w),
                      Text("Next release in 2 days", style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFA54600), fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 2. TABS
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: KorraColors.brand,
              unselectedLabelColor: Colors.grey,
              indicatorColor: KorraColors.brand,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Released"),
              ],
            ),
          ),

          // 3. LISTS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(locked, isLocked: true),
                _buildList(released, isLocked: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<VaultItem> items, {required bool isLocked}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_search, size: 40.sp, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            Text("No transactions here", style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(20.r),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = items[index];
        return _VaultItemCard(item: item, isLocked: isLocked);
      },
    );
  }
}

// --- WIDGETS & MODELS ---

class _VaultItemCard extends StatelessWidget {
  final VaultItem item;
  final bool isLocked;

  const _VaultItemCard({required this.item, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    // Format Date: "12 Dec"
    final dateString = DateFormat('dd MMM').format(item.releaseDate);
    final dayString = DateFormat('EEEE').format(item.releaseDate); // "Monday"

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // 1. DATE BOX
          Container(
            width: 50.w,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFF9FAFB) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              children: [
                Text(
                  dateString.split(' ')[0], // Day (12)
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: isLocked ? Colors.black : const Color(0xFF027A48)),
                ),
                Text(
                  dateString.split(' ')[1].toUpperCase(), // Month (DEC)
                  style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 16.w),

          // 2. DETAILS (Title + Ref)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${item.ref} • ${dayString}",
                  style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // 3. AMOUNT + ICON
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₦${NumberFormat("#,##0").format(item.amount)}",
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: isLocked ? Colors.grey.shade700 : const Color(0xFF027A48)),
              ),
              SizedBox(height: 4.h),
              if (isLocked)
                Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 10.sp, color: const Color(0xFFA54600)),
                    SizedBox(width: 2.w),
                    Text("Locked", style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFFA54600), fontWeight: FontWeight.w600)),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 10.sp, color: const Color(0xFF027A48)),
                    SizedBox(width: 2.w),
                    Text("Released", style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF027A48), fontWeight: FontWeight.w600)),
                  ],
                )
            ],
          ),
        ],
      ),
    );
  }
}

// --- HELPER MODEL ---
enum VaultStatus { locked, released }

class VaultItem {
  final String title;
  final double amount;
  final DateTime releaseDate;
  final VaultStatus status;
  final String ref;

  VaultItem({
    required this.title,
    required this.amount,
    required this.releaseDate,
    required this.status,
    required this.ref,
  });
}