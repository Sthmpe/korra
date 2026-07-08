// lib/presentation/vendor/product/widgets/vendor_reviews_body.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../data/models/vendor/vendor_review.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class VendorReviewsBody extends StatefulWidget {
  final String vendorId;

  const VendorReviewsBody({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorReviewsBody> createState() => _VendorReviewsBodyState();
}

class _VendorReviewsBodyState extends State<VendorReviewsBody> {
  final List<VendorReview> _reviews = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _isLoadingStats = true;
  bool _hasMore = true;

  double _avgRating = 0.0;
  int _totalCount = 0;
  final Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStatsAndFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadStatsAndFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch ALL reviews to calculate stats breakdown
      final allSnap = await firestore
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('reviews')
          .get();

      double sum = 0.0;
      _starCounts.updateAll((key, value) => 0);
      for (final doc in allSnap.docs) {
        final r = VendorReview.fromFirestore(doc);
        sum += r.rating;
        final rounded = r.rating.round().clamp(1, 5);
        _starCounts[rounded] = (_starCounts[rounded] ?? 0) + 1;
      }
      _totalCount = allSnap.docs.length;
      _avgRating = _totalCount > 0 ? sum / _totalCount : 0.0;
      _isLoadingStats = false;

      // 2. Fetch first page of reviews (limit 10)
      final pageSnap = await firestore
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _reviews.clear();
      for (final doc in pageSnap.docs) {
        _reviews.add(VendorReview.fromFirestore(doc));
      }

      _lastDoc = pageSnap.docs.isNotEmpty ? pageSnap.docs.last : null;
      _hasMore = pageSnap.docs.length == 10;
      _isLoading = false;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading reviews: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final pageSnap = await firestore
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(10)
          .get();

      for (final doc in pageSnap.docs) {
        _reviews.add(VendorReview.fromFirestore(doc));
      }

      _lastDoc = pageSnap.docs.isNotEmpty ? pageSnap.docs.last : null;
      _hasMore = pageSnap.docs.length == 10;
      _isLoading = false;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading next page: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    _lastDoc = null;
    _hasMore = true;
    await _loadStatsAndFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStats && _reviews.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFA54600),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return _buildEmptyState(context);
    }

    final hasMock = _reviews.any((r) => r.isMock);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFA54600),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Demo Mode Banner
          if (hasMock)
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFFFF4ED),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFFA54600),
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "Demo mode active with mock reviews & orders.",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFA54600),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _clearMockData(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Clear Demo Data",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFA54600),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 1. Rating Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: _buildSummaryCard(),
            ),
          ),

          // 2. Reviews Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                'Customer Feedback ($_totalCount)',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: KorraColors.textDark,
                ),
              ),
            ),
          ),

          // 3. Reviews List
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = _reviews[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildReviewTile(review),
                  );
                },
                childCount: _reviews.length,
              ),
            ),
          ),

          // 4. Loading Footer
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA54600)),
                ),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(color: const Color(0xFFF2F4F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Average score
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _avgRating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                _buildStarRow(_avgRating, size: 14.sp),
                SizedBox(height: 8.h),
                Text(
                  '$_totalCount review${_totalCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            height: 90.h,
            width: 1,
            color: const Color(0xFFEAECF0),
            margin: EdgeInsets.symmetric(horizontal: 16.w),
          ),

          // Right side: Bar charts
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final starNum = 5 - index;
                final count = _starCounts[starNum] ?? 0;
                final pct = _totalCount > 0 ? count / _totalCount : 0.0;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        '$starNum',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: KorraColors.textDark,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.star,
                        size: 10.sp,
                        color: const Color(0xFFFFB000),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFF2F4F7),
                            color: const Color(0xFFFFB000),
                            minHeight: 6.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 24.w,
                        child: Text(
                          '${(pct * 100).round()}%',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(VendorReview review) {
    final initials = review.customerName.trim().isNotEmpty
        ? review.customerName.trim()[0].toUpperCase()
        : 'C';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(color: const Color(0xFFF2F4F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFFF2F4F7),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475467),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: KorraColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildStarRow(review.rating, size: 12.sp),
                  ],
                ),
              ),
              Text(
                DateFormat.yMMMd().format(review.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.4,
                color: const Color(0xFF344054),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating, {required double size}) {
    final int fullStars = rating.floor();
    final bool hasHalf = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: const Color(0xFFFFB000), size: size);
        } else if (index == fullStars && hasHalf) {
          return Icon(Icons.star_half, color: const Color(0xFFFFB000), size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.grey.shade300, size: size);
        }
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 48.sp,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No reviews yet',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: KorraColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Customer ratings and comments will appear here once they complete orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearMockData(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      // Get reviews
      final reviewsQuery = await firestore
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('reviews')
          .where('isMock', isEqualTo: true)
          .get();

      for (final doc in reviewsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Get orders
      final ordersQuery = await firestore
          .collection('orders')
          .where('vendorId', isEqualTo: widget.vendorId)
          .where('isMock', isEqualTo: true)
          .get();

      for (final doc in ordersQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      if (context.mounted) {
        showAppSnackbar("Demo reviews and orders cleared successfully!", SnackbarType.success);
      }
      _onRefresh(); // Reload to show empty state
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar("Failed to clear demo data: $e", SnackbarType.error);
      }
    }
  }
}
