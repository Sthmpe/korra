import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../data/models/customer/customer_model.dart';
import '../../data/models/customer/payment_receipt_data.dart';
import '../../logic/bloc/auth/signup_customer/signup_customer_bloc.dart';
import '../../logic/bloc/auth/signup_customer/signup_customer_event.dart';
import '../../presentation/auth/signup_customer/signup_customer_screen.dart';
import '../../presentation/customer/customer_shell.dart';
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
import 'app_routes.dart';
import 'auth_middleware.dart';
import 'common_pages.dart';

class CustomerPages {
  static final List<GetPage> routes = [
    ...commonRoutes,
    
    // 👤 Customer Signup
    GetPage(
      name: Routes.customerSignup,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final showIcon = args?['showLeadingIcon'] ?? false;
        return BlocProvider(
          create: (_) => SignupCustomerBloc()..add(SignupCustomerInit()),
          child: SignupCustomerScreen(showLeadingIcon: showIcon),
        );
      },
    ),

    // --- Customer Shell ---
    GetPage(
      name: Routes.customerShell,
      page: () => CustomerShell(uid: FirebaseAuth.instance.currentUser!.uid),
      middlewares: [AuthMiddleware()],
    ),

    // --- Customer Feature Pages ---
    
    // 🔔 Notifications
    GetPage(
      name: Routes.customerNotifications,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return NotificationScreen(
          uid: map['uid'],
          onJumpToPlans: () => Get.back(result: 'jump_to_plans'),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ➕ Create Plan
    GetPage(
      name: Routes.customerCreatePlan,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return CreatePlanScreen(
          product: map['product'],
          customerUid: map['customerUid'],
          customer: map['customer'],
          walletBalance: map['walletBalance'],
          onJumpToHome: () => Get.back(result: 'jump_to_home'),
          onJumpToPlan: () => Get.back(result: 'jump_to_plans'),
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🧾 Transaction Receipt
    GetPage(
      name: Routes.customerTransactionReceipt,
      page: () => guard((args) {
        final mapArgs = args as Map<String, dynamic>;
        return TransactionReceiptScreen(
          data: mapArgs['data'] as PaymentReceiptData,
          txType: mapArgs['type'] as String,
          convertedAmount: mapArgs['convertedAmount'] as double?,
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🏦 Bank Details
    GetPage(
      name: Routes.customerBankDetails,
      page: () => guard((args) {
        final Customer customer;
        if (args is Customer) {
          customer = args;
        } else {
          customer = (args as Map<String, dynamic>)['customer'];
        }
        return BankDetailsScreen(
          customer: customer,
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: Routes.customerPlanDetailsLoader,
      page: () => guard((args) => PlanDetailsLoaderScreen(
        planId: args['planId'],
      )),
      middlewares: [AuthMiddleware()],
    ),
    
    // 📄 Plan Details
    GetPage(
      name: Routes.customerPlanDetails,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return PlanDetailsScreen(
          plan: map['plan'],
        );
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📄 Statements
    GetPage(
      name: Routes.customerStatements,
      page: () => guard((args) {
        final String uid;
        if (args is String) {
          uid = args;
        } else {
          uid = (args as Map<String, dynamic>)['uid'];
        }
        return StatementsScreen(customerUid: uid);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 💳 Pay Plan Input
    GetPage(
      name: Routes.customerPayPlan,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return PayPlanInputScreen(plan: map['plan']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ Payment Result
    GetPage(
      name: Routes.customerPaymentResult,
      page: () => guard((args) {
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
      page: () => guard((args) => MyQrScreen(customer: args)),
      middlewares: [AuthMiddleware()],
    ),

    // ✏️ Edit Profile
    GetPage(
      name: Routes.customerEditProfile,
      page: () => guard((args) {
        final Customer customer;
        if (args is Customer) {
          customer = args;
        } else {
          customer = (args as Map<String, dynamic>)['customer'];
        }
        return EditProfileScreen(customer: customer);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 💰 Store Credits
    GetPage(
      name: Routes.customerStoreCredits,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return MyStoreCreditsScreen(customerUid: map['uid']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🚀 Limit Upgrade
    GetPage(
      name: Routes.customerLimitUpgrade,
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return LimitUpgradeScreen(
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
      page: () => guard((args) {
        final map = args as Map<String, dynamic>;
        return MyVendorsScreen(customerUid: map['uid']);
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 🔒 Change Password
    GetPage(
      name: Routes.customerChangePassword,
      page: () => guard((args) {
        return const ChangePasswordScreen();
      }),
      middlewares: [AuthMiddleware()],
    ),

    // 📜 Legal & Help
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
  ];
}
