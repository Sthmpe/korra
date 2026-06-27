import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../data/repository/vendors/vendor_repository.dart';
import '../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../logic/bloc/vendor/image/image_bloc.dart';
import '../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../logic/bloc/vendor/payout/payout_event.dart';
import '../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../presentation/auth/signup_vendor/signup_vendor_screen.dart';
import '../../presentation/vendor/home/widgets/notification_screen.dart';
import '../../presentation/vendor/payout/payout_screen_ui.dart';
import '../../presentation/vendor/payout/widgets/payout_success_screen.dart';
import '../../presentation/vendor/product/widgets/Add_product_page.dart';
import '../../presentation/vendor/product/widgets/product_details_screen.dart';
import '../../presentation/vendor/product/widgets/product_edit_screen.dart';
import '../../presentation/vendor/profile/change_password_screen.dart';
import '../../presentation/vendor/profile/payout_settings_screen.dart';
import '../../presentation/vendor/profile/store_balance_screen.dart';
import '../../presentation/vendor/profile/vendor_receipt_screen.dart';
import '../../presentation/vendor/profile/vendor_settlement_screen.dart';
import '../../presentation/vendor/profile/widgets/legal_screen.dart';
import '../../presentation/vendor/reservation/reservations_page.dart';
import '../../presentation/vendor/vendor_shell.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';
import 'common_pages.dart';

class VendorPages {
  static final List<GetPage> routes = [
    ...commonRoutes,

    // 🏪 Vendor Signup
    GetPage(
      name: Routes.vendorSignup,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final showIcon = args?['showLeadingIcon'] ?? false;
        return BlocProvider(
          create: (_) => SignupVendorBloc()..add(SignupVendorInit()),
          child: SignupVendorScreen(showLeadingIcon: showIcon),
        );
      },
    ),

    // --- Vendor Shell ---
    GetPage(
      name: Routes.vendorShell,
      page: () => VendorShell(uid: FirebaseAuth.instance.currentUser!.uid),
      middlewares: [AuthMiddleware()],
    ),

    // --- Vendor Feature Pages ---
    
    // 🔔 Vendor Notifications
    GetPage(
      name: Routes.vendorNotifications,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return VendorNotificationScreen(
          vendorUid: map['uid'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 💰 Vendor Payout
    GetPage(
      name: Routes.vendorPayout,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return BlocProvider(
          create: (context) => PayoutBloc(
            vendorUid: map['uid'],
            repo: context.read<VendorRepository>(),
          )..add(PayoutStarted(map['withdrawableAmount'])),
          child: const PayoutScreen(),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📅 Vendor Reservations
    GetPage(
      name: Routes.vendorReservations,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return ReservationsPage(
          vendorId: map['uid'],
          initialFilter: map['filter'],
          showLeadingIcon: map['showLeadingIcon'] ?? true,
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ Payout Success
    GetPage(
      name: Routes.vendorPayoutSuccess,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return PayoutSuccessScreen(
          amount: map['amount'],
          reference: map['reference'],
          bankName: map['bankName'],
          accountNumber: map['accountNumber'],
          accountName: map['accountName'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ➕ Vendor Add Product
    GetPage(
      name: Routes.vendorAddProduct,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: map['listBloc'] as VendorProductsBloc,
            ),
            BlocProvider(
              create: (_) => ImageBloc(),
            ),
          ],
          child: AddProductPage(
            vendorUid: map['uid'],
          ),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📦 Product Details
    GetPage(
      name: Routes.vendorProductDetails,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return BlocProvider.value(
          value: map['listBloc'] as VendorProductsBloc,
          child: ProductDetailsScreen(
            product: map['product'],
            vendorUid: map['uid'],
          ),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✏️ Edit Product
    GetPage(
      name: Routes.vendorEditProduct,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: map['listBloc'] as VendorProductsBloc,
            ),
            BlocProvider(
              create: (_) => ImageBloc(),
            ),
          ],
          child: ProductEditScreen(
            product: map['product'],
            vendorUid: map['uid'],
          ),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🏦 Settlement Settings
    GetPage(
      name: Routes.vendorSettlement,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return VendorSettlementScreen(
          vendorUid: map['uid'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🏦 Payout Settings (Vault)
    GetPage(
      name: Routes.vendorPayoutSettings,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return PayoutSettingsScreen(
          vendorUid: map['uid'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🔒 Change Password (Vendor)
    GetPage(
      name: Routes.vendorChangePassword,
      page: () => guard((args) {
        return const VendorChangePasswordScreen();
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📜 Legal Menu (Vendor)
    GetPage(
      name: Routes.vendorLegal,
      page: () => const vLegalMenuScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // 🧾 Vendor Transaction Receipt
    GetPage(
      name: Routes.vendorReceipt,
      page: () => guard((args) => VendorReceiptScreen(
        transaction: args['transaction'],
      )),
      middlewares: [AuthMiddleware()],
    ),

    // 🏦 Vendor Store Balances
    GetPage(
      name: Routes.vendorStoreBalances,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return StoreBalanceScreen(
          vendorUid: map['uid'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
