plugins { `java-library` }
dependencies {
    api(project(":core"))
    api("dev.langchain4j:langchain4j-open-ai:${providers.gradleProperty("langchain4jVersion").getOrElse("1.22.0")}")
    api("dev.langchain4j:langchain4j-http-client-jdk:${providers.gradleProperty("langchain4jVersion").getOrElse("1.22.0")}")
    testImplementation("org.bsc.langgraph4j:langgraph4j-core:1.9.5")
}
