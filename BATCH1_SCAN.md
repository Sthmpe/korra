# BATCH 1 SCAN RESULTS - lib/presentation/auth/
# DO NOT RE-SCAN. Use this data directly.
# Total files: 19

---

## STEP A - Write these missing tokens FIRST before touching any UI file

### colors.dart - add these immediately:
```dart
static const Color surfaceCool = Color(0xFFF2F2F7);
static const Color labelGrey = Color(0xFF666666);
static const Color inputIconGrey = Color(0xFF9CA3AF);
static const Color inputPlaceholder = Color(0xFFAAAAAA);
static const Color inputBgInactive = Color(0xFFF7F7F7);
static const Color inputBorderInactive = Color(0xFFE5E5E5);
static const Color dividerSubtle = Color(0xFFF0F0F0);
static const Color legalBorder = Color(0xFFF3F4F6);
static const Color borderCool = Color(0xFFE5E7EB);
static const Color textBodyCool = Color(0xFF4B5563);
static const Color iosBlack = Color(0xFF1C1C1E);
static const Color successText = Color(0xFF15803D);
static const Color warningText = Color(0xFFC2410C);
static const Color progressSuccessBg = Color(0xFFF0FDF4);
static const Color progressSuccessBorder = Color(0xFFBBF7D0);
static const Color instagram = Color(0xFFE1306C);
static const Color facebook = Color(0xFF1877F2);
static const Color black54 = Color(0x8A000000);
static const Color errorIconLight = Color(0xFFE57373);
static const Color readOnlyBg = Color(0xFFF0F0F0);
static const Color greyShade100 = Color(0xFFF5F5F5);
static const Color warningBorder = Color(0xFFFFEDD5);
```

### sizes.dart - add these immediately:
```dart
static const double segmentRadius = 14.0;
static const double logoRadius = 18.0;
static const double pillRadius = 99.0;
static const double s2 = 2.0;
static const double s4 = 4.0;
static const double s5 = 5.0;
static const double s6 = 6.0;
static const double s7 = 7.0;
static const double s14 = 14.0;
static const double s48 = 48.0;
static const double font2xlPlus = 22.0;
static const double fontMdPlus = 15.0;
static const double fontSmPlus = 13.0;
static const double fontSmPlusH = 13.5;
static const double fontMdHalf = 14.5;
static const double fontSmHalf = 12.5;
static const double fontXs = 11.0;
static const double trackingSnug = -0.5;
static const double trackingTight = -0.8;
static const double lineHeightMd = 1.4;
static const double icon3xl = 48.0;
```

### strings.dart - add these immediately:
```dart
// Auth / Login
static const String roleCustomer = 'Customer';
static const String roleVendor = 'Vendor';
static const String labelBiometricOr = ' Or use biometric authentication ';
static const String signInAsCustomer = 'Sign in as Customer';
static const String signInAsMerchant = 'Sign in as Merchant';
static const String forgotPasswordLabel = 'Forgot password?';
static const String actionCreateAccountLink = 'Create account';
static const String actionContinueGoogle = 'Continue with Google';

// Forgot password / Reset link
static const String forgotPasswordHint = "No worries. Enter your email and we'll send a reset link.";
static const String labelEmailLower = 'Email address';
static const String actionSendResetLink = 'Send reset link';
static const String actionBackToSignIn = 'Back to sign in';
static const String resetLinkSentTitle = 'Check your email';
static const String actionOpenMailApp = 'Open mail app';
static const String actionUseDifferentEmail = 'Use a different email';

// Signup screens
static const String createCustomerAccountTitle = 'Create Customer Account';
static const String createBusinessAccountTitle = 'Create Business Account';
static const String actionCreateAccount = 'Create Account';
static const String actionContinue = 'Continue';
static const String snackAccountCreated = 'Account created successfully!';
static const String snackBusinessAccountCreated = 'Your business account has been created successfully.';
static const String signupFailedTitle = 'Signup Failed';
static const String signupFailedDefault = 'An unknown error occurred during signup.';
static const String snackAgreeToTerms = 'Please agree to the terms to continue.';

// Signup step titles / hints
static const String stepPersonalTitle = 'Personal Details';
static const String stepPersonalHint = 'We need this to verify your identity later.';
static const String stepStoreTitle = 'Store Details';
static const String stepStoreHint = 'Tell us about your shop and where customers can find you.';
static const String stepDigitalTitle = 'Digital Presence';
static const String stepDigitalHint = 'Where can customers verify your business? Please provide at least 3 distinct links.';
static const String stepReviewCustomerTitle = 'Review & Consent';
static const String stepReviewCustomerHint = 'Please double check your details before creating your account.';
static const String stepReviewVendorTitle = 'Review Application';
static const String stepReviewVendorHint = 'Please confirm your basic details before creating your account.';

// Form labels
static const String labelFirstName = 'First Name';
static const String labelLastName = 'Last Name';
static const String labelOtherName = 'Other Name';
static const String labelPhoneNumber = 'Phone Number';
static const String labelEmailAddress = 'Email Address';
static const String labelPassword = 'Password';

// Form hints
static const String hintFirstName = 'e.g. John';
static const String hintLastName = 'e.g. Doe';
static const String hintOptional = 'Optional';
static const String hintPhoneNumber = '080...';
static const String hintEmail = 'you@example.com';

// Store / categories
static const String labelStoreName = 'Store Name';
static const String hintStoreName = 'e.g. Amazing Gadgets';
static const String labelCategories = 'Categories';
static const String labelCategoryLimit = 'Select 1-5';
static const String hintSearchCategories = 'Search categories...';
static const String errorSelectCategory = 'Select at least one category';
static const String errorMaxCategories = 'Maximum 5 categories allowed';
static const String labelWhereSell = 'Where do you sell?';
static const String presenceOnline = 'Online';
static const String presencePhysical = 'Physical';
static const String presenceBoth = 'Both';

// Social links
static const String labelInstagram = 'Instagram';
static const String labelTwitterX = 'Twitter / X';
static const String labelWhatsAppGroup = 'WhatsApp Group';
static const String labelWebsite = 'Website';
static const String labelWebsiteStore = 'Website / Store Link';
static const String labelFacebook = 'Facebook';
static const String labelTikTok = 'TikTok';
static const String labelOtherLinktree = 'Other (Linktree)';
static const String labelOtherLinktreeEtc = 'Other (Linktree, etc)';

// Review card labels
static const String reviewLabelFullName = 'Full Name';
static const String reviewLabelEmailAddress = 'Email Address';
static const String reviewLabelPhoneNumber = 'Phone Number';
static const String reviewLabelPhone = 'Phone';
static const String reviewLabelStoreName = 'Store Name';
static const String reviewLabelPresence = 'Presence';
static const String reviewLabelCategories = 'Categories';
static const String reviewSectionOwner = 'Owner Details';
static const String reviewSectionStore = 'Store Details';
static const String reviewSectionSocial = 'Social Presence';
static const String reviewNoLinks = 'No links provided';

// Legal consent
static const String legalTermsOfService = 'Terms of Service';
static const String legalPrivacyPolicy = 'Privacy Policy';
static const String legalVendorPartnership = 'Vendor Partnership Agreement';
static const String legalConsentCustomerPrefix = "By creating an account, you confirm that you have read and agree to Korra's ";
static const String legalConsentVendorPrefix = "By checking this box, I agree to Korra's ";
static const String legalConsentAnd = ' and ';
static const String legalConsentComma = ', ';

// Legal PDF screen
static const String legalMerchantTermsTitle = 'Merchant Terms of Service';
static const String legalPartnershipTitle = 'Partnership & Integrity Policy';
static const String legalMerchantPrivacyTitle = 'Merchant Privacy Policy';
static const String legalCustomerTermsTitle = 'Customer Terms of Service';
static const String legalCustomerPrivacyTitle = 'Privacy Policy';
static const String documentLoadingPrefix = 'Loading Document... ';
static const String documentLoadError = 'Failed to load document.\nPlease check your connection.';

// Progress bar
static const String progressRequirementMet = 'Requirement Met';
static const String progressLinksAdded = ' Links Added';
static const String progressAddMoreSuffix = ' more to continue.';

// Validation messages
static const String validationEmailRequired = 'Email is required';
static const String validationEmailInvalid = 'Enter a valid email';
static const String validationPasswordRequired = 'Password is required';
static const String validationPasswordMin = 'Minimum 6 characters';
static const String validationRequired = 'Required';
static const String validationPhoneInvalid = 'Enter a valid phone number';
static const String validationAddMoreLinks = 'Add more links';
```

### gaps.dart - add these immediately:
```dart
static const Widget h2 = SizedBox(height: 2);
static const Widget h54 = SizedBox(height: 54);
static const Widget h60 = SizedBox(height: 60);
static const Widget h80 = SizedBox(height: 80);
static const Widget w6 = SizedBox(width: 6);
```

### paddings.dart - add these immediately:
```dart
static EdgeInsets get top2 => EdgeInsets.only(top: KorraSizes.s2.h);
static EdgeInsets get top20 => EdgeInsets.only(top: KorraSizes.s20.h);
static EdgeInsets get bottom8 => EdgeInsets.only(bottom: KorraSizes.s8.h);
static EdgeInsets get right12 => EdgeInsets.only(right: KorraSizes.s12.w);
static EdgeInsets get v10 => EdgeInsets.symmetric(vertical: KorraSizes.s10.h);
static EdgeInsets get h35 => EdgeInsets.symmetric(horizontal: KorraSizes.s35.w);
static EdgeInsets get headerBar => EdgeInsets.symmetric(horizontal: KorraSizes.s20.w, vertical: KorraSizes.s16.h);
static EdgeInsets get chipContent => EdgeInsets.symmetric(horizontal: KorraSizes.s16.w, vertical: KorraSizes.s10.h);
static EdgeInsets get sheetFailure => EdgeInsets.fromLTRB(KorraSizes.s20.w, KorraSizes.s16.h, KorraSizes.s20.w, KorraSizes.s20.h);
static EdgeInsets get legalContent => EdgeInsets.fromLTRB(KorraSizes.s20.w, KorraSizes.s20.h, KorraSizes.s20.w, KorraSizes.s40.h);
static EdgeInsets get bulletMargin => EdgeInsets.only(top: KorraSizes.s7.h, right: KorraSizes.s10.w);
static EdgeInsets get all4 => EdgeInsets.all(KorraSizes.s4.r);
static EdgeInsets get v16 => EdgeInsets.symmetric(vertical: KorraSizes.s16.h);
```

---

After writing ALL token files above - confirm each file written and run git add on each.
Then proceed to STEP B.

---

## STEP B - Replace hardcoded values in all 19 UI files

Do all 19 files without stopping between them.
Only stop after ALL 19 files are done.
Confirm each file written and run git add on each.

---

### FILE 1 - role_login/role_login_screen.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| scaffold bg | Colors.white | KorraColors.white |
| padding vertical | 40.h (inline in EdgeInsets) | KorraSizes.s40.h |
| SizedBox(height: 40.h) | gap | Gaps.h40 |
| button border | Color(0xFFE5E7EB) | KorraColors.borderCool |
| button border radius | BorderRadius.circular(16.r) | BorderRadius.circular(KorraSizes.cardRadius.r) |
| button bg | Colors.white | KorraColors.white |
| SizedBox(width: 12.w) | gap | Gaps.w12 |
| 'Continue with Google' | string | KorraStrings.actionContinueGoogle |
| button label fontSize: 15.sp | font size | KorraSizes.fontMdPlus.sp |
| button label FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| button label Color(0xFF1B1B1B) | color | KorraColors.black |
| SizedBox(height: 20.h) | gap | Gaps.h20 |

---

### FILE 2 - role_login/widgets/login_fields.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| email field icon | Iconsax.sms | KorraIcons.email |
| SizedBox(height: 16.h) | gap | Gaps.h16 |
| password field icon | Iconsax.lock | KorraIcons.lock |
| SizedBox(height: 24.h) | gap | Gaps.h24 |
| "Forgot password?" fontSize: 13.5.sp | font size | KorraSizes.fontSmPlusH.sp |
| "Forgot password?" FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| "Create account" fontSize: 13.5.sp | font size | KorraSizes.fontSmPlusH.sp |
| "Create account" FontWeight.w700 | weight | KorraSizes.weightBold |
| Color(0xFFF2F2F7) inactive fill | color | KorraColors.surfaceCool |
| BorderRadius.circular(16.r) container | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| input text fontSize: 15.sp | font size | KorraSizes.fontMdPlus.sp |
| input text FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| input text Color(0xFF1B1B1B) | color | KorraColors.black |
| hint fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| hint FontWeight.w500 | weight | KorraSizes.weightMedium |
| hint/icon Color(0xFF9CA3AF) | color | KorraColors.inputIconGrey |
| icon size: 20.sp x 2 | icon size | KorraSizes.iconMd.sp |
| Iconsax.eye | icon | KorraIcons.eye |
| Iconsax.eye_slash | icon | KorraIcons.eyeOff |
| all 5x BorderRadius.circular(16.r) in borders | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| BoxConstraints(minWidth: 48.w) | size | BoxConstraints(minWidth: KorraSizes.s48.w) |
| EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h) | padding | KorraPaddings.inputContent |
| error Colors.red.shade600 | color | KorraColors.error |
| error fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| error FontWeight.w500 | weight | KorraSizes.weightMedium |

---

### FILE 3 - role_login/widgets/login_header.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| logo EdgeInsets.all(2.r) | padding | EdgeInsets.all(KorraSizes.s2.r) |
| SizedBox(height: 20.h) | gap | Gaps.h20 |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| subtitle Color(0xFF666666) | color | KorraColors.labelGrey |

---

### FILE 4 - role_login/widgets/login_button.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| spinner Colors.white | color | KorraColors.white |

---

### FILE 5 - role_login/widgets/role_divider.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| EdgeInsets.symmetric(horizontal: 20.0.w) | padding | KorraPaddings.pageH |
| "Or use biometric..." fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| Colors.grey.shade500 | color | KorraColors.greyCancel |
| FontWeight.w600 | weight | KorraSizes.weightSemiBold |

---

### FILE 6 - role_login/widgets/role_selector.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| outer bg Color(0xFFF2F2F7) | color | KorraColors.surfaceCool |
| outer BorderRadius.circular(14.r) | radius | BorderRadius.circular(KorraSizes.segmentRadius.r) |
| pill BorderRadius.circular(10.r) | radius | BorderRadius.circular(KorraSizes.chipRadius.r) |
| icon size: 18.sp | size | KorraSizes.fontXl.sp |
| active text/icon Color(0xFF1C1C1E) | color | KorraColors.iosBlack |
| SizedBox(width: 6.w) | gap | Gaps.w6 |

---

### FILE 7 - forgot_password/forgot_password_screen.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| AppBar title fontSize: 16.sp | font size | KorraSizes.fontLg.sp |
| AppBar title FontWeight.w700 | weight | KorraSizes.weightBold |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| subtitle fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| subtitle FontWeight.w500 | weight | KorraSizes.weightMedium |
| SizedBox(height: 40.h) | gap | Gaps.h40 |
| second SizedBox(height: 8.h) | gap | Gaps.h8 |
| SizedBox(height: 12.h) | gap | Gaps.h12 |
| SizedBox(height: 20.h) | gap | Gaps.h20 |
| email field icon Iconsax.sms | icon | KorraIcons.email |
| fontSize: 13.5.sp x 2 | font size | KorraSizes.fontSmPlusH.sp |
| icon size: 18.sp | size | KorraSizes.fontXl.sp |
| errorStyle fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| button padding vertical: 14.h | padding | KorraSizes.s14.h |
| button text fontSize: 16.sp | font size | KorraSizes.fontLg.sp |
| button text FontWeight.w700 | weight | KorraSizes.weightBold |
| "Back to sign in" fontSize: 14.sp | font size | KorraSizes.fontMd.sp |

---

### FILE 8 - forgot_password/reset_link_sent_screen.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| Iconsax.message_favorite | icon | KorraIcons.messageFavorite |
| SizedBox(height: 24.h) | gap | Gaps.h24 |
| heading fontSize: 32.sp | font size | KorraSizes.font5xl.sp |
| heading FontWeight.w700 | weight | KorraSizes.weightBold |
| SizedBox(height: 20.h) | gap | Gaps.h20 |
| subtext fontSize: 18.sp | font size | KorraSizes.fontXl.sp |
| subtext FontWeight.w500 | weight | KorraSizes.weightMedium |
| button padding vertical: 14.h | padding | KorraSizes.s14.h |
| all 3x button text fontSize: 16.sp | font size | KorraSizes.fontLg.sp |
| all 3x button text FontWeight.w700 | weight | KorraSizes.weightBold |
| second SizedBox(height: 20.h) | gap | Gaps.h20 |

---

### FILE 9 - sgnup_failure_sheet.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h) | padding | KorraPaddings.sheetFailure |
| handle bar width: 40.w | size | KorraSizes.s40.w |
| handle bar height: 4.h | size | KorraSizes.s4.h |
| SizedBox(height: 24.h) x 2 | gap | Gaps.h24 |
| Iconsax.warning_2 | icon | KorraIcons.warning |
| SizedBox(height: 16.h) x 2 | gap | Gaps.h16 |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| SizedBox(width: 12.w) | gap | Gaps.w12 |
| "Try Again" text Colors.white | color | KorraColors.white |
| SizedBox(height: 16.h) bottom | gap | Gaps.h16 |

---

### FILE 10 - signup_customer/signup_customer_screen.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| scaffold bg Colors.white | color | KorraColors.white |
| appBar bg Colors.white | color | KorraColors.white |
| leading icon Iconsax.arrow_left | icon | KorraIcons.back |
| leading icon size: 24.sp | size | KorraSizes.iconLg.sp |
| leading icon Colors.black | color | KorraColors.pureBlack |
| appBar title fontSize: 18.sp | font size | KorraSizes.fontXl.sp |
| appBar title FontWeight.w700 | weight | KorraSizes.weightBold |
| appBar title Color(0xFF111111) | color | KorraColors.nearBlack |
| appBar title letterSpacing: -0.5 | tracking | KorraSizes.trackingSnug |
| stepper padding vertical: 12.h | inline | KorraSizes.s12.h |
| stepper track Color(0xFFF2F2F7) | color | KorraColors.surfaceCool |
| stepper BorderRadius.circular(2.r) x 2 | radius | BorderRadius.circular(KorraSizes.s2.r) |
| step text fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| step text FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| step text Color(0xFF666666) | color | KorraColors.labelGrey |
| bottom nav padding 16.h in fromLTRB | inline | KorraSizes.s16.h |
| back btn BorderRadius.circular(16.r) | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| back btn Color(0xFFE5E7EB).withOpacity(0.45) | color | KorraColors.borderCool.withOpacity(0.45) |
| back btn bg Colors.white | color | KorraColors.white |
| back btn Iconsax.arrow_left | icon | KorraIcons.back |
| back btn icon Colors.black | color | KorraColors.pureBlack |
| back btn size: 24.sp | size | KorraSizes.iconLg.sp |
| SizedBox(width: 12.w) | gap | Gaps.w12 |
| next btn BorderRadius.circular(16.r) | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| next btn spinner/text Colors.white x 2 | color | KorraColors.white |
| next btn fontSize: 16.sp | font size | KorraSizes.fontLg.sp |
| next btn FontWeight.w700 | weight | KorraSizes.weightBold |

---

### FILE 11 - signup_customer/steps/step_personal.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| scroll padding EdgeInsets.symmetric(horizontal: 20.w) | padding | KorraPaddings.pageH |
| title fontSize: 24.sp | font size | KorraSizes.font3xl.sp |
| title FontWeight.w800 | weight | KorraSizes.weightExtraBold |
| title Color(0xFF111111) | color | KorraColors.nearBlack |
| title letterSpacing: -0.8 | tracking | KorraSizes.trackingTight |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| subtitle fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| subtitle Color(0xFF666666) | color | KorraColors.labelGrey |
| subtitle height: 1.4 | line height | KorraSizes.lineHeightMd |
| SizedBox(height: 32.h) | gap | Gaps.h32 |
| SizedBox(width: 16.w) | gap | Gaps.w16 |
| SizedBox(height: 24.h) x 3 | gap | Gaps.h24 |
| phone icon Iconsax.call | icon | KorraIcons.phone |
| phone icon Colors.grey.shade400 | color | KorraColors.greyShade400 |
| phone icon size: 20.sp | size | KorraSizes.iconMd.sp |
| email icon Iconsax.tick_circle | icon | KorraIcons.successOutline |
| email icon Colors.green | color | KorraColors.receiptCredit |
| email icon size: 20.sp | size | KorraSizes.iconMd.sp |
| SizedBox(height: 40.h) | gap | Gaps.h40 |
| label Color(0xFF111111) | color | KorraColors.nearBlack |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| readOnly bg Color(0xFFF0F0F0) | color | KorraColors.readOnlyBg |
| inactive bg Color(0xFFF7F7F7) | color | KorraColors.inputBgInactive |
| focused bg Colors.white | color | KorraColors.white |
| all 6x BorderRadius.circular(12.r) | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| border Color(0xFFE5E5E5) | color | KorraColors.inputBorderInactive |
| input text fontSize: 15.sp | font size | KorraSizes.fontMdPlus.sp |
| input text FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| input text Color(0xFF1B1B1B) | color | KorraColors.black |
| hint fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| hint FontWeight.w400 | weight | KorraSizes.weightRegular |
| hint Color(0xFFAAAAAA) | color | KorraColors.inputPlaceholder |
| EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h) | padding | KorraPaddings.inputContent |
| errorStyle fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| errorStyle FontWeight.w500 | weight | KorraSizes.weightMedium |

---

### FILE 12 - signup_customer/steps/step_review.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| scroll padding EdgeInsets.symmetric(horizontal: 20.w) | padding | KorraPaddings.pageH |
| title fontSize: 22.sp | font size | KorraSizes.font2xlPlus.sp |
| title FontWeight.w800 | weight | KorraSizes.weightExtraBold |
| title Color(0xFF111111) | color | KorraColors.nearBlack |
| title letterSpacing: -0.5 | tracking | KorraSizes.trackingSnug |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| subtitle fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| subtitle Color(0xFF666666) | color | KorraColors.labelGrey |
| subtitle height: 1.4 | line height | KorraSizes.lineHeightMd |
| SizedBox(height: 32.h) | gap | Gaps.h32 |
| card EdgeInsets.all(20.r) | padding | KorraPaddings.all20 |
| card bg Colors.white | color | KorraColors.white |
| card BorderRadius.circular(16.r) | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| card border Color(0xFFE5E5E5).withOpacity(0.35) | color | KorraColors.inputBorderInactive.withOpacity(0.35) |
| divider Color(0xFFF0F0F0) | color | KorraColors.dividerSubtle |
| Iconsax.user | icon | KorraIcons.account |
| Iconsax.sms | icon | KorraIcons.email |
| Iconsax.call | icon | KorraIcons.phone |
| legal box EdgeInsets.all(16.r) | padding | KorraPaddings.all16 |
| legal bg Color(0xFFF9FAFB) | color | KorraColors.surface |
| legal BorderRadius.circular(12.r) | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| shield icon padding EdgeInsets.only(top: 2.h) | inline | EdgeInsets.only(top: KorraSizes.s2.h) |
| Iconsax.shield_tick | icon | KorraIcons.shieldCheck |
| size: 18.sp | size | KorraSizes.fontXl.sp |
| SizedBox(width: 12.w) | gap | Gaps.w12 |
| legal text fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| legal text Color(0xFF4B5563) | color | KorraColors.textBodyCool |
| legal text height: 1.5 | line height | KorraSizes.lineHeightNormal |
| SizedBox(height: 40.h) | gap | Gaps.h40 |
| icon box EdgeInsets.all(8.r) | padding | KorraPaddings.all8 |
| icon box bg Color(0xFFF7F7F7) | color | KorraColors.inputBgInactive |
| icon box BorderRadius.circular(8.r) | radius | BorderRadius.circular(KorraSizes.sm.r) |
| SizedBox(width: 12.w) | gap | Gaps.w12 |
| icon size: 16.sp | size | KorraSizes.fontLg.sp |
| icon Color(0xFF666666) | color | KorraColors.labelGrey |
| label fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| label FontWeight.w500 | weight | KorraSizes.weightMedium |
| label Color(0xFF8E8E93) | color | KorraColors.textSecondary |
| SizedBox(height: 2.h) | gap | Gaps.h2 |
| value fontSize: 14.5.sp | font size | KorraSizes.fontMdHalf.sp |
| value FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| value Color(0xFF1C1C1E) | color | KorraColors.iosBlack |

---

### FILE 13 - signup_vendor/signup_vendor_screen.dart

Same widget structure as FILE 10. Apply all FILE 10 replacements, plus:

| Location | Hardcoded value | Replacement |
|---|---|---|
| back btn const BorderSide(color: Color(0xFFE5E7EB)) | color | KorraColors.borderCool |

---

### FILE 14 - signup_vendor/steps_v/step_personal.dart

Identical widget structure to FILE 11. Apply all FILE 11 replacements exactly.

---

### FILE 15 - signup_vendor/steps_v/step_store_details.dart

Apply all FILE 11 _PremiumInput replacements, plus:

| Location | Hardcoded value | Replacement |
|---|---|---|
| scroll padding EdgeInsets.symmetric(horizontal: 20.w) | padding | KorraPaddings.pageH |
| title fontSize: 22.sp | font size | KorraSizes.font2xlPlus.sp |
| title Color(0xFF111111) | color | KorraColors.nearBlack |
| title FontWeight.w800 | weight | KorraSizes.weightExtraBold |
| title letterSpacing: -0.5 | tracking | KorraSizes.trackingSnug |
| category label fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| category label FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| category label Color(0xFF111111) | color | KorraColors.nearBlack |
| category count fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| category count Color(0xFF8E8E93) | color | KorraColors.textSecondary |
| search border Colors.grey.shade300 | color | KorraColors.greyShade300 |
| search border BorderRadius.circular(12.r) x 3 | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| chip container EdgeInsets.all(12.w) | padding | KorraPaddings.all12 |
| chip container BorderRadius.circular(12.r) | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| empty state fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| empty state Colors.grey.shade500 | color | KorraColors.greyCancel |
| empty state FontWeight.w500 | weight | KorraSizes.weightMedium |
| error text Colors.red | color | KorraColors.error |
| error text fontSize: 12.sp | font size | KorraSizes.fontSm.sp |
| error text FontWeight.w500 | weight | KorraSizes.weightMedium |
| divider Color(0xFFF0F0F0) x 2 | color | KorraColors.dividerSubtle |
| "Where do you sell?" fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| "Where do you sell?" FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| "Where do you sell?" Color(0xFF111111) | color | KorraColors.nearBlack |
| presence toggle EdgeInsets.all(4.r) | padding | KorraPaddings.all4 |
| presence toggle Color(0xFFF2F2F7) | color | KorraColors.surfaceCool |
| presence toggle BorderRadius.circular(12.r) | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| "Digital Presence" fontSize: 16.sp | font size | KorraSizes.fontLg.sp |
| "Digital Presence" FontWeight.w700 | weight | KorraSizes.weightBold |
| "Digital Presence" Color(0xFF111111) | color | KorraColors.nearBlack |
| _RequirementProgress EdgeInsets.all(16.r) | padding | KorraPaddings.all16 |
| _RequirementProgress incomplete bg Color(0xFFFFF7ED) | color | KorraColors.warningBg |
| _RequirementProgress complete bg Color(0xFFF0FDF4) | color | KorraColors.progressSuccessBg |
| _RequirementProgress BorderRadius.circular(12.r) | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| _RequirementProgress fontSize: 12.5.sp | font size | KorraSizes.fontSmHalf.sp |
| _RequirementProgress FontWeight.w700 | weight | KorraSizes.weightBold |
| _RequirementProgress fill Color(0xFF16A34A) | color | KorraColors.creditGreen |
| _RequirementProgress progress bg Colors.white | color | KorraColors.white |
| _RequirementProgress BorderRadius.circular(99.r) x 2 | radius | BorderRadius.circular(KorraSizes.pillRadius.r) |
| _RequirementProgress incomplete text Color(0xFFC2410C) | color | KorraColors.warningText |
| _RequirementProgress add more fontSize: 11.sp | font size | KorraSizes.fontXs.sp |
| Iconsax.shop | icon | KorraIcons.store |
| Iconsax.search_normal | icon | KorraIcons.search |
| Iconsax.tick_circle | icon | KorraIcons.successOutline |
| Iconsax.link_1 | icon | KorraIcons.linkVariant |
| Icons.tiktok | icon | KorraIcons.tiktok |
| Instagram Color(0xFFE1306C) | color | KorraColors.instagram |
| WhatsApp Color(0xFF25D366) | color | KorraColors.whatsappGreen |
| Facebook Color(0xFF1877F2) | color | KorraColors.facebook |
| selected bg Colors.white | color | KorraColors.white |
| unselected bg Colors.transparent | color | KorraColors.transparent |
| BorderRadius.circular(10.r) | radius | BorderRadius.circular(KorraSizes.chipRadius.r) |
| tab fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| tab FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| tab FontWeight.w500 | weight | KorraSizes.weightMedium |
| tab Color(0xFF111111) | color | KorraColors.nearBlack |
| tab Color(0xFF8E8E93) | color | KorraColors.textSecondary |
| chip unselected bg Colors.white | color | KorraColors.white |
| chip selected text Colors.white | color | KorraColors.white |
| chip unselected text Color(0xFF111111) | color | KorraColors.nearBlack |
| chip BorderRadius.circular(20.r) | radius | BorderRadius.circular(KorraSizes.s20.r) |
| chip fontSize: 12.5.sp | font size | KorraSizes.fontSmHalf.sp |
| chip FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| chip FontWeight.w500 | weight | KorraSizes.weightMedium |

---

### FILE 16 - signup_vendor/steps_v/step_socials.dart

Apply all FILE 15 _SocialInput and _RequirementProgress replacements, plus:

| Location | Hardcoded value | Replacement |
|---|---|---|
| _RequirementProgress BorderRadius.circular(16.r) | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| _RequirementProgress border Color(0xFFBBF7D0) | color | KorraColors.progressSuccessBorder |
| _RequirementProgress border Color(0xFFFFEDD5) | color | KorraColors.warningBorder |
| WA Color(0xFF25D366) | color | KorraColors.whatsappGreen |
| FB Color(0xFF1877F2) | color | KorraColors.facebook |

---

### FILE 17 - signup_vendor/steps_v/step_review_vendor.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| scroll padding EdgeInsets.symmetric(horizontal: 20.w) | padding | KorraPaddings.pageH |
| title fontSize: 22.sp | font size | KorraSizes.font2xlPlus.sp |
| title FontWeight.w800 | weight | KorraSizes.weightExtraBold |
| title Color(0xFF111111) | color | KorraColors.nearBlack |
| title letterSpacing: -0.5 | tracking | KorraSizes.trackingSnug |
| SizedBox(height: 8.h) | gap | Gaps.h8 |
| subtitle fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| subtitle Color(0xFF666666) | color | KorraColors.labelGrey |
| subtitle height: 1.4 | line height | KorraSizes.lineHeightMd |
| SizedBox(height: 32.h) | gap | Gaps.h32 |
| card EdgeInsets.all(20.r) | padding | KorraPaddings.all20 |
| card bg Colors.white | color | KorraColors.white |
| card BorderRadius.circular(16.r) | radius | BorderRadius.circular(KorraSizes.cardRadius.r) |
| Iconsax.user | icon | KorraIcons.account |
| Iconsax.shop | icon | KorraIcons.store |
| Iconsax.global | icon | KorraIcons.globe |
| divider padding EdgeInsets.symmetric(vertical: 16.h) | padding | KorraPaddings.v16 |
| divider Color(0xFFF0F0F0) x 2 | color | KorraColors.dividerSubtle |
| legal agreed bg Color(0xFFF0FDF4) | color | KorraColors.progressSuccessBg |
| legal unagreed bg Color(0xFFF9FAFB) | color | KorraColors.surface |
| legal BorderRadius.circular(12.r) | radius | BorderRadius.circular(KorraSizes.fieldRadius.r) |
| checkbox BorderRadius.circular(6.r) | radius | BorderRadius.circular(KorraSizes.s6.r) |
| checkbox Colors.white bg | color | KorraColors.white |
| checkbox border Colors.grey.shade300 | color | KorraColors.greyShade300 |
| check Icons.check | icon | KorraIcons.check |
| check size: 16.sp | size | KorraSizes.fontLg.sp |
| check Colors.white | color | KorraColors.white |
| SizedBox(width: 12.w) | gap | Gaps.w12 |
| legal text fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| legal text Color(0xFF4B5563) | color | KorraColors.textBodyCool |
| SizedBox(height: 40.h) | gap | Gaps.h40 |
| _SectionHeader icon size: 18.sp | size | KorraSizes.fontXl.sp |
| _SectionHeader SizedBox(width: 8.w) | gap | Gaps.w8 |
| _SectionHeader fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| _SectionHeader FontWeight.w700 | weight | KorraSizes.weightBold |
| _SectionHeader Color(0xFF111111) | color | KorraColors.nearBlack |
| _ReviewRow EdgeInsets.only(bottom: 8.h) | inline | EdgeInsets.only(bottom: KorraSizes.s8.h) |
| _ReviewRow label fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| _ReviewRow label FontWeight.w500 | weight | KorraSizes.weightMedium |
| _ReviewRow label Color(0xFF8E8E93) | color | KorraColors.textSecondary |
| _ReviewRow SizedBox(width: 16.w) | gap | Gaps.w16 |
| _ReviewRow value fontSize: 13.5.sp | font size | KorraSizes.fontSmPlusH.sp |
| _ReviewRow value FontWeight.w600 | weight | KorraSizes.weightSemiBold |
| _ReviewRow value Color(0xFF1C1C1E) | color | KorraColors.iosBlack |

---

### FILE 18 - legal/legal__sheet.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| modal bg Colors.transparent | color | KorraColors.transparent |
| container bg Colors.white | color | KorraColors.white |
| BorderRadius.vertical(top: Radius.circular(24.r)) | radius | BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)) |
| margin EdgeInsets.only(top: 40.h) | inline | EdgeInsets.only(top: KorraSizes.s40.h) |
| header padding EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w) | inline | EdgeInsets.symmetric(vertical: KorraSizes.s16.h, horizontal: KorraSizes.s20.w) |
| divider Color(0xFFF0F0F0) | color | KorraColors.dividerSubtle |
| header fontSize: 18.sp | font size | KorraSizes.fontXl.sp |
| header FontWeight.w700 | weight | KorraSizes.weightBold |
| header Color(0xFF111111) | color | KorraColors.nearBlack |
| header letterSpacing: -0.5 | tracking | KorraSizes.trackingSnug |
| close btn EdgeInsets.all(8.r) | padding | KorraPaddings.all8 |
| close btn bg Color(0xFFF5F5F5) | color | KorraColors.greyShade100 |
| Iconsax.close_circle | icon | KorraIcons.closeCircle |
| close icon size: 20.sp | size | KorraSizes.iconMd.sp |
| Colors.black54 | color | KorraColors.black54 |
| list padding EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h) | inline | KorraPaddings.legalContent |
| SizedBox(height: 24.h) separator | gap | Gaps.h24 |
| _Section heading fontSize: 15.sp | font size | KorraSizes.fontMdPlus.sp |
| _Section heading FontWeight.w700 | weight | KorraSizes.weightBold |
| _Section heading Color(0xFF111111) | color | KorraColors.nearBlack |
| _Section SizedBox(height: 8.h) | gap | Gaps.h8 |
| _Section item EdgeInsets.only(bottom: 8.h) | inline | EdgeInsets.only(bottom: KorraSizes.s8.h) |
| _Section bullet Color(0xFF9CA3AF) | color | KorraColors.inputIconGrey |
| _Section body fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| _Section body height: 1.5 | line height | KorraSizes.lineHeightNormal |
| _Section body Color(0xFF4B5563) | color | KorraColors.textBodyCool |
| _Section body FontWeight.w400 | weight | KorraSizes.weightRegular |

---

### FILE 19 - legal/legal_pdf_screen.dart

| Location | Hardcoded value | Replacement |
|---|---|---|
| scaffold bg Colors.white | color | KorraColors.white |
| SizedBox(height: 16.h) | gap | Gaps.h16 |
| loading text Color(0xFF667085) | color | KorraColors.textMid |
| loading fontSize: 13.sp | font size | KorraSizes.fontSmPlus.sp |
| loading FontWeight.w500 | weight | KorraSizes.weightMedium |
| Iconsax.document_filter | icon | KorraIcons.documentFilter |
| error icon Colors.red.shade300 | color | KorraColors.errorIconLight |
| error icon size: 48.sp | size | KorraSizes.icon3xl.sp |
| error text fontSize: 14.sp | font size | KorraSizes.fontMd.sp |
| error text Color(0xFF344054) | color | KorraColors.textLabel |

---

## IMPORTS TO ADD PER FILE

For every file above add these imports if not already present and remove unused imports:

- If file uses Gaps: add import for gaps.dart (adjust relative path)
- If file uses KorraIcons replacing Iconsax: add import for icons.dart and REMOVE iconsax import if no Iconsax usages remain
- If file uses KorraStrings: add import for strings.dart
- If file uses KorraPaddings: add import for paddings.dart
- If file uses new KorraColors tokens: ensure colors.dart is imported

---

## AFTER ALL 19 FILES ARE DONE

1. Run: flutter analyze lib/presentation/auth/
2. Fix any import errors found
3. Commit: git commit -m "refactor(auth): replace all hardcoded values with design system tokens"
4. Push: git push origin clean-architecture
5. Report done and wait for next batch instruction