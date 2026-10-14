plugins { kotlin("jvm") version "2.3.21" apply false }

subprojects {
    apply(plugin = "application")
    repositories {
        maven { url = uri(providers.gradleProperty("abtoRepository").getOrElse("https://repo.maven.apache.org/maven2")) }
        mavenCentral()
    }
    val artifact = if (name == "java" || name == "kotlin") "abto-calling" else "abto-calling-$name"
    dependencies { "implementation"("app.abto:$artifact:${providers.gradleProperty("abtoVersion").getOrElse("1.1.0")}") }
    dependencies {
        constraints {
            for (module in listOf("openai-java", "openai-java-core", "openai-java-client-okhttp")) {
                "implementation"("com.openai:$module:${providers.gradleProperty("openaiVersion").getOrElse("4.49.0")}")
            }
        }
    }
    extensions.configure<JavaPluginExtension> { toolchain.languageVersion.set(JavaLanguageVersion.of(providers.gradleProperty("javaVersion").getOrElse("17"))) }
    extensions.configure<SourceSetContainer> { named("main") { java.srcDir("../support/src/main/java") } }
    tasks.withType<JavaCompile>().configureEach { options.release.set(17) }
    val main = when (name) {
        "java" -> "example.JavaExample"
        "kotlin" -> "example.KotlinExampleKt"
        "spring-ai-1" -> "example.SpringAI1Example"
        "spring-ai-2" -> "example.SpringAI2Example"
        else -> "example.LangChainExample"
    }
    extensions.configure<JavaApplication> { mainClass.set(main) }
    tasks.named<JavaExec>("run") { args("--self-test") }
    if (name != "java") {
        apply(plugin = "org.jetbrains.kotlin.jvm")
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension> {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
        dependencies { "implementation"("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2") }
    }
    if (name.startsWith("spring-ai-")) {
        val boot = if (name.endsWith("1")) providers.gradleProperty("springBoot1Version").getOrElse("3.5.16") else providers.gradleProperty("springBoot2Version").getOrElse("4.1.1")
        dependencies {
            "implementation"(platform("org.springframework.boot:spring-boot-dependencies:$boot"))
            "implementation"("org.springframework.boot:spring-boot-starter")
        }
    }
    if (name == "langchain4j") dependencies { "implementation"("org.bsc.langgraph4j:langgraph4j-core:1.9.5") }
}
