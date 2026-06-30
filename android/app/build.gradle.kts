import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- 🚀 KORRA ENVIRONMENT CONFIG SWITCHER (Kotlin DSL) ---
var isLive = false
if (project.hasProperty("dart-defines")) {
    val dartDefines = project.property("dart-defines") as String
    // "IS_LIVE=true" encoded in Base64 is exactly "SVNfTElWRT10cnVl"
    if (dartDefines.contains("SVNfTElWRT10cnVl")) {
        isLive = true
    }
}

val targetJson = if (isLive) "google-services-prod.json" else "google-services-dev.json"
println("🚀 KORRA BUILD: Instantly copying $targetJson to google-services.json")

copy {
    from(targetJson)
    into(project.projectDir)
    rename { "google-services.json" }
}
// ---------------------------------------------------------

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.korra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ❌ REMOVED: applicationId = "com.example.korra" (Moved to flavors)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

   flavorDimensions += "app_type"

    // Create a dynamic suffix based on your existing 'isLive' variable
    val appSuffix = if (isLive) ".live" else ""

    productFlavors {
        // 🛍️ Customer App
        create("customer") {
            dimension = "app_type"
            // Becomes "com.korra.shop" in dev, and "com.korra.shop.live" in live
            applicationId = "com.korra.shop$appSuffix"
            resValue("string", "app_name", "Korra")
            manifestPlaceholders["appLinkHost"] = "app.korra.com.ng"
        }

        // 🏢 Merchant App
        create("merchant") {
            dimension = "app_type"
            // Becomes "com.korra.business" in dev, and "com.korra.business.live" in live
            applicationId = "com.korra.business$appSuffix"
            resValue("string", "app_name", "Korra Biz")
            manifestPlaceholders["appLinkHost"] = "business.korra.com.ng"
        }
    }

    // 🔐 SECURE SIGNING CONFIGURATION
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            val storeFilePath = keystoreProperties["storeFile"] as String?
            storeFile = if (storeFilePath != null) file(storeFilePath) else null
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("debug") {
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }

        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}


flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-appcheck")
    implementation("com.google.firebase:firebase-ai")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
}
