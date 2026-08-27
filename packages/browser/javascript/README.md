# @abto-app/event

ABTO SDK는 고객사가 선택해 직접 기록한 사용자 행동을 수집하고, Gateway가 반환한 `request_id`를 통해 서버의 LLM 비용·지연 데이터와 연결한다.

`@abto-app/event`는 공개키를 사용하는 Browser 전용 패키지다.
비밀키와 provider credential을 사용하는 Node 환경에는 별도 `@abto-app/calling` 패키지를 설치한다.

PostHog의 autocapture, ingestion, session, schema/discovery는 ABTO 이벤트 설계의 참고 모델이다. ABTO 이벤트를 PostHog로 보내는 연동이 아니라, 검증된 수집 철학을 ABTO 독립 수집 구조에 적용한다.

## 설치

```bash
pnpm add @abto-app/event
```

## 이벤트 경계

Browser SDK가 보내는 이벤트는 두 종류다.

| 종류 | SDK 이름 | Analytics wire 이름 | 정의 주체 | 발생 방식 |
|---|---|---|---|---|
| 시스템 이벤트 | `$`로 시작 | ABTO canonical 이름 | ABTO | 명시적으로 켠 autocapture 또는 전용 API |
| 커스텀 이벤트 | `$` 없이 제품 도메인 이름 사용 | 같은 이름 | 고객 저장소 | `client.capture()` |

사용자는 `$` 이벤트나 `$` 속성을 등록할 수 없다. 아래 canonical wire 이름도 ABTO가 소유하므로 커스텀 이벤트로 등록할 수 없다. ABTO 시스템 이벤트는 일반 `capture()`로 보낼 수 없으며 SDK 내부 경로와 AI trace 전용 메서드만 발생시킨다.

### Browser SDK 시스템 이벤트

| SDK 이벤트 | Analytics `event_name` | 의미 | 발생 조건 |
|---|---|---|---|
| `$pageview` | `pageview` | 페이지/SPA route 진입 | autocapture opt-in 시 초기 로드, history 변경, bfcache 복원 |
| `$pageleave` | `pageleave` | 페이지/route 이탈 | autocapture opt-in 시 SPA 이동, `pagehide` |
| `$autocapture` | `interaction_autocaptured` | DOM 상호작용 원시 사실 | autocapture opt-in 시 click, change, submit, copy |
| `$rageclick` | `interaction_rageclick` | 짧은 시간의 반복 클릭 | autocapture opt-in 시 SDK 휴리스틱 |
| `$dead_click` | `interaction_deadclick` | 반응이 관측되지 않은 클릭 | autocapture opt-in 시 SDK 휴리스틱 |
| `$ai_prompt_submitted` | `llm_prompt_submitted` | 프롬프트 제출을 앱이 확인 | `trace.submitPrompt()` |
| `$ai_response_rendered` | `llm_response_rendered` | 응답이 UI에 렌더됨을 앱이 확인 | `trace.markResponseRendered()` |
| `$ai_response_interacted` | `llm_response_interacted` | 응답에 대한 명시적 행동 | `trace.captureResponseInteraction()` |

`$session_start`와 `$session_end`는 보내지 않는다. 모든 이벤트의 `$session_id`와 timestamp의 최솟값·최댓값을 분석 계층에서 사용해 세션 시작, 종료, duration을 파생한다. 브라우저 종료 신호는 유실될 수 있으므로 `$session_end`를 확정 사실로 기록하지 않는다.

## 커스텀 이벤트 정본: `abto.events.ts`

제품 이벤트는 고객 애플리케이션 저장소의 `abto.events.ts`에 사전 등록한다. 이 파일을 코드 리뷰와 향후 CLI/CI schema push의 정본으로 사용한다.

```ts
// abto.events.ts
import { defineEvents } from '@abto-app/event';

export const events = defineEvents({
  checkout_completed: {
    description: '결제가 완료됨',
    properties: {
      order_id: { type: 'string', required: true },
      value: { type: 'number', required: true },
      scale: {
        type: 'string',
        enum: ['KRW', 'USD'],
        required: true,
      },
    },
  },
});
```

```ts
import { initAbto } from '@abto-app/event';
import { events } from './abto.events';

const abto = initAbto({
  projectKey: 'public_project_key',
  environment: 'development',
  events,
});

abto.capture('checkout_completed', {
  order_id: 'order_123',
  value: 49_000,
  scale: 'KRW',
});
```

`value`와 `scale`은 Success Metric이 읽는 metric 필드로 승격되는 예약 이름이다.
금액이나 개수처럼 집계할 수치는 이 두 이름으로 실어야 하며,
다른 이름의 property는 `extra_json`에만 남아 전환 건수로만 쓰인다.

`defineEvents()`에서 타입을 추론하므로 잘못된 이벤트 이름, required 누락, enum 위반을 개발 시점에 확인할 수 있다. 런타임 정책은 환경별로 다르다.

| 환경 | 미등록 이벤트 | 등록 schema drift |
|---|---|---|
| `development` | 전송하고 `Discovered` 경고 | 전송하고 drift 경고 |
| `production` | drop | required/type/enum 위반 drop |

알 수 없는 추가 속성은 막지 않는다. schema가 선언한 required/type/enum만 검사해 점진적 확장을 허용한다.

## 초기화와 autocapture

앱 루트에서 한 번 초기화한다. 설정을 생략한 기본 초기화는 identity와 trace context만 준비하며 이벤트를 만들지 않는다. 고객사가 필요하다고 정한 Custom Event와 LLM trace event만 해당 제품 동작에서 직접 호출한다.

```ts
const abto = initAbto({
  projectKey: 'public_project_key',
  apiHost: 'https://api.abto.app',
  environment: 'production',
  events,
});
```

페이지와 DOM 상호작용을 넓게 수집해야 하고 데이터 정책 검토를 마친 경우에만 autocapture를 명시적으로 켠다.

```ts
const abto = initAbto({
  projectKey: 'public_project_key',
  autocapture: { enabled: true },
});
```

### 이전 기본값에서 마이그레이션

`0.1.4` 이하에서 `autocapture`를 생략하면 자동 수집이 켜졌다. 그 동작에 의존한 애플리케이션은 업그레이드할 때 `autocapture: { enabled: true }`를 추가해야 한다. 자동 수집이 필요하지 않은 애플리케이션은 설정을 생략하고 선택한 `capture()`와 `LlmTrace` 호출만 유지한다.

기본 endpoint는 `${apiHost}/v1/collect/events`다. SDK 내부의 Browser 이벤트는 전송 직전에
현재 Analytics 수신 계약으로 변환된다.

```json
{
  "batch": [
    {
      "event_id": "019b...",
      "device_id": "019b...",
      "session_id": "019b...",
      "event_name": "checkout_started",
      "value": 3000,
      "scale": "KRW",
      "occurred_at": "2026-07-15T04:10:00.000Z",
      "extra_json": {
        "value": 3000,
        "scale": "KRW",
        "$lib": "web",
        "$lib_version": "0.1.5"
      }
    }
  ]
}
```

서버의 이벤트별 응답은 event UUID를 key로 사용한다.

```json
{
  "results": {
    "019b5b74-11d0-7000-8000-000000000001": {
      "result": "drop",
      "code": "schema_type_mismatch"
    }
  }
}
```

모든 collector 요청은 public project key를 Bearer header에 싣는다. 페이지 이탈도 응답을 읽을 수 있는 `fetch(..., { keepalive: true })`를 사용하며, 서버가 이 key에서 `project_id`와 `account_id`를 결정한다. `$tenant_id`를 포함한 client property는 분석 문맥이며 인증·project 귀속 값이 아니다.

수신 계약의 상한은 요청당 100 events다. SDK 기본값은 20이며 약 60 KiB 이하 payload만 keepalive로 전송한다. malformed request와 인증 실패는 요청 단위 4xx, 개별 validation/storage 실패는 2xx 응답의 UUID별 `warning`, `drop`, `retry`로 처리한다.
커스텀 `event_name`은 Backend와 같은 UTF-16 기준 최대 200자이며, `defineEvents()`와 runtime capture가 enqueue 전에 검증한다.
metric `scale`은 최대 16자이며, 초과한 값은 event 전체가 drop되지 않도록 top-level metadata에서 제외한다.

SDK 내부 queue와 API에서는 `$` 이름을 유지하지만, Analytics의 고정 Event 계약은 `$` 접두
`event_name`을 거절한다. Transport가 위 표의 canonical 이름으로만 변환해 전송하며 `$lib`,
`$device_id`, `$session_id` 같은 SDK 소유 context는 `extra_json`에 그대로 보존한다.
Dashboard 이벤트 카탈로그와 Success Metric에서는 canonical wire 이름을 사용한다.

autocapture를 명시적으로 켠 경우 annotation은 원시 `$autocapture`를 다른 이벤트로 바꾸지 않는다. 원시 상호작용을 보존하면서 분석 차원만 보강한다.

```html
<button
  data-abto-action="accept"
  data-abto-surface="generator"
  data-abto-node-key="resume.make"
  data-abto-response-id="resp_123"
  data-abto-request-id="req_123">
  적용
</button>
```

autocapture를 켰다면 위 클릭은 `$autocapture`로 수집되며 `$ai_action`, `$surface`, `$node_key`, `$response_id`, `$request_id`가 함께 실린다. 업무 의미가 확정된 행동은 앱 코드에서 커스텀 이벤트 또는 AI 전용 메서드로 별도 기록한다.

## 개인정보 기본값

prompt, response, DOM text/value는 기본적으로 원문을 수집하지 않는다.

```ts
initAbto({
  projectKey: 'public_project_key',
  events,
  capture: {
    prompt: 'metadata_only',
    response: 'metadata_only',
    mask: 'all',
  },
});
```

위 값들이 생략됐을 때도 같은 안전한 기본값이 적용된다.

| annotation | 동작 |
|---|---|
| `data-abto-no-capture` | 자신과 하위 트리를 수집하지 않음 |
| `data-abto-sensitive` | 자신과 하위 text/value를 항상 전체 마스킹 |
| `data-abto-include` | 해당 요소의 text/value 수집을 명시적으로 허용 |

`password`, `hidden` input과 카드·비밀번호·SSN 계열 필드는 annotation과 무관하게 보호한다. `full` 원문 수집은 명시적 opt-in이며 고객의 동의·보존·삭제 정책과 함께 사용해야 한다.

## 브라우저에서 관측 가능한 AI 이벤트

브라우저가 확실히 아는 세 가지 사실만 전용 API로 제공한다.

```ts
const trace = abto.startLlmTrace({
  nodeId: 'resume.make',
  taskType: 'draft_generation',
  surface: 'editor',
});

await trace.submitPrompt({
  prompt: promptText,
  language: 'ko',
});

const response = await fetch('/api/generate', {
  method: 'POST',
  headers: { 'content-type': 'application/json', ...trace.getHeaders() },
  body: JSON.stringify({ prompt: promptText }),
});
trace.attachRequestId(response);

await trace.markResponseRendered({
  responseId: 'resp_123',
  timeToRenderMs: 1_380,
});

await trace.captureResponseInteraction('copied', {
  responseId: 'resp_123',
  source: 'copy_button',
});
```

provider/model/token/cost/retry/fallback, 실제 첫 토큰 시점과 request 성공·실패는 Server SDK/Gateway가 소유한다. AI task 완료·이탈은 제품마다 의미가 다르므로 커스텀 이벤트 또는 분석 파생 지표로 둔다.

## 식별자와 세션

| 속성 | 수명과 역할 |
|---|---|
| `$device_id` | 프로젝트별 브라우저 설치, localStorage 유지 |
| `$anonymous_id` | 로그인 전 distinct identity |
| `$user_id` | `identify()`로 연결한 제품 사용자 |
| `$session_id` | 탭 사이에서 공유하는 논리 세션, 30분 idle 또는 24시간 max age에 회전 |
| `$window_id` | 탭/window별 ID, sessionStorage 유지 |
| `$pageview_id` | 페이지/SPA route 구간, pageview마다 회전 |
| `$trace_id` | 한 사용자 행동에서 서버 호출까지 연결 |
| `$request_id` | Gateway의 실제 provider 호출 PK |

```ts
abto.identify('user_123', 'tenant_123');
abto.reset();        // user/tenant 제거, device 유지
abto.forgetDevice(); // outbox와 device identity 제거
```

## 전송과 재시도

- 이벤트는 localStorage outbox에 먼저 저장한다.
- 기본적으로 최대 20개씩 `POST /v1/collect/events`로 보낸다.
- 일반 flush와 페이지 이탈 모두 응답 가능한 `fetch`를 사용하며, 안전 크기의 이탈 payload에만 `keepalive`를 켠다.
- keepalive payload는 약 60 KiB 이내로 제한한다. 응답 전에 페이지가 종료되면 localStorage outbox가 다음 SDK 인스턴스에서 재전송한다.
- 408, 429, 5xx와 이벤트별 `retry`만 지수 backoff로 재시도한다.
- 영구 4xx와 이벤트별 `drop`은 outbox에서 제거한다.
- 이벤트별 `ok`, `warning`, `drop`, `retry` 응답을 UUID 기준으로 처리한다.

## Public API (browser)

`initAbto` · `defineEvents` · `identify` · `getIdentity` · `reset` · `forgetDevice` · `startLlmTrace` · `setNode` · `getTraceHeaders` · `client.capture` · `trace.submitPrompt` · `trace.markResponseRendered` · `trace.captureResponseInteraction` · `flush`.

## 개발 검증

```bash
pnpm test
pnpm typecheck
pnpm build
node ../../examples/browser-smoke/collector.mjs
```

실브라우저 검증 절차는 [`examples/browser-smoke/README.md`](../../examples/browser-smoke/README.md)를 따른다.
