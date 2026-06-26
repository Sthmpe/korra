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

  // -- Auth / Login -----------------------------------------------------
  static const roleCustomer         = 'Customer';
  static const roleVendor           = 'Vendor';
  static const labelBiometricOr     = ' Or use biometric authentication ';
  static const signInAsCustomer     = 'Sign in as Customer';
  static const signInAsMerchant     = 'Sign in as Merchant';
  static const forgotPasswordLabel  = 'Forgot password?';
  static const actionCreateAccountLink = 'Create account';

  // -- Forgot password / Reset link ------------------------------------
  static const forgotPasswordHint      = "No worries. Enter your email and we'll send a reset link.";
  static const labelEmailLower         = 'Email address';
  static const actionSendResetLink     = 'Send reset link';
  static const actionBackToSignIn      = 'Back to sign in';
  static const resetLinkSentTitle      = 'Check your email';
  static const actionOpenMailApp       = 'Open mail app';
  static const actionUseDifferentEmail = 'Use a different email';

  // -- Signup screens --------------------------------------------------
  static const createCustomerAccountTitle   = 'Create Customer Account';
  static const createBusinessAccountTitle   = 'Create Business Account';
  static const actionCreateAccount          = 'Create Account';
  static const actionContinue               = 'Continue';
  static const snackAccountCreated          = 'Account created successfully!';
  static const snackBusinessAccountCreated  = 'Your business account has been created successfully.';
  static const signupFailedTitle            = 'Signup Failed';
  static const signupFailedDefault          = 'An unknown error occurred during signup.';
  static const snackAgreeToTerms            = 'Please agree to the terms to continue.';

  // -- Signup step titles / hints --------------------------------------
  static const stepPersonalTitle       = 'Personal Details';
  static const stepPersonalHint        = 'We need this to verify your identity later.';
  static const stepStoreTitle          = 'Store Details';
  static const stepStoreHint           = 'Tell us about your shop and where customers can find you.';
  static const stepDigitalTitle        = 'Digital Presence';
  static const stepDigitalHint         = 'Where can customers verify your business? Please provide at least 3 distinct links.';
  static const stepReviewCustomerTitle = 'Review & Consent';
  static const stepReviewCustomerHint  = 'Please double check your details before creating your account.';
  static const stepReviewVendorTitle   = 'Review Application';
  static const stepReviewVendorHint    = 'Please confirm your basic details before creating your account.';

  // -- Form labels -----------------------------------------------------
  static const labelFirstName    = 'First Name';
  static const labelLastName     = 'Last Name';
  static const labelOtherName    = 'Other Name';
  static const labelPhoneNumber  = 'Phone Number';
  static const labelEmailAddress = 'Email Address';
  static const labelPassword     = 'Password';

  // -- Form hints ------------------------------------------------------
  static const hintFirstName   = 'e.g. John';
  static const hintLastName    = 'e.g. Doe';
  static const hintOptional    = 'Optional';
  static const hintPhoneNumber = '080...';
  static const hintEmail       = 'you@example.com';

  // -- Store / categories ----------------------------------------------
  static const labelStoreName        = 'Store Name';
  static const hintStoreName         = 'e.g. Amazing Gadgets';
  static const labelCategories       = 'Categories';
  static const labelCategoryLimit    = 'Select 1-5';
  static const hintSearchCategories  = 'Search categories...';
  static const errorSelectCategory   = 'Select at least one category';
  static const errorMaxCategories    = 'Maximum 5 categories allowed';
  static const labelWhereSell        = 'Where do you sell?';
  static const presenceOnline        = 'Online';
  static const presencePhysical      = 'Physical';
  static const presenceBoth          = 'Both';

  // -- Social links ----------------------------------------------------
  static const labelInstagram         = 'Instagram';
  static const labelTwitterX          = 'Twitter / X';
  static const labelWhatsAppGroup     = 'WhatsApp Group';
  static const labelWebsite           = 'Website';
  static const labelWebsiteStore      = 'Website / Store Link';
  static const labelFacebook          = 'Facebook';
  static const labelTikTok            = 'TikTok';
  static const labelOtherLinktree     = 'Other (Linktree)';
  static const labelOtherLinktreeEtc  = 'Other (Linktree, etc)';

  // -- Review card labels ----------------------------------------------
  static const reviewLabelFullName    = 'Full Name';
  static const reviewLabelEmailAddress = 'Email Address';
  static const reviewLabelPhoneNumber = 'Phone Number';
  static const reviewLabelPhone       = 'Phone';
  static const reviewLabelStoreName   = 'Store Name';
  static const reviewLabelPresence    = 'Presence';
  static const reviewLabelCategories  = 'Categories';
  static const reviewSectionOwner     = 'Owner Details';
  static const reviewSectionStore     = 'Store Details';
  static const reviewSectionSocial    = 'Social Presence';
  static const reviewNoLinks          = 'No links provided';

  // -- Legal consent ---------------------------------------------------
  static const legalTermsOfService      = 'Terms of Service';
  static const legalPrivacyPolicy       = 'Privacy Policy';
  static const legalVendorPartnership   = 'Vendor Partnership Agreement';
  static const legalConsentCustomerPrefix = "By creating an account, you confirm that you have read and agree to Korra's ";
  static const legalConsentVendorPrefix = "By checking this box, I agree to Korra's ";
  static const legalConsentAnd          = ' and ';
  static const legalConsentComma        = ', ';

  // -- Legal PDF screen ------------------------------------------------
  static const legalMerchantTermsTitle   = 'Merchant Terms of Service';
  static const legalPartnershipTitle     = 'Partnership & Integrity Policy';
  static const legalMerchantPrivacyTitle = 'Merchant Privacy Policy';
  static const legalCustomerTermsTitle   = 'Customer Terms of Service';
  static const legalCustomerPrivacyTitle = 'Privacy Policy';
  static const documentLoadingPrefix     = 'Loading Document... ';
  static const documentLoadError         = 'Failed to load document.\nPlease check your connection.';

  // -- Progress bar ----------------------------------------------------
  static const progressRequirementMet = 'Requirement Met';
  static const progressLinksAdded     = ' Links Added';
  static const progressAddMoreSuffix  = ' more to continue.';

  // -- Validation messages ---------------------------------------------
  static const validationEmailRequired    = 'Email is required';
  static const validationEmailInvalid     = 'Enter a valid email';
  static const validationPasswordRequired = 'Password is required';
  static const validationPasswordMin      = 'Minimum 6 characters';
  static const validationRequired         = 'Required';
  static const validationPhoneInvalid     = 'Enter a valid phone number';
  static const validationAddMoreLinks     = 'Add more links';
}