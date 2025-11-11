import java.util.Properties

/* ───────── plugins ───────── */
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
}

/* ───────── load external properties ───────── */
val keystoreProps = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val localProps = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val flutterVersionCode   = (localProps["flutter.versionCode"] ?: "1").toString().toInt()
val flutterVersionName   =  localProps["flutter.versionName"] ?: "1.0"

/* ───────── android block ───────── */
android {
    namespace = "com.hfg.hash"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    lint {
        disable.add("PackagedPrivateKey")
        checkReleaseBuilds = false
        abortOnError = false
    }
    defaultConfig {
        applicationId = "com.hfg.hash"
        minSdk = 23                                   // bumped for Firebase Auth
        targetSdk = 35
        versionCode = 25
        versionName = flutterVersionName.toString()
    }

    /* signing (release) */
    signingConfigs {
        create("release") {
            if (keystoreProps.isNotEmpty()) {
                storeFile     = file(keystoreProps["storeFile"] ?: "")
                storePassword = keystoreProps["storePassword"] as String? ?: ""
                keyAlias      = keystoreProps["keyAlias"] as String? ?: ""
                keyPassword   = keystoreProps["keyPassword"] as String? ?: ""
            }
        }
    }

    /* build types */
    buildTypes {
        getByName("debug")  { isDebuggable = true }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    /* flavours */
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "HFG Dev")
            buildConfigField("String", "API_BASE_URL", "\"https://dev-api.hfg.com\"")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "HFG")
            buildConfigField("String", "API_BASE_URL", "\"https://api.hfg.com\"")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true          // desugaring ON
    }
    kotlinOptions { jvmTarget = "11" }

    buildFeatures { buildConfig = true }
}

/* ───────── dependencies ───────── */
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.guardsquare:proguard-annotations:7.4.1")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    // add other libs below …
    // Needed for Theme.Material3.*
    implementation("com.google.android.material:material:1.12.0")
// Needed for Theme.SplashScreen + windowSplashScreen* attrs (Android 12 compat)
    implementation("androidx.core:core-splashscreen:1.0.1")
}

/* ───────── flutter source ───────── */
flutter { source = "../.." }
