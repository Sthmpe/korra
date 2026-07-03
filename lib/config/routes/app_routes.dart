abstract class Routes {
  // --- Core ---
  static const String splashScreen = '/';

  // --- Auth ---
  static const String roleLoginScreen = '/role-login';
  static const String resetLinkSent = '/auth/reset-sent';
  static const String customerSignup = '/auth/signup/customer';
  static const String vendorSignup = '/auth/signup/vendor';
  static const String forgotPassword = '/auth/forgot-password';

  // --- Vendor ---
  // Matches "VendorShell" widget
  static const String vendorShell = '/vendor/shell';

  static const String vendorNotifications = '/vendor/notifications';
  static const String vendorPayout = '/vendor/payout';
  static const String vendorReservations = '/vendor/reservations';
  static const String vendorPayoutSuccess = '/vendor/payout/success';
  static const String vendorAddProduct = '/vendor/products/add';
  static const String vendorProductDetails = '/vendor/products/details';
  static const String vendorEditProduct = '/vendor/products/edit';
  static const String vendorEditProfile = '/vendor/profile/edit';
  static const String vendorQr = '/vendor/profile/qr';
  static const String vendorSettlement = '/vendor/profile/settlement';
  static const String vendorChangePassword = '/vendor/settings/password';
  static const String vendorLegal = '/vendor/settings/legal';
  static const String vendorReceipt = '/vendor/receipt';
  static const String vendorStoreBalances = '/vendor/profile/store-balances';
  static const String vendorPayoutSettings = '/vendor/payout/settings';

  // --- Customer ---
  static const String customerShell = '/customer/shell';

  static const String customerNotifications = '/customer/notifications';
  static const String customerCreatePlan = '/customer/plan/create';
  static const String customerPlanDetailsLoader = '/customer/plan/loader';
  static const String customerPlanDetails = '/customer/plan/details';
  static const String customerBankDetails = '/customer/bank-details';
  static const String customerTransactionReceipt = '/customer/transaction/receipt';
  static const String customerStatements = '/customer/statements';
  static const String customerPayPlan = '/customer/plan/pay';
  static const String customerPaymentResult = '/customer/payment/result';
  // --- Profile / Settings ---
  static const String customerQr = '/customer/profile/qr';
  static const String customerEditProfile = '/customer/profile/edit';
  static const String customerStoreCredits = '/customer/profile/credits';
  static const String customerLiveness = '/customer/verification/liveness';
  static const String customerLimitUpgrade = '/customer/profile/limit-upgrade';
  static const String customerMyVendors = '/customer/profile/vendors';
  static const String customerChangePassword = '/customer/settings/password';
  static const String customerLegal = '/customer/settings/legal';
  static const String customerHelp = '/customer/settings/help';
  static const String customerStorefront = '/store/:slug';
}
