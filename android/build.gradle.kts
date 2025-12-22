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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    if (project.name == "flutter_media_metadata") {
        project.afterEvaluate {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                namespace = "com.alexmercerind.flutter_media_metadata"
                compileSdk = 36
            }
        }
    }
    if (project.name == "isar_flutter_libs") {
        project.afterEvaluate {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                namespace = "dev.isar.isar_flutter_libs"
            }
        }
    }
    if (project.name == "on_audio_query_android") {
        project.afterEvaluate {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                namespace = "com.lucasjosino.on_audio_query"
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
            // Fix JVM target compatibility for Kotlin
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
    if (project.name == "flutter_image_compress_common") {
        project.afterEvaluate {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
}
