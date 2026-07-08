// lib/presentation/customer/storefront/widgets/storefront_cart_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_service.dart';
import 'storefront_sliver_app_bar.dart';

/// Cart icon button with a live item-count badge, listening to [CartService].
class StorefrontCartButton extends StatelessWidget {
  final String vendorId;
  final VoidCallback onPressed;

  const StorefrontCartButton({
    super.key,
    required this.vendorId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, List<CartItem>>>(
      valueListenable: CartService.instance.cartsNotifier,
      builder: (context, carts, _) {
        final items = carts[vendorId] ?? [];
        final count = items.fold(0, (sum, item) => sum + item.quantity);

        return Padding(
          padding: EdgeInsets.only(right: 6.w),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GlassIconButton(
                icon: Icons.shopping_bag_rounded,
                onPressed: onPressed,
                tooltip: "View Cart",
              ),
              if (count > 0)
                Positioned(
                  top: -4.h,
                  right: -4.w,
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}