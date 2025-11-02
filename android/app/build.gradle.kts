plugins {
    id("com.android.application")
    id("kotlin-android")
    // ต้องอยู่หลัง Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fiberflowv3_fixed"   // <<< ใช้ชื่อเดียวกับ MainActivity
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.fiberflowv3_fixed"   // <<< ให้ตรง namespace
        minSdk = flutter.minSdkVersion        // ถ้าใช้งานสแกน/permission บางตัว แนะนำ 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
