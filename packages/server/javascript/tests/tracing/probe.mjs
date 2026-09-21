import assert from 'node:assert/strict';
import { AsyncLocalStorage } from 'node:async_hooks';
import { writeFileSync } from 'node:fs';
import { assertNoCredentials, callingKey, providerKey, localServer } from '../server.mjs';

const modern = process.argv[2] === 'modern';
for (const key of Object.keys(process.env)) {
  if (/^(LANGFUSE|LANGSMITH|LANGCHAIN|OPENAI|ABTO|OTEL)_/.test(key)) delete process.env[key];
}
process.env.LANGCHAIN_TRACING_V2 = 'false';
process.env.LANGCHAIN_CALLBACKS_BACKGROUND = 'false';

const server = await localServer();
const nativeFetch = globalThis.fetch;
globalThis.fetch = (input, init) => {
  assert.equal(new URL(input instanceof Request ? input.url : input).origin, server.url);
  return nativeFetch(input, init);
};
const handlers = [];
const customer = new AsyncLocalStorage();
let sdk, processor, exporter, otherExporter, otel;
try {
  if (modern) {
    const { NodeSDK } = await import('@opentelemetry/sdk-node');
    const { InMemorySpanExporter, SimpleSpanProcessor } = await import('@opentelemetry/sdk-trace-base');
    const { LangfuseSpanProcessor } = await import('@langfuse/otel');
    otel = await import('@opentelemetry/api');
    exporter = new InMemorySpanExporter();
    otherExporter = new InMemorySpanExporter();
    processor = new LangfuseSpanProcessor({
      exporter, publicKey: 'fixture-public', secretKey: 'fixture-telemetry', baseUrl: server.url,
      mediaUploadEnabled: false, flushInterval: 60000,
    });
    sdk = new NodeSDK({ resourceDetectors: [], spanProcessors: [processor, new SimpleSpanProcessor(otherExporter)] });
    sdk.start();
  }
  const { ChatOpenAI } = await import('@langchain/openai');
  const { ChatPromptTemplate } = await import('@langchain/core/prompts');
  const { StringOutputParser } = await import('@langchain/core/output_parsers');
  const { awaitAllCallbacks } = await import('@langchain/core/callbacks/promises');
  const { LangChainTracer } = await import('@langchain/core/tracers/tracer_langchain');
  const { Client } = await import('langsmith');
  const { CallbackHandler } = await import(modern ? '@langfuse/langchain' : 'langfuse-langchain');
  const { initAbto } = await import('@abto-app/calling');
  const smith = new Client({
    apiUrl: `${server.url}/langsmith`, apiKey: 'fixture-telemetry',
    autoBatchTracing: false, fetchImplementation: globalThis.fetch,
  });
  const smithHandler = new LangChainTracer({ client: smith, projectName: 'local-coexistence' });
  const sharedHandler = modern ? new CallbackHandler({ sessionId: 'fixture-session' }) : undefined;
  function langfuseHandler() {
    if (sharedHandler) return sharedHandler;
    // Legacy handlers own one mutable root trace; scope them to an invocation.
    const handler = new CallbackHandler({
      baseUrl: server.url, publicKey: 'fixture-public', secretKey: 'fixture-telemetry',
      flushInterval: 60000, flushAt: 1000,
    });
    handlers.push(handler);
    return handler;
  }
  const abto = initAbto({
    abtoApiKey: callingKey, providerKeys: { openai: providerKey }, gatewayBaseURL: `${server.url}/gateway/v1`,
  });
  const serializedModels = [];
  const callbacks = [];
  const callback = {
    name: 'customer-callback', raiseError: true,
    handleChatModelStart(serialized) { serializedModels.push(serialized); },
    handleLLMEnd() { callbacks.push({ type: 'success', customer: customer.getStore()?.name }); },
    handleLLMError() { callbacks.push({ type: 'error' }); },
  };
  function model(client) {
    const configuration = {
      baseURL: `${server.url}/direct/v1`,
      fetch: async (input, init) => {
        if (modern && customer.getStore()) {
          assert.equal(otel.trace.getSpan(otel.context.active()).spanContext().traceId, customer.getStore().traceId);
        }
        return fetch(input, init);
      },
    };
    // Simulate an existing client configuration with its own provider credential.
    if (client) configuration.apiKey = providerKey;
    const result = new ChatOpenAI({
      apiKey: providerKey, model: 'gpt-4o-mini', temperature: 0.7, maxRetries: 0,
      ...(modern ? { useResponsesApi: false } : {}),
      configuration: client ? client.openaiOptions(configuration) : configuration,
    });
    assertNoCredentials(result.toJSON());
    return result;
  }
  const prompt = ChatPromptTemplate.fromMessages([
    ['system', 'Customer dynamic context: {customer}'], ['human', '{question}'],
  ]);
  const roots = [];
  for (const mode of ['baseline', 'abto']) {
    const chain = prompt.pipe(model(mode === 'abto' ? abto : undefined)).pipe(new StringOutputParser());
    await Promise.all(['slow', 'fast'].map(async (name, index) => {
      async function invoke(root) {
        const traceId = root?.spanContext().traceId ?? String(index + 1).repeat(32);
        const headers = { traceparent: `00-${traceId}-${String(index + 1).repeat(16)}-00`, tracestate: `customer=${name}` };
        if (modern) otel.propagation.inject(otel.context.active(), headers);
        const result = await customer.run({ name, traceId }, async () => {
          const call = () => chain.invoke({ customer: name, question: `${mode}-${name}` }, {
            callbacks: [langfuseHandler(), smithHandler, callback],
            metadata: { case: `${mode}-${name}` }, tags: ['customer-tag'], options: { headers },
          });
          return mode === 'abto'
            ? abto.withContext({ deviceId: name, featureId: 'support.reply', traceId: 'f'.repeat(32) }, call)
            : call();
        });
        assert.equal(result, `answer:${mode}-${name}`);
        const request = server.requests.find(r => r.body.messages.at(-1).content === `${mode}-${name}`);
        assert.equal(request.headers.traceparent, headers.traceparent);
        assert.equal(request.headers.tracestate, headers.tracestate);
        if (mode === 'abto') assert.equal(request.headers['x-abto-device-id'], name);
        roots.push({ name: `${mode}-${name}`, traceId });
      }
      if (!modern) return invoke();
      return otel.trace.getTracer('customer').startActiveSpan(`${mode}-${name}`, async root => {
        try { await invoke(root); } finally { root.end(); }
      });
    }));
  }
  assert.equal(customer.getStore(), undefined);
  assert.equal(abto.getContext(), undefined);
  await assert.rejects(() => model(abto).invoke('provider-error', { callbacks: [langfuseHandler(), smithHandler, callback] }));
  const fallback = initAbto({
    abtoApiKey: callingKey, providerKeys: { openai: providerKey }, gatewayBaseURL: `${server.url}/unavailable/v1`,
    fallback: { baseURL: `${server.url}/direct/v1` },
  });
  const answer = await model(fallback).invoke('fallback', { callbacks: [langfuseHandler(), smithHandler, callback] });
  assert.equal(answer.content, 'answer:fallback');
  await awaitAllCallbacks();
  await smith.awaitPendingTraceBatches();
  await Promise.all(handlers.map(handler => handler.flushAsync()));
  if (processor) await processor.forceFlush();
  server.assertHealthy();
  assert.equal(server.requests.length, 7);
  assert.equal(callbacks.filter(event => event.type === 'success').length, 5);
  assert.equal(callbacks.filter(event => event.type === 'error').length, 1);
  assert.deepEqual(callbacks.filter(event => event.customer).map(event => event.customer).sort(), ['fast', 'fast', 'slow', 'slow']);
  assert.equal(serializedModels.length, 6);
  const smithModels = server.langsmith.filter(event => event.method === 'POST' && event.body.run_type === 'llm');
  assert.equal(smithModels.length, 6, 'Actual LangSmith HTTP export must include every LLM run');
  assertNoCredentials(serializedModels);
  assertNoCredentials(server.langsmith);
  assertNoCredentials(server.langfuse);
  let reportedModels;
  if (modern) {
    const spans = exporter.getFinishedSpans();
    const generations = spans.filter(span => span.attributes['langfuse.observation.type'] === 'generation');
    assert.equal(generations.length, 6);
    assert.equal(generations.filter(span => span.attributes['langfuse.observation.level'] === 'ERROR').length, 1);
    for (const root of roots) {
      const generation = generations.find(span => span.spanContext().traceId === root.traceId);
      assert(generation);
      assert.equal(generation.attributes['langfuse.observation.model.name'], root.name.startsWith('abto') ? 'gpt-4.1-mini' : 'gpt-4o-mini');
      assert.equal(generation.attributes['langfuse.observation.metadata.case'], root.name);
      assert(otherExporter.getFinishedSpans().some(span => span.name === root.name && span.spanContext().traceId === root.traceId));
    }
    assertNoCredentials(spans.map(span => span.attributes));
    reportedModels = generations.map(span => span.attributes['langfuse.observation.model.name']);
  } else {
    const creates = server.langfuse.filter(event => event.type === 'generation-create');
    const updates = server.langfuse.filter(event => event.type === 'generation-update');
    assert.equal(creates.length, 6);
    assert.equal(new Set(creates.map(event => event.body.traceId)).size, 6);
    assert.equal(updates.filter(event => event.body.output).length, 5);
    assert.equal(updates.filter(event => event.body.level === 'ERROR').length, 1);
    for (const event of creates) {
      const update = updates.find(update => update.body.id === event.body.id);
      assert.equal(update?.body.traceId, event.body.traceId);
      if (event.body.metadata.case) assert(event.body.metadata.tags.includes('customer-tag'));
    }
    // Record the legacy limitation without rewriting the customer's model configuration.
    reportedModels = creates.map(event => updates.find(update => update.body.id === event.body.id)?.body.model ?? event.body.model);
  }
  const report = {
    status: 'passed', stack: modern ? 'modern' : 'legacy', node: process.version,
    exportedLangSmithModels: smithModels.length, serializedCredentials: false,
    requests: server.requests.length, successfulCallbacks: 5, errorCallbacks: 1, reportedModels,
    coexistence: modern ? 'Langfuse + LangSmith + independent OpenTelemetry processor' : 'Langfuse + LangSmith',
  };
  writeFileSync('report.json', `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report));
} finally {
  try {
    await Promise.allSettled(handlers.map(handler => handler.shutdownAsync()));
    if (sdk) await sdk.shutdown();
  } finally {
    await server.close();
    globalThis.fetch = nativeFetch;
  }
}
