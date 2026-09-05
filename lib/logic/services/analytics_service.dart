// lib/logic/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../flavors/app_config.dart';

/// Central Firebase Analytics funnel for BOTH apps.
///
/// Design goals:
///  - ONE place that owns event names (see [AnalyticsEvents]) so we never ship
///    typo'd or duplicated names that fragment GA4 reports.
///  - Every event is auto-tagged with `role` (customer | merchant) and the
///    app also sets the `app_role` user property, so any custom event can be
///    segmented by who fired it — you can see which features customers lean on
///    versus merchants without renaming a thing.
///  - Role-specific actions ALSO carry a `customer_` / `merchant_` prefixed
///    name, so they read clearly in the raw events list.
///  - Fire-and-forget and fully guarded: analytics NEVER throws into a caller
///    and NEVER blocks a flow. Safe to call from blocs, repos, or widgets.
///  - No-ops nothing on web — analytics works there too — but wraps every call
///    so a failure is swallowed.
class Analytics {
  Analytics._();

  static FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  static String get _role => AppConfig.isVendor ? 'merchant' : 'customer';

  /// Observer wired into GetMaterialApp so every route change logs a
  /// `screen_view` automatically (this is what powers "which screens are used
  /// most"). Named lazily because AppConfig must be initialised first.
  static FirebaseAnalyticsObserver observer() =>
      FirebaseAnalyticsObserver(analytics: _fa);

  /// Call once in bootstrap after Firebase + AppConfig are ready.
  static Future<void> init() async {
    try {
      await _fa.setAnalyticsCollectionEnabled(!kDebugMode);
      await _fa.setUserProperty(name: 'app_role', value: _role);
      // Keep the analytics user id in sync with the signed-in account so
      // events segment per user and match the Crashlytics identifier.
      FirebaseAuth.instance.authStateChanges().listen((user) {
        setUser(user?.uid);
      });
    } catch (_) {
      // analytics setup must never break startup
    }
  }

  /// Ties events/crashes to the signed-in account; pass null on logout.
  static Future<void> setUser(String? uid) async {
    try {
      await _fa.setUserId(id: uid);
    } catch (_) {}
  }

  /// Core logger. [name] should come from [AnalyticsEvents]. `role` is always
  /// injected; extra params are cleaned to GA4-legal values.
  static void log(String name, [Map<String, Object?>? params]) {
    try {
      final clean = <String, Object>{'role': _role};
      if (params != null) {
        params.forEach((key, value) {
          if (value == null) return;
          // GA4 params accept num or String (<=100 chars).
          if (value is num) {
            clean[key] = value;
          } else {
            final s = value.toString();
            clean[key] = s.length > 100 ? s.substring(0, 100) : s;
          }
        });
      }
      _fa.logEvent(name: name, parameters: clean);
    } catch (_) {
      // swallow — a dropped analytics event must never surface
    }
  }

  /// Manual screen tag for surfaces that aren't full routes (bottom sheets,
  /// tab switches) so they show up alongside route-based screen_views.
  static void screen(String screenName) {
    try {
      _fa.logScreenView(screenName: screenName);
    } catch (_) {}
  }
}

/// The complete event-name catalog. snake_case, GA4-legal (<=40 chars),
/// grouped by domain. Role-specific events are prefixed customer_ / merchant_;
/// shared events (auth) rely on the injected `role` param.
class AnalyticsEvents {
  AnalyticsEvents._();

  // ---- Auth & onboarding (shared; role param distinguishes) ----
  static const login = 'login';
  static const loginFailed = 'login_failed';
  static const logout = 'logout';
  static const signupStarted = 'signup_started';
  static const signupSuccess = 'signup_success';
  static const signupFailed = 'signup_failed';
  static const kycStarted = 'kyc_started';
  static const kycSubmitted = 'kyc_submitted';
  static const kycApproved = 'kyc_approved';
  static const kycFailed = 'kyc_failed';

  // ---- Customer: discovery & storefront ----
  static const custHomeViewed = 'customer_home_viewed';
  static const custProductCodeEntered = 'customer_product_code_entered';
  static const custLinkPasted = 'customer_link_pasted';
  static const custStoreOpened = 'customer_store_opened';
  static const custStoreSearched = 'customer_store_searched';
  static const custProductViewed = 'customer_product_viewed';
  static const custProductShared = 'customer_product_shared';
  static const custLastViewedTapped = 'customer_last_viewed_tapped';
  static const custFeaturedTapped = 'customer_featured_tapped';
  static const custDealViewed = 'customer_deal_viewed';

  // ---- Customer: cart & checkout ----
  static const custAddToCart = 'customer_add_to_cart';
  static const custRemoveFromCart = 'customer_remove_from_cart';
  static const custCartViewed = 'customer_cart_viewed';
  static const custOutrightStarted = 'customer_outright_started';
  static const custOutrightSuccess = 'customer_outright_success';
  static const custOutrightFailed = 'customer_outright_failed';

  // ---- Customer: reservations / installment plans ----
  static const custReserveStarted = 'customer_reserve_started';
  static const custReserveSuccess = 'customer_reserve_success';
  static const custReserveFailed = 'customer_reserve_failed';
  static const custInstallmentPaid = 'customer_installment_paid';
  static const custInstallmentFailed = 'customer_installment_failed';
  static const custPlanViewed = 'customer_plan_viewed';

  // ---- Customer: wallet & money ----
  static const custWalletFundStarted = 'customer_wallet_fund_started';
  static const custWalletFundSuccess = 'customer_wallet_fund_success';
  static const custWalletFundFailed = 'customer_wallet_fund_failed';
  static const custStatementsViewed = 'customer_statements_viewed';
  static const custStoreCreditViewed = 'customer_store_credit_viewed';

  // ---- Customer: engagement ----
  static const custNotificationOpened = 'customer_notification_opened';
  static const custPurchaseHistoryViewed = 'customer_purchase_history_viewed';
  static const custVendorSaved = 'customer_vendor_saved';

  // ---- Merchant: catalog ----
  static const merchProductAdded = 'merchant_product_added';
  static const merchProductEdited = 'merchant_product_edited';
  static const merchProductDeleted = 'merchant_product_deleted';
  static const merchProductsViewed = 'merchant_products_viewed';

  // ---- Merchant: campaigns & marketing ----
  static const merchCampaignCreated = 'merchant_campaign_created';
  static const merchCampaignDeleted = 'merchant_campaign_deleted';
  static const merchCampaignAnalytics = 'merchant_campaign_analytics_viewed';
  static const merchCampaignHistoryViewed = 'merchant_campaign_history_viewed';
  static const merchWebActivityViewed = 'merchant_web_activity_viewed';

  // ---- Merchant: orders & fulfilment ----
  static const merchOrderViewed = 'merchant_order_viewed';
  static const merchOrderDelivered = 'merchant_order_delivered';
  static const merchReservationViewed = 'merchant_reservation_viewed';
  static const merchReservationFulfilled = 'merchant_reservation_fulfilled';

  // ---- Merchant: money ----
  static const merchPayoutRequested = 'merchant_payout_requested';
  static const merchPayoutSuccess = 'merchant_payout_success';
  static const merchPayoutFailed = 'merchant_payout_failed';
  static const merchSettlementViewed = 'merchant_settlement_viewed';
  static const merchStoreBalanceViewed = 'merchant_store_balance_viewed';

  // ---- Merchant: store setup ----
  static const merchStorefrontSettings = 'merchant_storefront_settings_saved';
  static const merchNotificationOpened = 'merchant_notification_opened';
}
