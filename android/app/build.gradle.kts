plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.korra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion =  "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.korra"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk =  23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase Bill of Materials (BOM)
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))

     // --- Core / analytics ---
    implementation("com.google.firebase:firebase-analytics")

    // --- Authentication (already had) ---
    implementation("com.google.firebase:firebase-auth")

    // --- Firestore (database) ---
    implementation("com.google.firebase:firebase-firestore")

    // --- Storage ---
    implementation("com.google.firebase:firebase-storage")

    // --- App Check ---
    implementation("com.google.firebase:firebase-appcheck")

    // --- AI/ML (Firebase AI Logic) ---
    implementation("com.google.firebase:firebase-ai")

    // --- (Optional) Add more if needed: ML Kit, Crashlytics, etc. ---
    // implementation("com.google.firebase:firebase-crashlytics")
    // implementation("com.google.firebase:firebase-functions")
}
