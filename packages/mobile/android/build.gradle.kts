import org.gradle.api.publish.maven.MavenPublication
import org.gradle.api.tasks.JavaExec
import org.gradle.jvm.tasks.Jar
import org.gradle.plugins.signing.Sign
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    kotlin("jvm") version "2.3.21"
    `java-library`
    `maven-publish`
    signing
}

group = providers.gradleProperty("GROUP").get()
version = providers.gradleProperty("VERSION_NAME").get()

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain(17)
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_1_8)
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
    withSourcesJar()
}

val javadocJar by tasks.registering(Jar::class) {
    archiveClassifier.set("javadoc")
    // The SDK is Kotlin-only. Central requires a javadoc-classified artifact;
    // API documentation generation can be added without changing coordinates.
}

val checks by sourceSets.creating {
    kotlin.srcDir("src/checks/kotlin")
    compileClasspath += sourceSets.main.get().output
    runtimeClasspath += output + compileClasspath
}

configurations[checks.implementationConfigurationName]
    .extendsFrom(configurations.implementation.get())
configurations[checks.runtimeOnlyConfigurationName]
    .extendsFrom(configurations.runtimeOnly.get())

tasks.register<JavaExec>("sdkChecks") {
    group = "verification"
    description = "Runs the framework-free ABTO SDK checks."
    dependsOn(checks.classesTaskName)
    classpath = checks.runtimeClasspath
    mainClass.set("AbtoSdkChecksKt")
}

tasks.named("check") {
    dependsOn("sdkChecks")
}

val mavenPublication = publishing.publications.create<MavenPublication>("maven") {
    from(components["java"])
    artifact(javadocJar)
    artifactId = "abto-app"

    pom {
        name.set("ABTO SDK for Android and Kotlin/JVM")
        description.set("ABTO analytics SDK for user behavior and LLM cost, latency, and quality attribution.")
        url.set("https://github.com/greedy-co/abto-sdk")

        licenses {
            license {
                name.set("The MIT License")
                url.set("https://opensource.org/license/mit")
                distribution.set("repo")
            }
        }
        developers {
            developer {
                id.set("greedy-co")
                name.set("Greedy")
                email.set("contact@abto.app")
            }
        }
        scm {
            connection.set("scm:git:git://github.com/greedy-co/abto-sdk.git")
            developerConnection.set("scm:git:ssh://github.com/greedy-co/abto-sdk.git")
            url.set("https://github.com/greedy-co/abto-sdk")
        }
    }
}

publishing {
    repositories {
        maven {
            name = "centralBundle"
            url = uri(layout.buildDirectory.get().dir("central-staging"))
        }
    }
}

val signingPrivateKey = providers.environmentVariable("GPG_PRIVATE_KEY").orNull
val signingPassphrase = providers.environmentVariable("GPG_PASSPHRASE").orNull
val signingEnabled = !signingPrivateKey.isNullOrBlank() && !signingPassphrase.isNullOrBlank()

signing {
    if (signingEnabled) {
        useInMemoryPgpKeys(signingPrivateKey, signingPassphrase)
    }
    sign(mavenPublication)
}

tasks.withType<Sign>().configureEach {
    enabled = signingEnabled
}
