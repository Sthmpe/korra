// lib/presentation/customer/storefront/store_reviews_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../data/models/vendor/vendor_review.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/widgets/show_app_snackbar.dart';
import 'widgets/ai_review_summary_box.dart';
import 'widgets/storefront_review_composer.dart';
import 'widgets/storefront_reviews_section.dart';

/// Full ratings & reviews screen for one store: big average, star
/// distribution bars and the paginated review list, streamed from
/// `vendors/{id}/reviews` (both `comment` and legacy `review` fields).
class StoreReviewsScreen extends StatefulWidget {
  final String vendorId;
  final String storeName;

  const StoreReviewsScreen({
    super.key,
    required this.vendorId,
    required this.storeName,
  });

  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  Stream<QuerySnapshot>? _reviewsStream;
  int _visible = _pageSize;

  /// Composer eligibility: only customers who have purchased from this store
  /// (a plan or an outright order) may rate it.
  bool _canReview = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _reviewsStream = FirebaseFirestore.instance
        .collection('vendors')
        .doc(widget.vendorId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
    _checkPurchaseEligibility();
    _scrollController.addListener(_maybeLoadMore);
  }

  Future<void> _checkPurchaseEligibility() async {
    final uid = _uid;
    if (uid == null) return;
    final firestore = FirebaseFirestore.instance;
    try {
      for (final collection in ['orders', 'plans']) {
        final query = await firestore
            .collection(collection)
            .where('customerId', isEqualTo: uid)
            .where('vendorId', isEqualTo: widget.vendorId)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          if (mounted) setState(() => _canReview = true);
          return;
        }
      }
    } catch (e) {
      debugPrint('Review eligibility check failed: $e'); // composer stays hidden
    }
  }

  VendorReview? _myReview(List<VendorReview> reviews) {
    final uid = _uid;
    if (uid == null) return null;
    for (final r in reviews) {
      if (r.customerId == uid) return r;
    }
    return null;
  }

  Future<void> _submitReview(double rating, String comment) async {
    final uid = _uid;
    if (uid == null) return;
    final user = FirebaseAuth.instance.currentUser;
    try {
      // Doc id = customer uid → one review per customer, updates replace it.
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('reviews')
          .doc(uid)
          .set({
        'customerId': uid,
        'customerName': user?.displayName ?? 'Korra Customer',
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'isMock': false,
      }, SetOptions(merge: true));
      if (mounted) {
        showAppSnackbar("Thanks! Your review has been posted.", SnackbarType.success);
      }
    } catch (e) {
      debugPrint('Review submit failed: $e');
      if (mounted) {
        showAppSnackbar(
            "Could not post your review. Please try again.", SnackbarType.error);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      setState(() => _visible += _pageSize);
    }
  }

  /// Tolerant mapping: supports the model's `comment` and the legacy `review`
  /// field, plus int OR double ratings.
  VendorReview _fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VendorReview(
      id: doc.id,
      customerId: (data['customerId'] ?? '').toString(),
      customerName: (data['customerName'] ?? 'Anonymous Buyer').toString(),
      rating: ((data['rating'] ?? 0) as num).toDouble(),
      comment: (data['comment'] ?? data['review'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMock: data['isMock'] == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KorraColors.surface,
      appBar: const KorraHeader(title: "Ratings & Reviews", showLeadingIcon: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: KorraColors.brand));
          }
          final reviews =
              (snapshot.data?.docs ?? const []).map(_fromDoc).toList();
          return _buildBody(reviews);
        },
      ),
    );
  }

  Widget _buildBody(List<VendorReview> reviews) {
    final myReview = _myReview(reviews);

    // Header widgets rendered above the review list: the composer (only for
    // customers who purchased here) and the ratings summary.
    final headers = <Widget>[
      AiReviewSummaryBox(key: ValueKey('ai_summary_${widget.vendorId}'), vendorId: widget.vendorId),
      if (_canReview)
        StorefrontReviewComposer(
          // Re-key on the review content so the card flips back to the
          // "Your review" summary right after a submit/update.
          key: ValueKey('composer_${myReview?.rating}_${myReview?.comment}'),
          existing: myReview,
          onSubmit: _submitReview,
        ),
      if (reviews.isNotEmpty) _summarySection(reviews),
    ];

    if (reviews.isEmpty && !_canReview) return _emptyState();

    final shown = _visible < reviews.length ? _visible : reviews.length;
    final hasMore = shown < reviews.length;

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      itemCount: headers.length + shown + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < headers.length) return headers[index];
        final reviewIndex = index - headers.length;
        if (reviewIndex >= shown) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: SizedBox(
                height: 22.w,
                width: 22.w,
                child: const CircularProgressIndicator(
                    strokeWidth: 2.5, color: KorraColors.brand),
              ),
            ),
          );
        }
        return StoreReviewCard(review: reviews[reviewIndex]);
      },
    );
  }

  Widget _summarySection(List<VendorReview> reviews) {
    final average =
        reviews.fold<double>(0, (acc, r) => acc + r.rating) / reviews.length;
    final counts = List<int>.filled(5, 0); // index 0 → 1 star … 4 → 5 stars
    for (final r in reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star - 1]++;
    }
    return _summaryCard(average, reviews.length, counts);
  }

  Widget _summaryCard(double average, int total, List<int> counts) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Big average + stars
          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w900,
                  color: KorraColors.textDark,
                  height: 1,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  final IconData icon;
                  if (average >= starValue) {
                    icon = Icons.star_rounded;
                  } else if (average > i) {
                    icon = Icons.star_half_rounded;
                  } else {
                    icon = Icons.star_outline_rounded;
                  }
                  return Icon(icon, color: Colors.amber, size: 15.sp);
                }),
              ),
              SizedBox(height: 4.h),
              Text(
                "$total review${total == 1 ? '' : 's'}",
                style: GoogleFonts.inter(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: KorraColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(width: 18.w),

          // 5 → 1 star distribution bars
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[star - 1];
                final fraction = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.5.h),
                  child: Row(
                    children: [
                      Text(
                        "$star",
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: KorraColors.textMuted,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(Icons.star_rounded, size: 10.sp, color: Colors.amber),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6.h,
                            backgroundColor: const Color(0xFFF2F4F7),
                            color: KorraColors.brand,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 20.w,
                        child: Text(
                          "$count",
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: KorraColors.textMuted,
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.star, size: 42.sp, color: KorraColors.textHint),
            SizedBox(height: 14.h),
            Text(
              "No reviews yet",
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: KorraColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Complete a purchase from ${widget.storeName} to be the first to leave a review.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: KorraColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
