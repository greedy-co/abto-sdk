# Tracing coexistence regression

Run from the repository root with Node 24:

```sh
pnpm --filter @abto-app/calling build
pnpm --filter @abto-app/calling test:tracing
```

The runner packs the current SDK and installs it into two isolated, lockfile-pinned consumers.
The legacy fixture uses LangChain OpenAI 0.2.7/core 0.2.36, OpenAI 4.56.0, Langfuse 3.39.2 and LangSmith.
The modern fixture uses LangChain OpenAI 1.5.13/core 1.2.11, Langfuse 5.11.1, LangSmith and OpenTelemetry.
These are test dependencies, not published SDK runtime dependencies.

Each probe starts one ephemeral loopback HTTP server with synthetic credentials and data.
It clears vendor environment settings before loading tracing libraries and restricts fetch to that server's origin.
Provider responses, Gateway availability and telemetry ingestion responses are mocked.
LangChain chains/parsers/callbacks, Langfuse handlers, LangSmith serialization and HTTP export, and modern OTel processors are real.
There is no provider charge, external tracing account, database or browser session.
This suite does not run the actual ABTO Gateway; use the separate repository E2E for routing and database persistence.

Assertions cover:

- Direct baseline and ABTO concurrent calls with customer callbacks, metadata/tags, AsyncLocalStorage and trace headers.
- Langfuse and LangSmith attached to the same six LLM invocations, including one provider error and one safe fallback.
- Correct Gateway Calling Key and direct-provider authentication after replacing serializable apiKey with a placeholder.
- No Calling Key or provider key in model serialization, callback model metadata, actual LangSmith HTTP payloads, legacy Langfuse HTTP payloads or modern Langfuse spans.
- Request-scoped legacy handlers with six separate generation traces; modern shared handler with active OTel roots and a separate processor.
- Actual response model recorded by modern Langfuse; legacy requested-model reporting recorded as a limitation, not silently corrected.
- All seven provider/Gateway-shaped HTTP requests accounted for, including the failed Gateway attempt before fallback.

Each probe shuts down its tracing SDK and HTTP server in `finally`.
The runner times out stalled subprocesses and removes its temporary installation directory in `finally`.
Only summary JSON is printed; credentials, raw inputs and full telemetry are not printed.
The existing `calling-js` CI job runs this suite on Node 24.
