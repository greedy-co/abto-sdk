# abto (Python)

ABTO server-side SDK for Python. 얇은 gateway 헤더 helper로, `contextvars`로 `x-abto-*` 식별자를 운반하고 `httpx` event hook으로 outbound provider 호출에 주입한다. token·cost·latency·`request_id`·variant는 gateway가 소유한다.

`@abto-app/calling`(Node)의 Python 대응이다. npm과 PyPI는 다른 레지스트리라 언어별로 분리 배포한다.

## Install

```bash
pip install abto                 # 코어(contextvars 헤더 helper)
pip install "abto[openai]"       # openai + httpx 통합까지
```

## Quick Start

```python
import os

from abto import init_abto

abto = init_abto(
    api_key=os.environ["ABTO_API_KEY"],
    gateway_base_url="https://gateway.abto.app/v1",
    provider_keys={
        "openai": os.environ["OPENAI_API_KEY"],
        # 프로젝트가 Anthropic/Gemini로 라우팅될 수 있으면 해당 후보 키도 함께 전달한다.
        # "anthropic": os.environ["ANTHROPIC_API_KEY"],
        # "gemini": os.environ["GEMINI_API_KEY"],
    },
)
openai = abto.openai()  # Gateway 인증·context·provider 후보 키를 요청마다 주입

def generate(device_id: str, trace_id: str):
    with abto.with_context(device_id=device_id, node_key="resume.make", trace_id=trace_id):
        return openai.chat.completions.create(
            model="gpt-4.1",
            messages=[{"role": "user", "content": "Create a resume draft"}],
        )
```

## httpx 직접 사용

```python
import httpx
from abto import with_context

client = httpx.Client(event_hooks=abto.httpx_event_hooks())

with with_context(device_id="d1", node_key="resume.make"):
    client.post("https://gateway.abto.app/v1/...")  # x-abto-* 자동 첨부
```

## Public API

- `init_abto(api_key=None, gateway_base_url=None, provider_keys=None, fallback=None) -> Abto` — ABTO inbound key, provider 후보 키, direct fallback을 구성
- `abto.openai(**kwargs)` — gateway baseURL + 헤더 주입된 OpenAI client (extra: `openai`)
- `OpenAIDirectFallbackOptions` — OpenAI direct fallback의 retry·timeout 정책
- `abto.with_context(device_id=?, node_key=?, trace_id=?)` — 요청 단위 context (context manager)
- `abto.get_headers(ctx=None)` / `abto.create_trace_id()` / `abto.httpx_event_hooks()`
- 하위 helper: `with_context`, `get_context`, `get_headers`, `create_trace_id`, `create_traceparent`, `abto_request_hook`, `ABTO_HEADER`, `AbtoContext`

## Header Contract

```text
x-abto-device-id     (optional; 없으면 user 기준 분석과 sticky 배정에서만 빠진다)
x-abto-node-key     (required; "feature.node" dot notation, e.g. resume.make)
traceparent        (trace_id; gateway-deferred in Round1)
x-abto-key-openai  (route 후보 provider key; provider별로 선택해 추가)
Authorization       (required; Bearer ABTO inbound key)
```

Gateway는 API key를 `tenant_id`로 매핑하고 `request_id`(응답 `x-request-id`)를 발급하며 `variant_id`를 배정하고, provider 전달 전 `x-abto-*`를 strip한다.

## Gateway 장애 시 OpenAI direct fallback

OpenAI provider key가 있으면 안전한 Gateway 장애에 대한 direct fallback이 기본 활성화된다.
이 경로는 Gateway의 provider/model 배정을 재현하지 않는다.
원본 Chat Completions body와 `model`을 그대로 OpenAI API로 보내므로,
요청의 model도 OpenAI가 지원하는 이름이어야 한다.

```python
from abto import OpenAIDirectFallbackOptions, init_abto

abto = init_abto(
    api_key=os.environ["ABTO_API_KEY"],
    provider_keys={
        "openai": os.environ["OPENAI_API_KEY"],
        "anthropic": os.getenv("ANTHROPIC_API_KEY"),
        "gemini": os.getenv("GEMINI_API_KEY"),
    },
    fallback=OpenAIDirectFallbackOptions(
        max_retries=2,       # direct OpenAI 요청만 최대 두 번 재시도
        timeout_seconds=30,  # Gateway 응답 대기 상한
        on_timeout=False,    # timeout 난 현재 요청은 기본적으로 재전송하지 않음
    ),
)
```

기본 동작은 JavaScript Calling SDK와 동일하다.

- DNS·연결 수립·TLS 실패, Gateway 도달 전 edge `502`·`503`·`504`, provider 호출 전 admission `503`: 현재 요청을 OpenAI로 직접 전송
- Gateway timeout·전송 여부가 모호한 disconnect: 현재 요청은 원래 오류를 반환하고 circuit만 30초 동안 열어 이후 새 요청을 direct 경로로 전송
- `on_timeout=True`: timeout 난 현재 요청도 직접 재전송; 중복 실행·과금 위험이 있어 명시적으로만 사용
- provider·transport·internal 오류, 모호한 disconnect, 결정적인 `4xx`·`429`, streaming 시작 이후 실패: 현재 요청 direct fallback 없음

Direct 경로는 ABTO header와 Calling Key를 제거하고 OpenAI key만 사용한다.
또한 `accept`, `content-type`, `idempotency-key`, `openai-*`, `x-stainless-*`처럼
OpenAI에 필요한 header만 전달하고 Cookie·proxy credential·사용자 정의 Gateway header는 제거한다.
Gateway policy, ABTO retry, telemetry, `request_id`도 적용되지 않는다.
기능 전체를 끄려면 `init_abto(..., fallback=False)`를 사용한다.
`max_retries`는 `0`부터 `5`까지이며 direct OpenAI 요청에만 적용된다.
`timeout_seconds`는 Gateway connection pool 대기, 연결, 쓰기, 응답 헤더 읽기 각 단계의 inactivity 상한이며,
헤더 이후 body와 direct 요청은 `abto.openai(timeout=...)` 값을 유지한다.
OpenAI SDK 자체 retry는 Gateway와 중첩되지 않도록 항상 `0`이다.

Anthropic·Gemini key는 Gateway 라우팅 후보로 전달되지만,
현재 SDK는 두 provider의 네이티브 direct fallback을 제공하지 않는다.

## Test

```bash
pip install pytest && pytest
```
