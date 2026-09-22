allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Some plugins (e.g. flutter_native_splash 2.4.4) ship an Android module built against an
    // older compileSdk (31) than transitive androidx deps now require (34+), which fails the AGP
    // AAR metadata check. Force every subproject's compileSdk to match the app's so the check
    // passes, without touching the pinned package version (see pubspec.yaml for why it's pinned).
    // Must be registered before evaluationDependsOn below forces this project to evaluate.
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { android ->
            if (android.compileSdkVersion != "android-36") {
                android.compileSdkVersion(36)
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
