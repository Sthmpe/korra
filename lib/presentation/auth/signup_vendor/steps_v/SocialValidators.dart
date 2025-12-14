class SocialValidators {
  // 1. Instagram: matches https://instagram.com/username
  static String? instagram(String? value) {
    if (value == null || value.isEmpty) return null; // Allow empty if optional
    
    // Pattern: https://(www.)instagram.com/username
    final regex = RegExp(r'^(https?:\/\/)?(www\.)?instagram\.com\/[A-Za-z0-9_.]+\/?$');
    
    if (!regex.hasMatch(value)) {
      return "Enter a valid Instagram URL (e.g., instagram.com/korra)";
    }
    return null;
  }

  // 2. Twitter/X: matches https://x.com/username or twitter.com
  static String? twitter(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final regex = RegExp(r'^(https?:\/\/)?(www\.)?(twitter|x)\.com\/[A-Za-z0-9_]+\/?$');
    
    if (!regex.hasMatch(value)) {
      return "Enter a valid X/Twitter URL";
    }
    return null;
  }

  // 3. Facebook: matches profile or page links
  static String? facebook(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final regex = RegExp(r'^(https?:\/\/)?(www\.)?(facebook|fb)\.com\/[A-Za-z0-9_.]+\/?$');
    
    if (!regex.hasMatch(value)) {
      return "Enter a valid Facebook Page URL";
    }
    return null;
  }

  // 4. TikTok: matches tiktok.com/@username
  static String? tiktok(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final regex = RegExp(r'^(https?:\/\/)?(www\.)?tiktok\.com\/@[A-Za-z0-9_.]+\/?$');
    
    if (!regex.hasMatch(value)) {
      return "Enter a valid TikTok URL (must include @)";
    }
    return null;
  }

  // 5. WhatsApp: matches wa.me/1234567890
  static String? whatsapp(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Matches https://wa.me/2348012345678
    final regex = RegExp(r'^(https?:\/\/)?(wa\.me|api\.whatsapp\.com\/send\?phone=)\/\d+$');
    
    if (!regex.hasMatch(value)) {
      return "Use format: wa.me/234...";
    }
    return null;
  }
  
  // 6. Generic Website (Any valid URL)
  static String? website(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Checks for http/https and a dot in the domain
    final regex = RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');
    
    if (!regex.hasMatch(value)) {
      return "Enter a valid website URL (e.g. https://korra.ng)";
    }
    return null;
  }

  // 7. Other (Any valid URL)
  static String? other(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Checks for http/https and a dot in the domain
    final regex = RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');
    
    if (!regex.hasMatch(value)) {
      return "Enter a valid URL (e.g. https://korra.ng)";
    }
    return null;
  }
}