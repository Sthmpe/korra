class KorraStrings {
  // -- App --------------------------------------------------------------
  static const appName    = 'Korra';
  static const appTagline = 'Smart People Own Things Differently.';

  // -- Navigation - customer --------------------------------------------
  static const navHome    = 'Home';
  static const navPlans   = 'Plans';
  static const navProfile = 'Profile';

  // -- Navigation - vendor ----------------------------------------------
  static const navProducts     = 'Products';
  static const navReservations = 'Reservations';

  // -- Common actions ---------------------------------------------------
  static const actionCancel          = 'Cancel';
  static const actionDismiss         = 'Dismiss';
  static const actionTryAgain        = 'Try Again';
  static const actionViewAll         = 'View All';
  static const actionEdit            = 'Edit';
  static const actionShare           = 'Share link';
  static const actionContinueGoogle  = 'Continue with Google';
  static const actionLogOut          = 'Log out';
  static const actionKeepAccount     = 'Keep Account';
  static const actionDeletePermanent = 'Delete Permanently';
  static const actionVerifyPickup    = 'Verify Pickup PIN';
  static const actionPayNow          = 'Pay Now';
  static const actionView            = 'View';
  static const actionViewOnMaps      = 'View on Maps';
  static const actionOpenMaps        = 'Open Google Maps';
  static const actionWithdraw        = 'Withdraw';

  // -- Dialog / confirmation --------------------------------------------
  static const dialogLogoutTitle  = 'Log out';
  static const dialogLogoutBody   = 'Are you sure you want to log out?';
  static const dialogDeleteTitle  = 'Delete Account?';
  static const dialogDeleteBody   =
      'This action is permanent and cannot be undone.\n\n'
      'Note: You cannot delete your account if you have active orders or pending payouts.';
  static const dialogDeleteSupport       = 'Contact support to delete account.';
  static const dialogDeleteVendorSupport = 'Contact support to delete vendor account.';
  static const dialogVendorVerifyTitle   = 'Vendor Verification';
  static const dialogVendorVerifyBody    =
      "Enter the 4-digit code from the customer's app to release this item.";

  // -- Reservation / sheet labels ---------------------------------------
  static const reservationDetails      = 'Reservation Details';
  static const reservationIdPrefix     = 'ID: ';
  static const reservationCustomer     = 'Customer';
  static const reservationCustomerUc   = 'CUSTOMER';
  static const reservationBreakdown    = 'FINANCIAL BREAKDOWN';
  static const reservationProductPrice = 'Product Price';
  static const reservationAmountPaid   = 'Amount Paid';
  static const reservationOutstanding  = 'Outstanding Balance';
  static const reservationHandedOver   = 'Item Handed Over';
  static const reservationReadyHandover = 'Ready for Handover';
  static const reservationCollectedOn  = 'Collected on ';

  // -- Status labels - reservation --------------------------------------
  static const statusNew        = 'New';
  static const statusActive     = 'Active';
  static const statusReady      = 'Ready';
  static const statusCompleted  = 'Completed';
  static const statusClosed     = 'Closed';
  static const statusCancelled  = 'Cancelled';
  static const statusFulfilled  = 'FULFILLED';
  static const statusNewUc      = 'NEW';
  static const statusActiveUc   = 'ACTIVE';
  static const statusReadyUc    = 'READY TO PICKUP';
  static const statusCancelledUc = 'CANCELLED';

  // -- Status labels - product ------------------------------------------
  static const statusApproved   = 'Approved';
  static const statusPending    = 'Pending';
  static const statusRejected   = 'Rejected';
  static const statusOutOfStock = 'Out of stock';

  // -- Status labels - plan ---------------------------------------------
  static const statusPastDue         = 'Past Due';
  static const statusPendingApproval = 'Pending Approval';

  // -- Plan card labels -------------------------------------------------
  static const planPaidPrefix      = 'Paid: ';
  static const planRemainingPrefix = 'Remaining: ';
  static const planWaitingVendor   = 'Waiting for Vendor';
  static const planClosed          = 'Plan Closed';
  static const planAutoPay         = 'AutoPay';

  // -- Section headers --------------------------------------------------
  static const sectionRecentActivity  = 'Recent Activity';
  static const sectionYourPlans       = 'Your reserve plans';
  static const sectionStartPlan       = 'Start a new plan';
  static const sectionWalletPayments  = 'Wallet & payments';
  static const sectionPreferences     = 'Preferences';
  static const sectionSecurity        = 'Security';
  static const sectionHelpCenter      = 'Help Center';
  static const sectionFinance         = 'Finance';
  static const sectionBusinessDetails = 'Business Details';
  static const sectionLocationContact = 'Location & Contact';
  static const sectionSocialMedia     = 'Social Media';

  // -- Customer profile menu items --------------------------------------
  static const profileBankDetails        = 'Bank Details';
  static const profileMyStoreBalance     = 'My Store Balance';
  static const profileMyStoreBalanceSub  = 'View your store balance';
  static const profileLevelUpSlots       = 'Level Up Slots';
  static const profileLevelUpSlotsSub    = 'Unlock more reservation slots';
  static const profileMyMerchants        = 'My Merchants';
  static const profileMyMerchantsSub     = 'Merchants you interact with';
  static const profileStatements         = 'Statements & receipts';
  static const profileAppTheme           = 'App Theme';
  static const profileBiometric         = 'Biometric Sign-in';
  static const profileChangePassword     = 'Change password';
  static const profileLegal              = 'Legal & Privacy';

  // -- Vendor profile menu items ----------------------------------------
  static const vendorProfileSettlements      = 'Settlements & Ledger';
  static const vendorProfileSettlementsSub   = 'Earnings, vault & history';
  static const vendorProfileStoreBalances    = 'Customer Store Balances';
  static const vendorProfileStoreBalancesSub = 'Track retained customer balances';
  static const vendorProfilePayoutDetails    = 'Payout Details';
  static const vendorProfilePayoutSub        = 'Manage bank account';
  static const vendorProfileLegalName        = 'Legal Name';
  static const vendorProfileCacNumber        = 'CAC Number';
  static const vendorProfileStatus           = 'Status';
  static const vendorProfileCategories       = 'Categories';
  static const vendorProfileAddress          = 'Address';

  // -- Placeholder / fallback values ------------------------------------
  static const fallbackNotProvided  = 'Not Provided';
  static const fallbackNotAvailable = 'Not Available';
  static const fallbackLoading      = '...';

  // -- Empty states -----------------------------------------------------
  static const emptyRecentActivity  = 'No recent activity';
  static const emptyActivePlans     = 'No active plans yet';
  static const emptyPastePlanLink   = 'Paste a link below to start reserving.';
  static const emptyProfileCustomer = 'Profile not found';
  static const emptyProfileVendor   = 'Vendor profile not found.';

  // -- Error / failure messages -----------------------------------------
  static const errorLoadFailed   = 'Failed to load data, drag down to refresh';
  static const errorInvalidLink  = 'The link you provided is invalid';
  static const errorEnterLink    = 'Please enter a link to proceed';
  static const errorGeneric      = 'Error occurred';
  static const errorNoCustomer   = 'Customer data not available';
  static const errorOpenDialer   = 'Could not open phone dialer';
  static const errorOpenWhatsApp = 'Could not open WhatsApp';

  // -- Snackbar messages ------------------------------------------------
  static const snackComingSoon          = 'Coming soon!';
  static const snackSharingComingSoon   = 'Sharing coming soon!';
  static const snackQrComingSoon        = 'QR Code coming soon!';
  static const snackEditComingSoon      = 'Edit Profile coming soon!';
  static const snackPayoutComingSoon    = 'Payout settings coming soon!';
  static const snackBiometricComingSoon = 'Biometrics coming soon!';
  static const snackThemeComingSoon     = 'Themes are coming soon!';
  static const snackHandoverVerified    = 'Handover Verified! Inventory Updated.';

  // -- Vendor home / liveness -------------------------------------------
  static const vendorLivenessTitle   = 'Liveness Check Required';
  static const vendorLivenessBody    =
      'We need to verify your identity before you can withdraw funds. '
      'This is a security measure to protect your account.';
  static const vendorLivenessSupport = 'Contact support@korra.com.ng to continue';

  // -- Store balance screen labels --------------------------------------
  static const storeBalanceTotal        = 'Total Outstanding Balance';
  static const storeBalanceCustomers    = 'Customer Breakdown';
  static const storeBalanceAmountCol    = 'Amount (₦)';
  static const storeBalanceNone         = 'No outstanding balances';
  static const storeBalanceHeldBy       = 'Held by';
  static const storeBalanceHeldBySuffix = 'customers';

  // -- Vault / settlement labels ----------------------------------------
  static const vaultTitle    = 'SETTLEMENT VAULT';
  static const vaultViewAll  = 'View All';
  static const vaultNoFunds  = 'No funds currently locked.';
  static const vaultReleasing = 'Releasing';
  static const vaultUpcoming = 'Upcoming';
  static const vaultPending  = 'PENDING SETTLEMENT';
  static const vaultBalance  = 'Available Balance';
  static const vaultWithdraw = 'Withdraw';

  // -- Product labels ---------------------------------------------------
  static const productStockPrefix = 'Stock: ';
  static const productPaidPct     = '% Paid';
  static const productOf          = 'of ';
}