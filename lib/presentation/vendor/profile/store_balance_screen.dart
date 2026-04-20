import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/presentation/shared/widgets/korra_header.dart';

class StoreBalanceScreen extends StatefulWidget {
  final String vendorUid;

  const StoreBalanceScreen({Key? key, required this.vendorUid}) : super(key: key);

  @override
  State<StoreBalanceScreen> createState() => _StoreBalanceScreenState();
}

class _StoreBalanceScreenState extends State<StoreBalanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  // Pagination State
  final List<DocumentSnapshot> _customers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 15; // Load 15 at a time
  DocumentSnapshot? _lastDocument;

  // Totals for the Top Card
  double _totalBalance = 0;
  int _totalCustomersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTotals();
    _loadMoreData();

    // Listen to scroll events to trigger pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 && !_isLoading && _hasMore) {
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🧮 FETCH AGGREGATE TOTALS (Top Card)
  Future<void> _fetchTotals() async {
    try {
      final query = _firestore
          .collection('vendors')
          .doc(widget.vendorUid)
          .collection('customer_balances')
          .where('storeCredit', isGreaterThan: 0);

      final countQuery = await query.count().get();
      final sumQuery = await query.aggregate(sum('storeCredit')).get();

      if (mounted) {
        setState(() {
          _totalCustomersCount = countQuery.count ?? 0;
          _totalBalance = sumQuery.getSum('storeCredit') ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching totals: $e");
    }
  }

  // 🔄 PAGINATION LOGIC (List)
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = _firestore
          .collection('vendors')
          .doc(widget.vendorUid)
          .collection('customer_balances')
          .where('storeCredit', isGreaterThan: 0)
          .orderBy('storeCredit', descending: true) // Highest balances at the top
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _customers.addAll(snapshot.docs);
        
        if (snapshot.docs.length < _limit) {
          _hasMore = false; // Reached the end
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Pagination Error: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: KorraHeader(title: 'Store Balances', showLeadingIcon: true),
      body: Column(
        children: [
          // --- TOP SUMMARY CARD ---
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(24.w),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  'Total Outstanding Balance', 
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13.sp, fontWeight: FontWeight.w600)
                ),
                SizedBox(height: 8.h),
                Text(
                  '₦${_totalBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 32.sp, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), 
                    borderRadius: BorderRadius.circular(20.r), 
                    //border: Border.all(color: const Color(0xFFFFEDD5))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_alt_outlined, color: const Color(0xFFA54600), size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Held by $_totalCustomersCount customers', 
                        style: GoogleFonts.inter(color: const Color(0xFFA54600), fontWeight: FontWeight.w700, fontSize: 12.sp)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- LIST HEADER ---
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Customer Breakdown', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14.sp)),
                Text('Amount (₦)', style: GoogleFonts.inter(color: const Color(0xFF98A2B3), fontWeight: FontWeight.w600, fontSize: 11.sp, letterSpacing: 0.5)),
              ],
            ),
          ),

          // --- CUSTOMER LIST (PAGINATED) ---
          Expanded(
            child: _customers.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48.sp, color: Colors.grey[300]),
                        SizedBox(height: 16.h),
                        Text("No outstanding balances", style: GoogleFonts.inter(color: Colors.grey, fontSize: 14.sp, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: _customers.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      
                      // Show loader at the bottom if fetching more
                      if (index == _customers.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFFA54600))),
                        );
                      }

                      final data = _customers[index].data() as Map<String, dynamic>;
                      final String customerName = data['customerName'] ?? 'Customer';
                      final double balance = (data['storeCredit'] ?? 0.0).toDouble();
                      
                      String initials = customerName.isNotEmpty 
                          ? customerName.trim().split(' ').take(2).map((e) => e[0]).join().toUpperCase() 
                          : '?';

                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(12.r), 
                          //border: Border.all(color: const Color(0xFFF2F4F7))
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                          leading: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: const Color(0xFFF9FAFB),
                            foregroundColor: const Color(0xFF344054),
                            child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp)),
                          ),
                          title: Text(
                            customerName, 
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp, color: const Color(0xFF101828))
                          ),
                          trailing: Text(
                            '₦${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp, color: const Color(0xFF101828)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}