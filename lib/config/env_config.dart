enum AppEnvironment { dev, prod }

class EnvConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  // Supabase URLs
  static String get supabaseUrl => environment == AppEnvironment.prod
      ? "https://korra-prod-reference.supabase.co/functions/v1" 
      : "https://ltytmqjpektcgwajfzfm.supabase.co/functions/v1";

  
  static bool get isLive => environment == AppEnvironment.prod;
}
