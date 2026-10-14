plugins { `java-library` }
dependencies {
    api(project(":calling"))
    api("org.springframework.ai:spring-ai-openai:${providers.gradleProperty("springAi2Version").getOrElse("2.0.1")}")
    testImplementation(platform("org.springframework.boot:spring-boot-dependencies:4.1.1"))
    testImplementation("io.micrometer:micrometer-tracing-bridge-otel")
    testImplementation("io.opentelemetry:opentelemetry-exporter-otlp")
}
