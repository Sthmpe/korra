// lib/presentation/customer/storefront/widgets/storefront_cart_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../config/utils/korra_exception.dart';
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../shared/widgets/show_app_snackbar.dart';
import 'cart_service.dart';
import 'storefront_cart_balances.dart';
import 'storefront_cart_item_tile.dart';

/// Premium multi-item cart sheet: floating item tiles, live fee breakdown
/// (merchant absorb vs customer pays), store-balance-first payment split,
/// "Paying Now" total and a confirm-first checkout flow.
///
/// Payment rule: the customer's store balance at this merchant is ALWAYS
/// applied first (no opt-out); the wallet covers the remainder. If both
/// can't cover the total, checkout is replaced by a black "Fund Wallet" CTA
/// that opens Bank Details — backing out returns straight to this cart.
class StorefrontCartSheet extends StatefulWidget {
  final String vendorId;
  final String storeName;
  final String customerUid;
  final ScrollController scrollController;

  const StorefrontCartSheet({
    super.key,
    required this.vendorId,
    required this.storeName,
    required this.customerUid,
    required this.scrollController,
  });

  @override
  State<StorefrontCartSheet> createState() => _StorefrontCartSheetState();
}

class _StorefrontCartSheetState extends State<StorefrontCartSheet> {
  bool _isCheckingOut = false;

  // Stateless wrapper over the Firebase/Supabase singletons — safe to build
  // here (the sheet lives in the root overlay, outside the shell's provider).
  final CustomerRepository _repo = CustomerRepository();

  // Cached in initState — creating streams in build() resubscribes Firestore
  // on every rebuild.
  late final Stream<double> _storeBalanceStream;
  late final Stream<Customer?> _customerStream;

  @override
  void initState() {
    super.initState();
    final firestore = FirebaseFirestore.instance;

    _storeBalanceStream = firestore
        .collection('customers')
        .doc(widget.customerUid)
        .collection('my_vendors')
        .doc(widget.vendorId)
        .snapshots()
        .map((doc) => ((doc.data() ?? const {})['storeCredit'] ?? 0).toDouble());

    _customerStream = firestore
        .collection('customers')
        .doc(widget.customerUid)
        .snapshots()
        .map((doc) =>
            doc.exists && doc.data() != null ? Customer.fromMap(doc.data()!) : null);
  }

  void _goToFundWallet(Customer? customer) {
    if (customer == null) {
      showAppSnackbar("Couldn't load your profile. Please try again.", SnackbarType.error);
      return;
    }
    // Pushes Bank Details on top of this open sheet — the system back
    // returns the customer directly to this checkout.
    Get.toNamed(Routes.customerBankDetails, arguments: {'customer': customer});
  }

  void _updateQuantity(String productId, int delta) {
    CartService.instance.updateQuantity(widget.vendorId, productId, delta);
  }

  void _removeItem(String productId) {
    CartService.instance.removeItem(widget.vendorId, productId);
  }

  Future<void> _confirmCheckout(
    double subtotal,
    double fee,
    double storeApplied,
    double walletDue,
  ) async {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    final splitNote = storeApplied > 0
        ? " ${currencyFormat.format(storeApplied)} comes from your store balance and ${currencyFormat.format(walletDue)} from your wallet."
        : "";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Confirm Purchase",
          style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
        ),
        content: Text(
          "You are paying ${currencyFormat.format(subtotal + fee)} now for this outright purchase from ${widget.storeName}.$splitNote Proceed?",
          style: GoogleFonts.inter(fontSize: 13.sp, color: KorraColors.textBody, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: KorraColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA54600),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              "Pay Now",
              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) _checkoutCart();
  }

  void _checkoutCart() async {
    setState(() => _isCheckingOut = true);

    // Snapshot the cart BEFORE the network call — the server needs the exact
    // items, and we only clear the local cart once the order is confirmed.
    final items = CartService.instance
        .getItems(widget.vendorId)
        .map((i) => {'productId': i.productId, 'quantity': i.quantity})
        .toList();

    if (items.isEmpty) {
      if (mounted) setState(() => _isCheckingOut = false);
      return;
    }

    try {
      final receipt = await _repo.checkoutOutright(
        vendorId: widget.vendorId,
        items: items,
      );

      // Order succeeded — safe to clear the local cart now.
      CartService.instance.clearCart(widget.vendorId);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        showAppSnackbar(
          "Purchase confirmed! ${receipt.vendorName} will prepare your order.",
          SnackbarType.success,
        );
      }
    } on KorraException catch (e) {
      if (mounted) showAppSnackbar(e.message, SnackbarType.error);
    } catch (e) {
      if (mounted) {
        showAppSnackbar("Checkout failed. Please try again.", SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).snapshots(),
      builder: (context, vendorSnapshot) {
        bool absorbOutrightFee = false;
        if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
          final data = vendorSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final storeMap = data['store'] as Map<String, dynamic>? ?? {};
          absorbOutrightFee = storeMap['absorbOutrightFee'] ?? false;
        }

        return ValueListenableBuilder<Map<String, List<CartItem>>>(
          valueListenable: CartService.instance.cartsNotifier,
          builder: (context, carts, _) {
            final items = carts[widget.vendorId] ?? [];

            if (items.isEmpty) return _buildEmptyState(context);

            // Calculate Subtotal
            double subtotal = 0.0;
            for (final item in items) {
              subtotal += item.price * item.quantity;
            }

            // Calculate Processing Fee
            double fee = 0.0;
            if (!absorbOutrightFee) {
              fee = subtotal * 0.035;
              if (fee > 7500.0) {
                fee = 7500.0;
              }
            }

            final totalUnits = items.fold(0, (sum, item) => sum + item.quantity);

            return StreamBuilder<double>(
              stream: _storeBalanceStream,
              initialData: 0.0,
              builder: (context, balanceSnapshot) {
                return StreamBuilder<Customer?>(
                  stream: _customerStream,
                  builder: (context, customerSnapshot) {
                    final customer = customerSnapshot.data;
                    final storeBalance = balanceSnapshot.data ?? 0.0;
                    final walletBalance = customer?.availableBalance ?? 0.0;

                    // Store balance is always consumed first; wallet covers the rest.
                    final total = subtotal + fee;
                    final storeApplied = storeBalance >= total ? total : storeBalance;
                    final walletDue = total - storeApplied;
                    final shortfall = walletDue - walletBalance;
                    final insufficient = shortfall > 0;

                    return _buildCartBody(
                      items: items,
                      subtotal: subtotal,
                      fee: fee,
                      absorbOutrightFee: absorbOutrightFee,
                      totalUnits: totalUnits,
                      storeBalance: storeBalance,
                      walletBalance: walletBalance,
                      storeApplied: storeApplied,
                      walletDue: walletDue,
                      shortfall: insufficient ? shortfall : 0.0,
                      customer: customer,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartBody({
    required List<CartItem> items,
    required double subtotal,
    required double fee,
    required bool absorbOutrightFee,
    required int totalUnits,
    required double storeBalance,
    required double walletBalance,
    required double storeApplied,
    required double walletDue,
    required double shortfall,
    required Customer? customer,
  }) {
    final money = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final insufficient = shortfall > 0;

    return Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 10.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 12.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF4ED),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Iconsax.shopping_bag, color: KorraColors.brand, size: 18.sp),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Cart",
                              style: GoogleFonts.inter(
                                  fontSize: 17.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
                            ),
                            Text(
                              widget.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: KorraColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "$totalUnits item${totalUnits == 1 ? '' : 's'}",
                          style: GoogleFonts.inter(
                              fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: KorraColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF2F4F7), height: 1),

                // Cart Items
                Expanded(
                  child: ListView.builder(
                    controller: widget.scrollController,
                    itemCount: items.length,
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return StorefrontCartItemTile(
                        item: item,
                        onQuantityChanged: (delta) => _updateQuantity(item.productId, delta),
                        onRemove: () => _removeItem(item.productId),
                      );
                    },
                  ),
                ),

                // Fees & Checkout Footer
                Container(
                  padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        // Store + wallet balances (store balance is spent first)
                        StorefrontCartBalancesCard(
                          storeBalance: storeBalance,
                          walletBalance: walletBalance,
                          shortfall: shortfall,
                        ),
                        Divider(color: const Color(0xFFF2F4F7), height: 22.h),

                        _summaryRow("Subtotal", money.format(subtotal)),
                        SizedBox(height: 8.h),
                        _summaryRow(
                          absorbOutrightFee ? "Processing Fee" : "Processing Fee (3.5%, max ₦7,500)",
                          absorbOutrightFee ? "₦0 · absorbed by merchant" : money.format(fee),
                          valueColor: absorbOutrightFee ? KorraColors.settleGreen : null,
                        ),
                        if (storeApplied > 0) ...[
                          SizedBox(height: 8.h),
                          _summaryRow(
                            "Store Balance applied",
                            "− ${money.format(storeApplied)}",
                            valueColor: KorraColors.settleGreen,
                          ),
                        ],
                        Divider(color: const Color(0xFFF2F4F7), height: 24.h),

                        // Paying Now (wallet share only — store balance already deducted)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Paying Now",
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                                ),
                                Text(
                                  storeApplied > 0 ? "from wallet, after store balance" : "from wallet",
                                  style: GoogleFonts.inter(
                                      fontSize: 10.sp, fontWeight: FontWeight.w500, color: KorraColors.textHint),
                                ),
                              ],
                            ),
                            Text(
                              money.format(walletDue),
                              style: GoogleFonts.inter(
                                  fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFFA54600)),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // CTA: black Fund Wallet when short, gradient checkout otherwise
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: insufficient
                              ? ElevatedButton.icon(
                                  onPressed: () => _goToFundWallet(customer),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.r)),
                                  ),
                                  icon: Icon(Iconsax.wallet_add_1, size: 18.sp),
                                  label: Text(
                                    "Fund Wallet",
                                    style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800),
                                  ),
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [KorraColors.brand, Color(0xFFE05600)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isCheckingOut
                                        ? null
                                        : () => _confirmCheckout(subtotal, fee, storeApplied, walletDue),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                      elevation: 0,
                                    ),
                                    child: _isCheckingOut
                                        ? SizedBox(
                                            width: 24.w,
                                            height: 24.w,
                                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Text(
                                            "Proceed to Outright Purchase",
                                            style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800),
                                          ),
                                  ),
                                ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.shield_tick, size: 12.sp, color: KorraColors.textMuted),
                            SizedBox(width: 4.w),
                            Text(
                              "Payments secured by Korra",
                              style: GoogleFonts.inter(
                                  fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: KorraColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: KorraColors.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? KorraColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4ED),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.shopping_bag, size: 38.sp, color: KorraColors.brand),
            ),
            SizedBox(height: 18.h),
            Text(
              "Your Cart is Empty",
              style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
            ),
            SizedBox(height: 6.h),
            Text(
              "Browse ${widget.storeName} and add items you love.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: KorraColors.textMuted, height: 1.4),
            ),
            SizedBox(height: 20.h),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFA54600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              ),
              child: Text(
                "Continue Shopping",
                style: GoogleFonts.inter(
                    fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFFA54600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}