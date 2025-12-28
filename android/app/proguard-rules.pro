# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter splash screen resources
-keep class io.flutter.embedding.android.SplashScreen*
-keep class io.flutter.embedding.android.FlutterActivity*

# Firebase (Critical for Auth/Firestore)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Supabase / Deep Links
-keep class io.supabase.** { *; }

# WebView (If you use it for Monnify/Payment)
-keep class android.webkit.** { *; }

# Models (If you map JSON to Java objects in native code - unlikely in pure Flutter but safe to keep)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Prevent Obfuscation of Flutter's Entry Point
-keep class com.example.korra.MainActivity { *; }