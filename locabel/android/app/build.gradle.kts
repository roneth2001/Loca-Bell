plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = org.jetbrains.kotlin.konan.properties.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
if (flutterVersionCode == null) {
    localProperties["flutter.versionCode"] = "1"
}

val flutterVersionName = localProperties.getProperty("flutter.versionName")
if (flutterVersionName == null) {
    localProperties["flutter.versionName"] = "1.0"
}

android {
    namespace = "com.rhr.locabell"
    compileSdk = 36  // CHANGED from 34 to 36
    
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.rhr.locabell"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = (localProperties.getProperty("flutter.versionCode") ?: "1").toInt()
        versionName = localProperties.getProperty("flutter.versionName") ?: "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}