import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('promptKorraInstall')
external void _promptKorraInstall();

@JS('isKorraInstalled')
external bool _isKorraInstalled();

bool isPwaInstalled() {
  return _isKorraInstalled();
}

void triggerInstallPrompt() {
  _promptKorraInstall();
}

bool isIosBrowser() {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
}

// ✅ Check if it's strictly Safari
bool isIosSafari() {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return isIosBrowser() && !ua.contains('crios') && !ua.contains('fxios');
}

// ✅ Check if it's Chrome/Edge/Firefox on iOS
bool isIosNonSafari() {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return isIosBrowser() && (ua.contains('crios') || ua.contains('fxios'));
}