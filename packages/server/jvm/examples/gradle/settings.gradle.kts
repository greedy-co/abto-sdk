pluginManagement { repositories { gradlePluginPortal(); mavenCentral() } }
rootProject.name = "abto-calling-consumers"
listOf("java", "kotlin", "spring-ai-1", "spring-ai-2", "langchain4j").forEach {
    include(it)
    project(":$it").projectDir = file("../$it")
}
