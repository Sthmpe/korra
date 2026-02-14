enum AppFlavor { customer, vendor }

class AppConfig {
  static AppFlavor? _flavor;
  
  static AppFlavor get flavor {
    if (_flavor == null) {
      throw Exception("AppConfig not initialized! Call init() in main.");
    }
    return _flavor!;
  }

  static String get appName {
    return _flavor == AppFlavor.vendor ? "Korra Biz" : "Korra";
  }

  static bool get isVendor => _flavor == AppFlavor.vendor;

  static void init(AppFlavor flavor) {
    _flavor = flavor;
  }
}