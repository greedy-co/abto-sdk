const assert = require('node:assert/strict');
const { AsyncLocalStorage } = require('node:async_hooks');
const { ChatOpenAI } = require('@langchain/openai');
const sdk = require('@abto-app/calling');
const { StringOutputParser } = require('@langchain/core/output_parsers');
const gateway = 'https://gateway.abto.app/v1';
const direct = 'https://api.openai.com/v1';
const seen = [];
const customerContext = new AsyncLocalStorage();
let mode = 'ok';
let providerKey = 'provider-test';
let callbacks = 0;
const completion = {
  id: 'chatcmpl-test', object: 'chat.completion', created: 1, model: 'gpt-4o-mini',
  choices: [{ index: 0, message: { role: 'assistant', content: 'LangChain works' }, finish_reason: 'stop' }],
  usage: { prompt_tokens: 2, completion_tokens: 3, total_tokens: 5 },
};
const abto = sdk.initAbto({
  abtoApiKey: 'calling-test', gatewayBaseURL: gateway,
  providerKeys: { openai: () => providerKey },
  fallback: { baseURL: direct },
});
const model = new ChatOpenAI({
  apiKey: 'provider-test', model: 'gpt-4o-mini', maxRetries: 0,
  modelKwargs: { reasoning_effort: 'none' },
  callbacks: [{
    handleChatModelStart(serialized) {
      for (const secret of ['calling-test', 'provider-test', 'rotated-provider-test']) {
        assert(!JSON.stringify(serialized).includes(secret));
      }
    },
    handleLLMEnd() { callbacks++; },
  }],
  configuration: abto.openaiOptions({
    timeout: 5000,
    defaultHeaders: { 'x-product': 'preserved' },
    fetch: async (input, init) => {
      const request = new Request(input, init);
      seen.push({ url: request.url, headers: request.headers, body: await request.json() });
      if (customerContext.getStore()) {
        assert.equal(request.headers.get('x-abto-device-id'), customerContext.getStore().requestId);
      }
      if (mode === 'refused' && request.url.startsWith(gateway)) {
        throw new TypeError('fetch failed', { cause: Object.assign(new Error('refused'), { code: 'ECONNREFUSED' }) });
      }
      if (mode === 'provider-error') {
        return new Response('{"error":{"message":"provider failed"}}', {
          status: 500, headers: { 'content-type': 'application/json', 'x-abto-error-source': 'provider' },
        });
      }
      return new Response(JSON.stringify(completion), { headers: { 'content-type': 'application/json' } });
    },
  }),
});

(async () => {
  assert(!JSON.stringify(model).includes('calling-test'));
  const esm = await import('@abto-app/calling');
  assert.equal(esm.initAbto, sdk.initAbto);
  const result = await esm.runWithAbtoContext({ deviceId: 'mixed-entry-device' }, () =>
    abto.withContext({ featureId: 'support.reply' }, () => model.invoke('hello')));
  assert.equal(result.content, 'LangChain works');
  assert.deepEqual(result.usage_metadata, { input_tokens: 2, output_tokens: 3, total_tokens: 5 });
  assert.equal(callbacks, 1);
  assert.equal(seen[0].url, `${gateway}/chat/completions`);
  assert.equal(seen[0].headers.get('authorization'), 'Bearer calling-test');
  assert.equal(seen[0].headers.get('x-product'), 'preserved');
  assert.equal(seen[0].headers.get('x-abto-device-id'), 'mixed-entry-device');
  assert.equal(seen[0].headers.get('x-abto-feature-id'), 'support.reply');
  assert.equal(seen[0].body.stream, false);
  assert.equal(seen[0].body.reasoning_effort, 'none');
  assert.equal(seen[0].body.messages[0].content, 'hello');
  assert.equal(seen[0].body.stop, undefined);

  providerKey = 'rotated-provider-test';
  await Promise.all(['a', 'b'].map(deviceId => customerContext.run({ requestId: deviceId }, () =>
    abto.withContext({ deviceId, featureId: 'support.reply', traceId: 'f'.repeat(32) }, async () => {
    await Promise.resolve();
    await model.invoke(deviceId, {
      options: { headers: {
        traceparent: `00-${deviceId.repeat(32)}-${deviceId.repeat(16)}-00`,
        tracestate: `customer=${deviceId}`,
      } },
      callbacks: [{ handleLLMEnd() { assert.equal(customerContext.getStore().requestId, deviceId); } }],
    });
    assert.equal(customerContext.getStore().requestId, deviceId);
  }))));
  assert.equal(customerContext.getStore(), undefined);
  for (const request of seen.slice(1)) {
    assert.equal(request.headers.get('x-abto-device-id'), request.body.messages[0].content);
    assert.equal(request.headers.get('x-abto-key-openai'), providerKey);
    const deviceId = request.body.messages[0].content;
    assert.equal(request.headers.get('traceparent'), `00-${deviceId.repeat(32)}-${deviceId.repeat(16)}-00`);
    assert.equal(request.headers.get('tracestate'), `customer=${deviceId}`);
  }
  const chain = model.pipe(new StringOutputParser());
  assert.equal(await chain.invoke('chain'), 'LangChain works');
  mode = 'provider-error';
  const before = seen.length;
  await assert.rejects(() => model.invoke('fails'));
  assert.equal(seen.length, before + 1, 'LangChain maxRetries=0 must not be overridden');
  assert.equal(seen.at(-1).url, `${gateway}/chat/completions`);

  mode = 'refused';
  const fallbackTrace = { traceparent: `00-${'c'.repeat(32)}-${'d'.repeat(16)}-00`, tracestate: 'customer=fallback' };
  const fallback = await model.invoke('fallback', { options: { headers: fallbackTrace } });
  assert.equal(fallback.content, 'LangChain works');
  assert.equal(seen.at(-2).url, `${gateway}/chat/completions`);
  assert.equal(seen.at(-1).url, `${direct}/chat/completions`);
  assert.deepEqual(seen.at(-1).body, seen.at(-2).body);
  assert.equal(seen.at(-1).headers.get('authorization'), `Bearer ${providerKey}`);
  assert.equal(seen.at(-1).headers.has('x-abto-key-openai'), false);
  for (const request of seen.slice(-2)) {
    assert.equal(request.headers.get('traceparent'), fallbackTrace.traceparent);
    assert.equal(request.headers.get('tracestate'), fallbackTrace.tracestate);
  }
  const factory = await abto.openai({ clientOptions: { maxRetries: 0, fetch: async (input, init) => {
    const request = new Request(input, init);
    assert.equal(request.url, `${direct}/chat/completions`, 'Factory must share the circuit opened by LangChain');
    assert.equal(request.headers.get('authorization'), `Bearer ${providerKey}`);
    return new Response(JSON.stringify(completion), { headers: { 'content-type': 'application/json' } });
  } } });
  assert.equal((await factory.chat.completions.create({ model: 'gpt-4o-mini', messages: [] })).id, 'chatcmpl-test');
  console.log(`LangChain 0.2.7 / OpenAI 4.56.0 passed on ${process.version}`);
})().catch(error => { console.error(error); process.exitCode = 1; });
