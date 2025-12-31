import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/customer/customer_model.dart';
import '../../data/models/customer/payment_receipt_data.dart';
import '../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../logic/bloc/auth/signup_customer/signup_customer_event.dart';
import '../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../logic/bloc/vendor/image/image_bloc.dart';
import '../../logic/bloc/vendor/payout/payout_bloc.dart';
import '../../logic/bloc/vendor/payout/payout_event.dart';
import '../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../presentation/auth/forgot_password/forgot_password_screen.dart';
import '../../presentation/auth/forgot_password/reset_link_sent_screen.dart';
import '../../presentation/auth/signup_customer/signup_customer_screen.dart';
import '../../presentation/auth/signup_vendor/signup_vendor_screen.dart';
import '../../presentation/customer/home/notification_screen.dart';
import '../../presentation/customer/plans/create_plan_screen.dart';
import '../../presentation/customer/plans/widgets/pay_plan_input_screen.dart';
import '../../presentation/customer/plans/widgets/payment_result_screen.dart';
import '../../presentation/customer/plans/widgets/plan_details_loader_screen.dart';
import '../../presentation/customer/plans/widgets/plan_details_screen.dart';
import '../../presentation/customer/plans/widgets/transaction_receipt_screen.dart';
import '../../presentation/customer/profile/bank_details_screen.dart';
import '../../presentation/customer/profile/change_password_screen.dart';
import '../../presentation/customer/profile/edit_profile_screen.dart';
import '../../presentation/customer/profile/help_center_screen.dart';
import '../../presentation/customer/profile/legal_screen.dart';
import '../../presentation/customer/profile/limit_upgrade_screen.dart';
import '../../presentation/customer/profile/my_qr_screen.dart';
import '../../presentation/customer/profile/my_store_credit_screen.dart';
import '../../presentation/customer/profile/my_vendors_screen.dart';
import '../../presentation/customer/profile/statements_screen.dart';
import '../../presentation/vendor/home/widgets/notification_screen.dart';
import '../../presentation/vendor/payout/payout_screen_ui.dart';
import '../../presentation/vendor/payout/widgets/payout_success_screen.dart';
import '../../presentation/vendor/product/widgets/Add_product_page.dart';
import '../../presentation/vendor/product/widgets/product_details_screen.dart';
import '../../presentation/vendor/product/widgets/product_edit_screen.dart';
import '../../presentation/vendor/profile/change_password_screen.dart';
import '../../presentation/vendor/profile/vendor_receipt_screen.dart';
import '../../presentation/vendor/profile/vendor_settlement_screen.dart';
import '../../presentation/vendor/reservation/reservations_page.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

// --- Screen Imports ---
import '../../presentation/auth/role_login/role_login_screen.dart';
import '../../presentation/vendor/vendor_shell.dart';
import '../../presentation/customer/customer_shell.dart';

// ✅ HELPER: Checks if arguments exist. If not, redirects to Login.
Widget _guard(Widget Function(dynamic args) builder) {
  final args = Get.arguments;
  if (args == null) {
    // 🛑 STOP: No arguments found (Refresh or Manual URL)
    print("⚠️ Missing arguments. Redirecting to Login.");

    // Schedule the redirect for the next frame to avoid build errors
    Future.microtask(() => Get.offAllNamed(Routes.roleLoginScreen));

    // Return a temporary loader while redirecting
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // ✅ GO: Arguments exist, build the screen
  return builder(args);
}

class AppPages {
  static final routes = [
    // --- Public ---
    GetPage(name: Routes.roleLoginScreen, page: () => const RoleLoginScreen()),

    GetPage(
      name: Routes.resetLinkSent,
      page: () => _guard((args) => ResetLinkSentScreen(
        email: args['email'],
      )),
      // No AuthMiddleware needed here (user is usually logged out)
    ),

    // 👤 Customer Signup
    GetPage(
      name: Routes.customerSignup,
      page: () {
        // Check for arguments (optional)
        final args = Get.arguments as Map<String, dynamic>?;
        final showIcon = args?['showLeadingIcon'] ?? false; 
        
        return BlocProvider(
          create: (_) => SignupCustomerBloc()..add(SignupCustomerInit()),
          child: SignupCustomerScreen(showLeadingIcon: showIcon),
        );
      },
    ),

    // 🏪 Vendor Signup
    GetPage(
      name: Routes.vendorSignup,
      page: () {
        // Check for optional arguments
        final args = Get.arguments as Map<String, dynamic>?;
        final showIcon = args?['showLeadingIcon'] ?? false; // Default to false

        return BlocProvider(
          create: (_) => SignupVendorBloc()..add(SignupVendorInit()),
          child: SignupVendorScreen(showLeadingIcon: showIcon),
        );
      },
    ),

    // ❓ Forgot Password
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),

    // --- Vendor ---
    GetPage(
      name: Routes.vendorShell,
      // 🔹 WE USE THE SAME ARGUMENT NAME (uid)
      page: () => VendorShell(uid: FirebaseAuth.instance.currentUser!.uid),
      middlewares: [AuthMiddleware()],
    ),

    // --- Customer ---
    GetPage(
      name: Routes.customerShell,
      page: () => CustomerShell(uid: FirebaseAuth.instance.currentUser!.uid),
      middlewares: [AuthMiddleware()],
    ),

    ///-----------VENDOR PAGE--------------///
    
    // 🔔 Vendor Notifications
    GetPage(
      name: Routes.vendorNotifications,
      // 🛡️ GUARD APPLIED: Ensures 'uid' exists before building
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return VendorNotificationScreen(
          vendorUid: map['uid'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 💰 Vendor Payout (With Bloc Provider Injection)
    GetPage(
      name: Routes.vendorPayout,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        
        // 💉 Inject Bloc here, so the screen stays clean
        return BlocProvider(
          create: (_) => PayoutBloc(
            vendorUid: map['uid'],
            repo: map['repo'],
          )..add(PayoutStarted(map['withdrawableAmount'])), // Fire event immediately
          child: const PayoutScreen(),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📅 Vendor Reservations (With Filters)
    GetPage(
      name: Routes.vendorReservations,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return ReservationsPage(
          vendorId: map['uid'],
          vendors: map['repo'],
          initialFilter: map['filter'], // Passing the enum
          showLeadingIcon: map['showLeadingIcon'] ?? true,
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ Payout Success
    GetPage(
      name: Routes.vendorPayoutSuccess,
      page: () => _guard((args) {
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

    // ➕ Vendor Add Product (MultiBloc Preserved)
    GetPage(
      name: Routes.vendorAddProduct,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        
        return MultiBlocProvider(
          providers: [
            // 1. Pass the EXISTING Bloc (received via arguments)
            BlocProvider.value(
              value: map['listBloc'] as VendorProductsBloc,
            ),
            
            // 2. Create the NEW Image Bloc
            BlocProvider(
              create: (_) => ImageBloc(),
            ),
          ],
          child: AddProductPage(
            vendors: map['repo'],
            vendorUid: map['uid'],
          ),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📦 Product Details
    GetPage(
      name: Routes.vendorProductDetails,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        
        // 💉 Inject the EXISTING Bloc
        return BlocProvider.value(
          value: map['listBloc'] as VendorProductsBloc,
          child: ProductDetailsScreen(product: map['product']),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✏️ Edit Product (MultiBloc)
    GetPage(
      name: Routes.vendorEditProduct,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        
        return MultiBlocProvider(
          providers: [
            // 1. Pass the EXISTING Bloc
            BlocProvider.value(
              value: map['listBloc'] as VendorProductsBloc,
            ),
            // 2. Create NEW Image Bloc
            BlocProvider(
              create: (_) => ImageBloc(),
            ),
          ],
          child: ProductEditScreen(product: map['product']),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✏️ Edit Vendor Profile
    // GetPage(
    //   name: Routes.vendorEditProfile,
    //   page: () => _guard((args) => EditVendorProfileScreen(
    //     vendor: args['vendor'],
    //   )),
    //   middlewares: [AuthMiddleware()],
    // ),

    // 📱 Vendor QR
    // GetPage(
    //   name: Routes.vendorQr,
    //   page: () => _guard((args) => VendorQrScreen(
    //     vendor: args['vendor'],
    //   )),
    //   middlewares: [AuthMiddleware()],
    // ),

    // 🏦 Settlement Settings
    GetPage(
      name: Routes.vendorSettlement,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return VendorSettlementScreen(
          repo: map['repo'],
          vendorUid: map['uid'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🔒 Change Password (Vendor Context)
    GetPage(
      name: Routes.vendorChangePassword,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return VendorChangePasswordScreen(
          repo: map['repo'], // Injecting Vendor Repo here
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📜 Legal Menu (Shared)
    GetPage(
      name: Routes.vendorLegal,
      page: () => const LegalMenuScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // 🧾 Vendor Transaction Receipt
    GetPage(
      name: Routes.vendorReceipt,
      page: () => _guard((args) => VendorReceiptScreen(
        transaction: args['transaction'],
      )),
      middlewares: [AuthMiddleware()],
    ),


    ///----------CUSTOMERS PAGE------------///

    // 🔔 Notifications
    GetPage(
      name: Routes.customerNotifications,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return NotificationScreen(
          repo: map['repo'],
          uid: map['uid'],
          onJumpToPlans: () => Get.back(result: 'jump_to_plans'),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ➕ Create Plan
    GetPage(
      name: Routes.customerCreatePlan,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return CreatePlanScreen(
          product: map['product'],
          customerRepo: map['customerRepo'],
          customerUid: map['customerUid'],
          customer: map['customer'],
          walletBalance: map['walletBalance'],
          onJumpToHome: () => Get.back(result: 'jump_to_home'),
          onJumpToPlan: () => Get.back(result: 'jump_to_plans'),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🧾 Transaction Receipt (Object Pass)
    GetPage(
      name: Routes.customerTransactionReceipt,
      // 🛡️ GUARD APPLIED
      page: () => _guard(
        (args) => TransactionReceiptScreen(data: args as PaymentReceiptData),
      ),
      middlewares: [AuthMiddleware()],
    ),

    // 🏦 Bank Details (Object Pass)
    GetPage(
      name: Routes.customerBankDetails,
      // 🛡️ GUARD APPLIED
      page: () =>
          _guard((args) => BankDetailsScreen(customer: args as Customer)),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: Routes.customerPlanDetailsLoader,
      page: () => _guard((args) => PlanDetailsLoaderScreen(
        planId: args['planId'],
      )),
      middlewares: [AuthMiddleware()],
    ),
    
    // 📄 Plan Details (Map Pass)
    GetPage(
      name: Routes.customerPlanDetails,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return PlanDetailsScreen(
          plan: map['plan'],
          customerRepo: map['customerRepo'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📄 Statements
    GetPage(
      name: Routes.customerStatements,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return StatementsScreen(repo: map['repo'], customerUid: map['uid']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 💳 Pay Plan Input
    GetPage(
      name: Routes.customerPayPlan,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return PayPlanInputScreen(plan: map['plan'], repo: map['repo']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ Payment Result
    GetPage(
      name: Routes.customerPaymentResult,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return PaymentResultScreen(
          isSuccess: map['isSuccess'],
          amount: map['amount'],
          planName: map['planName'],
          fullReceiptData: map['fullReceiptData'],
          isPlanCompleted: map['isPlanCompleted'] ?? false,
          errorMessage: map['errorMessage'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📱 My QR
    GetPage(
      name: Routes.customerQr,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) => MyQrScreen(customer: args)),
      middlewares: [AuthMiddleware()],
    ),

    // ✏️ Edit Profile
    GetPage(
      name: Routes.customerEditProfile,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return EditProfileScreen(customer: map['customer'], repo: map['repo']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 💰 Store Credits
    GetPage(
      name: Routes.customerStoreCredits,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return MyStoreCreditsScreen(customerUid: map['uid']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🚀 Limit Upgrade
    GetPage(
      name: Routes.customerLimitUpgrade,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return LimitUpgradeScreen(
          repo: map['repo'],
          customer: map['customer'],
          currentMaxSlots: map['currentMaxSlots'],
          completedPlansCount: map['completedPlansCount'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🏪 My Vendors
    GetPage(
      name: Routes.customerMyVendors,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return MyVendorsScreen(customerUid: map['uid']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🔒 Change Password
    GetPage(
      name: Routes.customerChangePassword,
      // 🛡️ GUARD APPLIED
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return ChangePasswordScreen(repo: map['repo']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📜 Legal & Help (Simple Routes - No Args needed usually)
    GetPage(
      name: Routes.customerLegal,
      page: () => const LegalMenuScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.customerHelp,
      page: () => const HelpCenterScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // 📸 Liveness (Commented out as requested, but guard applied)
    /*
    GetPage(
      name: Routes.customerLiveness,
      page: () => _guard((args) {
        final map = args as Map<String, dynamic>;
        return LivenessScreen(
          onVerificationSuccess: map['onSuccess'], 
        );
      }),
      middlewares: [AuthMiddleware()],
    ),
    */
  ];
}
