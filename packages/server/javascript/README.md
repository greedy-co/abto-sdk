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

const abto = initAbto({
  abtoApiKey: process.env.ABTO_API_KEY,
  providerKeys: {
    openai: process.env.OPENAI_API_KEY,
  },
  gatewayBaseURL: 'https://gateway.abto.app/v1',
  deviceId: process.env.ABTO_DEVICE_ID,
});

const openai = await abto.openai();
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

## Public API

- `initAbto`
- `createAbtoOpenAI`
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
