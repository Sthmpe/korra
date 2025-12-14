import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/customer/plans.dart';
import '../widgets/plan_card.dart'; // Reuse your card!

class PlanSearchDelegate extends SearchDelegate<String?> {
  final List<Plan> sourcePlans; // We search inside this list
  
  PlanSearchDelegate({required this.sourcePlans});

  // 1. Engineering Polish: Match App Theme
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B1B1B)),
        toolbarHeight: 60.h,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.inter(fontSize: 16.sp, color: Colors.grey.shade400),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: GoogleFonts.inter(fontSize: 16.sp, color: const Color(0xFF1B1B1B), fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  String? get searchFieldLabel => 'Search plans, stores...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    // 2. Logic: Filter locally
    final results = sourcePlans.where((p) {
      final q = query.toLowerCase().trim();
      return p.title.toLowerCase().contains(q) ||
             p.storeName.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text("No plans found for '$query'", style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 16.h),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final plan = results[index];
        // 3. Reuse your PlanCard for consistency
        return PlanCard(
          plan: plan,
          onPayNow: () {}, // Handle pay
          onView: () {},   // Handle view
          onMenu: () {},
        );
      },
    );
  }
}