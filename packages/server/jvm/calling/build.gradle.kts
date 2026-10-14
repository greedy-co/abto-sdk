plugins { `java-library` }
dependencies {
    api(project(":core"))
    api("com.openai:openai-java:${providers.gradleProperty("openaiVersion").getOrElse("4.49.0")}")
}
