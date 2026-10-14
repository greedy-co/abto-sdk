# Java and Kotlin Calling

Read the current [Java/Kotlin guide](https://docs.abto.app/sdk/jvm/) and verify the installed Maven coordinates before editing. Java and Kotlin share a server Calling SDK; the Android Event SDK has a different responsibility and credential.

## Select the existing calling path

- Official OpenAI Java: use `AbtoOpenAI.openai()` for construction or `existingClient.withOptions(scope.openaiOptions(safeJdkTransport))` for configuration. Both use the same Gateway policy.
- Spring AI 1.1: apply `openAiApiOptions` to the API builder and `chatModelOptions` to the existing model builder. Preserve RestClient interceptors, ObservationRegistry, tools, and retry settings.
- Spring AI 2.0: apply `chatModelOptions()` to inject the configured official clients while retaining the existing model builder.
- LangChain4j: apply `openAiOptions()` to its existing OpenAiChatModel builder. Keep listeners, tool settings, model options, and retry policy.
- LangGraph4j: call that LangChain4j model from the existing graph node; retain graph state and checkpoints.
- Plain HTTP: wrap an explicitly safe JDK client with `AbtoHttpClient` and use a replayable body if fallback is enabled.

Do not install multiple adapters for the same call. Read the current tested versions in Docs instead of assuming an entire framework version range is supported. Inventory streaming, Responses, embeddings, and other incompatible calls without migrating them. Keep embeddings for RAG on their existing client.

## Transport, context, and ownership

The official config path requires an explicit `java.net.http.HttpClient`. Confirm `Redirect.NEVER` and no CookieHandler or Authenticator. The SDK keeps this JDK client's pool, proxy, TLS, and executor; it replaces the official client's hidden HTTP transport. Do not silently discard existing OkHttp interceptors or request-factory-specific settings. Report settings that need to be moved to the explicit transport, and use the installed SDK's documented timeout constraints.

Keep one root facade for the application lifecycle. Build immutable request scopes with `forContext(AbtoContext)` and carry them explicitly across async, coroutine, and graph boundaries. Forward the established device identifier; do not invent a second identity. `withContext` is synchronous convenience, not ThreadLocal propagation across arbitrary async work.

For official asynchronous calls, attach a fresh `AbtoCancellation` to the scope and `bind` the returned Future before awaiting it. Cancelling the original official Future alone does not cancel the underlying HTTP request. Close SDK-owned resources at application shutdown and leave borrowed resources under customer ownership.

## Fallback and observation

Follow the endpoint discovery and confirmation procedure in [Server](server.md#preserve-and-disclose-direct-fallback). A JVM proposal uses `AbtoFallback.builder().baseUrl(existingEndpoint)`. Do not enable timeout replay or alter native retry settings while adding ABTO.

Retain Micrometer/OpenTelemetry, LangChain4j listeners, and existing Langfuse exporters. Add no global exporter or replacement trace identity. Preserve `traceparent` and `tracestate`. Authentication is injected at dispatch; do not expose keys through logs or tracing header capture.

Customer-side traced input may differ from the request after Gateway policy. Use Gateway execution records for the final model, prompt, and cost. Verify local trace linkage separately from receipt in the customer's Langfuse account. Report Gateway-served and direct fallback calls separately; direct calls have no ABTO execution record or request identifier.
