import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanSearchDelegate extends SearchDelegate<String?> {
  PlanSearchDelegate({String? initial}) {
    query = initial ?? '';
  }

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Text(
        'Type a product or vendor name…',
        style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E)),
      ),
    );
  }
}
