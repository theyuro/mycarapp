import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.gilesdesenvolvimento.mycarapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gilesdesenvolvimento.mycarapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ADMOB_APP_ID"] =
            (project.findProperty("ADMOB_APP_ID") as String?)
                ?: System.getenv("ADMOB_APP_ID")
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // O Flutter Gradle Plugin já ativa o R8 no release; explícito aqui para
            // deixar claro que as regras abaixo são aplicadas.
            isMinifyEnabled = true
            // Remove recursos não usados do pacote (reduz o tamanho de
            // download na Play); só vale com o R8 ativo, como acima.
            isShrinkResources = true
            // Inclui a tabela de símbolos nativos no bundle: a Play deixa de
            // avisar sobre símbolos ausentes e os crashes nativos (ex.: ML Kit)
            // ficam legíveis no Android vitals.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
    // Força a versão do WorkManager, que chega transitivamente como 2.7.0 via
    // google_mobile_ads (play-services-ads-api). Versões novas trazem Room e
    // regras de consumer ProGuard atualizadas, compatíveis com o R8 do AGP 9.
    implementation("androidx.work:work-runtime:2.10.1")
}
