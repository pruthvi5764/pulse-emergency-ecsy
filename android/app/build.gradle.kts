import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.lifelinenexus.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ─── Release Signing Config ────────────────────────────────────────────────
    // Reads from key.properties (gitignored) or CI/CD environment variables.
    // To generate a keystore: keytool -genkey -v -keystore lifeline.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lifeline
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
                storeFile = file(keystoreProperties.getProperty("storeFile") ?: "lifeline.jks")
                storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            } else {
                // CI/CD fallback: inject via environment variables
                keyAlias = System.getenv("KEY_ALIAS") ?: ""
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
                storeFile = file(System.getenv("STORE_FILE") ?: "lifeline.jks")
                storePassword = System.getenv("STORE_PASSWORD") ?: ""
            }
        }
    }

    defaultConfig {
        applicationId = "com.lifelinenexus.app"
        // FIXED: minSdk must be 23+ for Firebase App Check PlayIntegrity (T-76)
        // flutter.minSdkVersion resolves to 21 which is insufficient.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Required when total method count exceeds 64K (Firebase + Maps + AI)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // FIXED: Use real release signing — debug keys are rejected by Play Store (T-89)
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM — manages all Firebase library versions consistently
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-analytics")
    // MultiDex support for method count > 64K
    implementation("androidx.multidex:multidex:2.0.1")
}
