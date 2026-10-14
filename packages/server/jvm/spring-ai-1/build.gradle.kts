plugins { `java-library` }
dependencies {
    api(project(":core"))
    api("org.springframework.ai:spring-ai-openai:${providers.gradleProperty("springAi1Version").getOrElse("1.1.8")}")
}
