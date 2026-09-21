import { ChatOpenAI, type ChatOpenAIFields } from '@langchain/openai';
import OpenAI from 'openai';
import { initAbto } from '@abto-app/calling';

const abto = initAbto({
  abtoApiKey: 'calling-test', gatewayBaseURL: 'https://gateway.abto.app/v1',
  providerKeys: { openai: 'provider-test' },
});
const existing: ChatOpenAIFields['configuration'] = { timeout: 1000 };
const model = new ChatOpenAI({
  apiKey: 'provider-test', model: 'gpt-4o-mini',
  configuration: abto.openaiOptions(existing),
});
const defaultModel = new ChatOpenAI({
  apiKey: 'provider-test', configuration: abto.openaiOptions(),
});
const openai = new OpenAI(abto.openaiOptions({ maxRetries: 0 }));
void [model, defaultModel, openai];
