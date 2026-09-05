import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Handles incoming Android App Links / iOS Universal Links.
///
/// Canonical store link is `https://korra.com.ng/store/{slug}` — when the OS
/// opens the customer app from such a link we route straight to the storefront.
/// Bare `/store` (no slug) has no app destination, so it's ignored (the website
/// sends those to the landing page). Only the CUSTOMER app registers these.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// Call once, after the first frame (the navigator must exist before we can
  /// route). Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // 1. Cold start — the link that launched the app.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      debugPrint("DeepLinkService: initial link error: $e");
    }

    // 2. Warm links — app already running.
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint("DeepLinkService: stream error: $e"),
    );
  }

  void dispose() {
    _sub?.cancel();
    _started = false;
  }

  void _handleUri(Uri uri) {
    // Accept korra.com.ng and the app subdomain; ignore anything else.
    final host = uri.host.toLowerCase();
    const allowedHosts = {'korra.com.ng', 'www.korra.com.ng', 'app.korra.com.ng'};
    if (!allowedHosts.contains(host)) return;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // Expect /store/{slug}, optionally ?product={id} (open that product) and
    // ?action=installment|outright (carried through for the app to act on).
    // Also accepts the website's shareable product page /store/{slug}/p/{id}.
    if (segments.length >= 2 && segments[0].toLowerCase() == 'store') {
      final slug = segments[1];
      if (slug.isNotEmpty) {
        final pathProduct = (segments.length >= 4 && segments[2].toLowerCase() == 'p')
            ? segments[3]
            : null;
        final product = pathProduct ?? uri.queryParameters['product'];
        final action = uri.queryParameters['action'];
        final query = <String, String>{
          if (product != null && product.isNotEmpty) 'product': product,
          if (action != null && action.isNotEmpty) 'action': action,
        };
        // Named GetX route — mirrors how the app opens storefronts internally.
        Get.toNamed('/store/$slug', parameters: query.isEmpty ? null : query);
      }
    }
  }
}
