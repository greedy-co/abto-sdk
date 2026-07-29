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

- `init_abto(api_key=None, gateway_base_url=None, provider_keys=None) -> Abto` — ABTO inbound key와 provider 후보 키를 구성
- `abto.openai(**kwargs)` — gateway baseURL + 헤더 주입된 OpenAI client (extra: `openai`)
- `abto.with_context(device_id=?, node_key=?, trace_id=?)` — 요청 단위 context (context manager)
- `abto.get_headers(ctx=None)` / `abto.create_trace_id()` / `abto.httpx_event_hooks()`
- 하위 helper: `with_context`, `get_context`, `get_headers`, `create_trace_id`, `create_traceparent`, `abto_request_hook`, `ABTO_HEADER`, `AbtoContext`

## Header Contract

```text
x-abto-device-id     (required)
x-abto-node-key     (required; "feature.node" dot notation, e.g. resume.make)
traceparent        (trace_id; gateway-deferred in Round1)
x-abto-key-openai  (route 후보 provider key; provider별로 선택해 추가)
Authorization       (required; Bearer ABTO inbound key)
```

Gateway는 API key를 `tenant_id`로 매핑하고 `request_id`(응답 `x-request-id`)를 발급하며 `variant_id`를 배정하고, provider 전달 전 `x-abto-*`를 strip한다.

## Test

```bash
pip install pytest && pytest
```
