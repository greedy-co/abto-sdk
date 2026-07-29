# @abto-app/calling

ABTO JavaScript Server SDK는 provider 요청을 ABTO Gateway로 라우팅하고 요청 단위 식별 문맥과 provider credential을 전달하는 Node.js 전용 패키지다.

Browser autocapture, DOM, 공개 project key는 다루지 않는다.
브라우저에서 사용자 행동을 수집하려면 `@abto-app/event`를 설치한다.

## 설치

```bash
pnpm add @abto-app/calling openai
```

## 빠른 시작

```ts
import { initAbto } from '@abto-app/calling';
import type OpenAI from 'openai';

const abto = initAbto({
  abtoApiKey: process.env.ABTO_API_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
  },
  gatewayBaseURL: 'https://gateway.abto.app/v1',
  deviceId: process.env.ABTO_DEVICE_ID,
});

const openai = await abto.openai<OpenAI>();
```

## 요청 문맥

```ts
import {
  createTraceId,
  getAbtoHeaders,
  runWithAbtoContext,
} from '@abto-app/calling';

await runWithAbtoContext(
  {
    deviceId: 'device_123',
    nodeKey: 'resume.make',
    traceId: createTraceId(),
  },
  async () => {
    const headers = getAbtoHeaders();
    // 이 문맥에서 생성한 provider 요청에 동일한 ABTO 식별자를 전달한다.
  },
);
```

Gateway는 provider 요청과 응답, token, cost, latency, `request_id`, variant 배정의 정본이다.
Server SDK는 원본 provider 요청을 재작성하지 않고 Gateway 주소와 ABTO header를 운반한다.

## Gateway 장애 시 OpenAI direct fallback

`providerKeys.openai` 또는 `OPENAI_API_KEY`가 있으면 안전한 Gateway 장애에 대한 OpenAI direct fallback이 기본 활성화된다.
이 경로는 Gateway의 provider/model 배정을 재현하지 않는 비상 경로다.
원본 Chat Completions body와 `model`을 그대로 `https://api.openai.com/v1/chat/completions`로 보내므로,
요청의 model도 OpenAI가 지원하는 이름이어야 한다.

```ts
const abto = initAbto({
  abtoApiKey: process.env.ABTO_API_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
    anthropic: process.env.ANTHROPIC_API_KEY,
    gemini: process.env.GEMINI_API_KEY,
  },
  fallback: {
    maxRetries: 2,     // direct OpenAI 요청만 최대 두 번 재시도
    timeoutMs: 30_000, // Gateway 응답 header 대기 상한
    onTimeout: false,  // timeout 난 현재 요청은 기본적으로 재전송하지 않음
  },
});
```

기본 동작은 다음과 같다.

- DNS·연결 수립·TLS 실패: provider에 전송되지 않은 것이 확실하므로 현재 요청을 OpenAI로 직접 전송
- `x-request-id`가 없는 edge `502`·`503`·`504`: Gateway 도달 전 실패로 보고 현재 요청을 직접 전송
- `x-request-id`는 있지만 `x-abto-error-source`가 없는 admission `503`: provider 호출 전 실패로 보고 현재 요청을 직접 전송
- Gateway timeout·전송 여부가 모호한 disconnect: circuit만 30초 동안 열고 현재 요청은 원래 오류 반환; 이후 새 요청은 OpenAI direct 경로 사용
- `fallback.onTimeout: true`: timeout 난 현재 요청도 직접 재전송; Gateway가 이미 provider를 실행했을 수 있어 중복 실행·과금 위험이 있음
- `x-abto-error-source: provider|transport|internal`, 모호한 disconnect, 결정적인 `4xx`·`429`, caller abort, streaming 시작 이후 실패: 현재 요청 direct fallback 없음

Circuit이 열린 30초 동안 새 요청은 Gateway를 건너뛰고,
기간이 끝나면 한 요청만 Gateway 회복 여부를 확인한다.
Direct 경로에는 ABTO header와 Calling Key를 보내지 않고 OpenAI key만 사용한다.
또한 `accept`, `content-type`, `idempotency-key`, `openai-*`, `x-stainless-*`처럼
OpenAI에 필요한 header만 전달하고 Cookie·proxy credential·사용자 정의 Gateway header는 제거한다.
이 호출은 Gateway policy, ABTO retry, telemetry, `request_id`의 적용 대상이 아니다.

필요하면 전체 기능을 끌 수 있다.

```ts
initAbto({
  // ...
  fallback: false,
});
```

`fallback.maxRetries`는 `0`부터 `5`까지 설정할 수 있고 direct OpenAI 요청에만 적용된다.
`fallback.timeoutMs`는 로컬 dispatcher 대기부터 Gateway 응답 헤더까지의 end-to-end 상한이며, direct 요청은 OpenAI client의 timeout 설정을 유지한다.
Caller 또는 OpenAI client deadline으로 abort된 direct 요청은 재시도하지 않고, `maxRetries`는 caller deadline이 남은 direct 실패에만 적용된다.
Gateway 요청의 OpenAI SDK retry는 중첩 실행을 막기 위해 항상 `0`이다.
Anthropic·Gemini key는 Gateway 라우팅 후보로 계속 전달되지만,
현재 SDK는 두 provider의 네이티브 direct fallback을 제공하지 않는다.

## Public API

- `initAbto`
- `createAbtoOpenAI`
- `OpenAIDirectFallbackConfig`
- `OpenAIDirectFallbackOptions`
- `runWithAbtoContext`
- `getAbtoContext`
- `getAbtoHeaders`
- `createTraceId`
- `createTraceparent`

## 개발 검증

```bash
pnpm test
pnpm typecheck
pnpm build
```
