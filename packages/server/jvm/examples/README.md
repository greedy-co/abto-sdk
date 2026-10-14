# Independent JVM consumers

These Maven and Gradle projects resolve published Maven coordinates only. They never add SDK source directories or composite builds. Each default run starts and closes an ephemeral loopback Chat Completions fixture; no credentials are needed.

From this directory, after installing Maven 3.9.11, Gradle 9.3.0 and Java 17:

```sh
mvn -B -ntp verify
gradle -p gradle run --no-daemon -Pkotlin.compiler.execution.strategy=in-process
```

To verify locally staged JARs before publication, build from the SDK directory and pass its absolute `file:` repository URL:

```sh
gradle -p .. build publishAllPublicationsToCentralBundleRepository --no-daemon
mvn -B -ntp verify -Dabto.repository="file:$(cd ../build/central-staging && pwd)"
gradle -p gradle run --no-daemon -Pkotlin.compiler.execution.strategy=in-process \
  -PabtoRepository="file:$(cd ../build/central-staging && pwd)"
```

`abto.version` (Maven) / `abtoVersion` (Gradle) overrides the SDK version. `openai.version` (Maven) / `openaiVersion` (Gradle) selects the official OpenAI runtime. CI consumes the same SDK built against OpenAI 4.49.0 with both 4.49.0 and 4.81.0. `springBoot1Version` and `springBoot2Version` select the Boot matrix. `javaVersion` selects the Gradle runtime toolchain; Maven uses the active JDK. CI checks Java 17/21/25 and both documented Boot combinations.

For a real Gateway call, set server-side `ABTO_API_KEY`, `ABTO_GATEWAY_BASE_URL` and provider key variables, then run a selected Maven example without the fixture:

```sh
mvn -B -ntp -pl java verify -Dexample.arguments=live
```

The example verifies HTTP completion only. Check the corresponding `support.reply`, `support.config`, `support.http` feature records in Dashboard separately. Do not use production customer keys for automated smoke tests.

Java and Kotlin examples cover factory/config and pure HTTP; Kotlin also demonstrates coroutine cancellation binding. Spring examples start real Boot application contexts. LangChain4j also invokes a LangGraph4j graph. The local fixture is test support, not a Gateway emulator for routing or pricing policies.
