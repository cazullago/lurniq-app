plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

// Release signing for Google Play. The upload keystore is NEVER committed.
// Two supported inputs (checked in this order):
//   1. android/keystore.properties (local file, git-ignored) with
//      storeFile, storePassword, keyAlias, keyPassword
//   2. Environment variables (used by GitHub Actions secrets):
//      LURNIQ_KEYSTORE_PATH, LURNIQ_STORE_PASSWORD, LURNIQ_KEY_ALIAS,
//      LURNIQ_KEY_PASSWORD
// Without either, release builds fall back to debug signing — fine for the
// debug APK / test AAB, NOT for Play Store upload. See PLAY_RELEASE_CHECKLIST.md.
val keystorePropsFile = rootProject.file("keystore.properties")
val keystoreProps = Properties()
if (keystorePropsFile.exists()) {
    keystoreProps.load(FileInputStream(keystorePropsFile))
}
val envKeystorePath = System.getenv("LURNIQ_KEYSTORE_PATH")
val hasReleaseKeystore =
    keystorePropsFile.exists() || (envKeystorePath != null && file(envKeystorePath).exists())

android {
    namespace = "com.lurniq.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (keystorePropsFile.exists()) {
                storeFile = file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            } else if (envKeystorePath != null) {
                storeFile = file(envKeystorePath)
                storePassword = System.getenv("LURNIQ_STORE_PASSWORD")
                keyAlias = System.getenv("LURNIQ_KEY_ALIAS")
                keyPassword = System.getenv("LURNIQ_KEY_PASSWORD")
            }
        }
    }

    defaultConfig {
        applicationId = "com.lurniq.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Debug-signed test build. Do NOT upload this to Google Play.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
