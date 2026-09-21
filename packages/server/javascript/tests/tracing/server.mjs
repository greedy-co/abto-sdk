import assert from 'node:assert/strict';
import { createServer } from 'node:http';

export const callingKey = 'fixture-calling-secret';
export const providerKey = 'fixture-provider-secret';

export function assertNoCredentials(value) {
  const serialized = JSON.stringify(value);
  for (const secret of [callingKey, providerKey]) {
    assert(!serialized.includes(secret), 'Credentials must not enter trace payloads');
  }
}

export async function localServer() {
  const requests = [];
  const langfuse = [];
  const langsmith = [];
  const server = createServer(async (req, res) => {
    try {
      let raw = '';
      for await (const chunk of req) raw += chunk;
      const body = raw ? JSON.parse(raw) : {};
      res.setHeader('content-type', 'application/json');
      if (req.url.startsWith('/langsmith')) {
        langsmith.push({ method: req.method, body });
        res.end(JSON.stringify(req.url.endsWith('/info')
          ? { batch_ingest_config: { use_multipart_endpoint: false } } : {}));
        return;
      }
      if (req.url === '/api/public/ingestion') {
        langfuse.push(...body.batch);
        res.end(JSON.stringify({
          successes: body.batch.map(event => ({ id: event.id, status: 201 })), errors: [],
        }));
        return;
      }
      const direct = req.url.startsWith('/direct/');
      assert.equal(req.headers.authorization, `Bearer ${direct ? providerKey : callingKey}`);
      assert.equal(req.headers['x-abto-key-openai'], direct ? undefined : providerKey);
      if (direct) assert(!Object.keys(req.headers).some(key => key.startsWith('x-abto-')));
      requests.push({
        path: req.url, body,
        headers: Object.fromEntries(Object.entries(req.headers)
          .filter(([key]) => !['authorization', 'x-abto-key-openai'].includes(key))),
      });
      if (req.url.startsWith('/unavailable/')) {
        res.statusCode = 503;
        res.end(JSON.stringify({ error: { message: 'Gateway unavailable' } }));
        return;
      }
      const input = body.messages.at(-1).content;
      if (input === 'provider-error') {
        res.statusCode = 429;
        res.setHeader('x-abto-request-id', 'fixture-error');
        res.setHeader('x-abto-error-source', 'provider');
        res.end(JSON.stringify({ error: { message: 'Synthetic provider error', type: 'rate_limit_error' } }));
        return;
      }
      await new Promise(resolve => setTimeout(resolve, input.includes('slow') ? 20 : 1));
      res.setHeader('x-abto-request-id', 'fixture-request');
      res.end(JSON.stringify({
        id: 'fixture-completion', object: 'chat.completion', created: 1,
        model: direct ? body.model : 'gpt-4.1-mini',
        choices: [{ index: 0, message: { role: 'assistant', content: `answer:${input}` }, finish_reason: 'stop' }],
        usage: { prompt_tokens: 10, completion_tokens: 3, total_tokens: 13 },
      }));
    } catch (error) {
      server.failure = error;
      res.statusCode = 500;
      res.end(JSON.stringify({ error: { message: 'Local fixture assertion failed' } }));
    }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  return {
    url: `http://127.0.0.1:${server.address().port}`, requests, langfuse, langsmith,
    assertHealthy() { if (server.failure) throw server.failure; },
    close: () => new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }),
  };
}
