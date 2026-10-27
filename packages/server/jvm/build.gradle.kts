import org.gradle.api.publish.maven.MavenPublication
import org.gradle.plugins.signing.Sign
import org.gradle.plugins.signing.SigningExtension

plugins { base }

subprojects {
    apply(plugin = "java-library")
    apply(plugin = "maven-publish")
    apply(plugin = "signing")
    group = providers.gradleProperty("GROUP").get()
    version = providers.gradleProperty("VERSION_NAME").get()
    repositories { mavenCentral() }
    extensions.configure<JavaPluginExtension> {
        toolchain.languageVersion.set(JavaLanguageVersion.of(providers.gradleProperty("javaVersion").getOrElse("17")))
        withSourcesJar()
        withJavadocJar()
    }
    tasks.withType<JavaCompile>().configureEach { options.release.set(17); options.encoding = "UTF-8" }
    tasks.withType<Javadoc>().configureEach {
        options.encoding = "UTF-8"
        (options as StandardJavadocDocletOptions).addBooleanOption("Xdoclint:all,-missing", true)
    }
    dependencies {
        "testImplementation"(platform("org.junit:junit-bom:5.14.1"))
        "testImplementation"("org.junit.jupiter:junit-jupiter")
        "testRuntimeOnly"("org.junit.platform:junit-platform-launcher")
    }
    tasks.withType<Test>().configureEach { useJUnitPlatform() }
    val artifact = if (name == "calling") "abto-calling" else "abto-calling-$name"
    base.archivesName.set(artifact)
    extensions.configure<PublishingExtension> {
        publications.create<MavenPublication>("maven") {
            from(components["java"])
            artifactId = artifact
            pom {
                name.set(artifact)
                description.set("ABTO Gateway integration for Java and Kotlin.")
                url.set("https://github.com/greedy-co/abto-sdk")
                licenses { license { name.set("The MIT License"); url.set("https://opensource.org/license/mit"); distribution.set("repo") } }
                developers { developer { id.set("greedy-co"); name.set("Greedy"); email.set("contact@abto.app") } }
                scm {
                    connection.set("scm:git:https://github.com/greedy-co/abto-sdk.git")
                    developerConnection.set("scm:git:ssh://git@github.com/greedy-co/abto-sdk.git")
                    url.set("https://github.com/greedy-co/abto-sdk")
                    tag.set("calling-jvm-v${project.version}")
                }
            }
        }
        repositories { maven { name = "centralBundle"; url = uri(rootProject.layout.buildDirectory.dir("central-staging")) } }
    }
    val signingKey = providers.environmentVariable("GPG_PRIVATE_KEY").orNull
    val passphrase = providers.environmentVariable("GPG_PASSPHRASE").orNull
    extensions.configure<SigningExtension> {
        if (!signingKey.isNullOrBlank()) useInMemoryPgpKeys(signingKey, passphrase)
        sign(extensions.getByType<PublishingExtension>().publications)
    }
    tasks.withType<Sign>().configureEach { enabled = !signingKey.isNullOrBlank() }
    tasks.withType<Jar>().configureEach {
        isPreserveFileTimestamps = false
        isReproducibleFileOrder = true
        from(rootProject.file("LICENSE")) { into("META-INF") }
    }
}
