plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
}

android {
    namespace = "com.turkmax.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // google_navigation_flutter gereksinimi.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    androidResources {
        // Navigation SDK'nın tüm dil kaynaklarının pakete girmesini önler.
        localeFilters.addAll(listOf("tr", "en"))
    }

    defaultConfig {
        // Geçici kimlik; yayından önce benzersizliği ve sahipliği doğrulanacak.
        applicationId = "com.turkmax.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24 // Navigation SDK alt sınırı
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug anahtarıyla imzalanır: kendi telefonunda kullanım için yeterlidir ve API
            // anahtarı kısıtlamasındaki SHA-1 ile aynı sertifikadır. Derlemeyi başkalarıyla
            // paylaşacaksanız kendi imza yapılandırmanızı tanımlayın (bkz. docs/SETUP.md).
            signingConfig = signingConfigs.getByName("debug")
            // R8 küçültmesi Navigation SDK'nın yansıma ile oluşturduğu iç sınıfları bozuyor
            // (açılışta IllegalAccessException); paket bunun için kural yayımlamıyor.
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs_nio:2.1.5")
    // Sanal ekranda harita (OffscreenMapRenderer) için Navigation SDK'ya doğrudan erişim;
    // sürüm google_navigation_flutter ile aynı tutulmalıdır.
    implementation("com.google.android.libraries.navigation:navigation:8.0.0")
    testImplementation("junit:junit:4.13.2")
}

secrets {
    // Gerçek anahtar: android/secrets.properties (git dışı). Yoksa varsayılan dosya kullanılır.
    propertiesFileName = "secrets.properties"
    defaultPropertiesFileName = "local.defaults.properties"
    ignoreList.add("sdk.*")
    ignoreList.add("flutter.*")
}
