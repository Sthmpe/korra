enum AppEnvironment { dev, prod }

class EnvConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  // Supabase URLs
  static String get supabaseUrl => environment == AppEnvironment.prod
      ? "https://korra-prod-reference.supabase.co/functions/v1" // Replace with your PROD ID
      : "https://ltytmqjpektcgwajfzfm.supabase.co/functions/v1"; // Your current DEV ID

  // Add other environment-specific keys here later (like Monnify Public Keys)
  static bool get isLive => environment == AppEnvironment.prod;
}