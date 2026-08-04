<p align="right">
  <strong>한국어</strong> · <a href="./README.en.md">English</a>
</p>

<div align="center">
  <h1>ABTO SDK</h1>
  <p><strong>제품 행동에서 AI 비용·지연·품질까지, 하나의 흐름으로 연결하세요.</strong></p>
  <p><sub>브라우저·서버·모바일 SDK와 코딩 에이전트용 통합 Skill을 한 저장소에서 제공합니다.</sub></p>
  <p>
    <a href="https://github.com/greedy-co/abto-sdk/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/greedy-co/abto-sdk/ci.yml?branch=main&style=flat-square&label=SDK%20CI" alt="SDK CI"></a>
    <a href="https://docs.abto.app/"><img src="https://img.shields.io/badge/docs-docs.abto.app-2563eb?style=flat-square" alt="Documentation"></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-22c55e?style=flat-square" alt="MIT License"></a>
  </p>
</div>

<p align="center">
  <a href="#가장-빠른-시작">빠른 시작</a> ·
  <a href="#직접-설치하기">SDK 선택</a> ·
  <a href="#하나의-흐름으로-연결하기">연결 원리</a> ·
  <a href="#키와-보안-경계">보안</a> ·
  <a href="#문서와-도움말">문서</a>
</p>

> AI 호출은 서버에서 일어나지만, 그 결과에 대한 사용자의 반응은 제품에서 일어납니다. ABTO SDK는 두 흐름을 `device_id`, `trace_id`, `request_id`로 연결합니다.

```text
사용자 행동 ── Event SDK ───────────────┐
                                        ├── ABTO ── 비용 · 지연 · 품질
LLM 요청 ──── Calling SDK ── Gateway ──┘
                 device_id · trace_id · request_id
```

## 가장 빠른 시작

### 코딩 에이전트에게 맡기기

ABTO Skill은 프로젝트의 런타임과 패키지 매니저를 확인하고, 필요한 SDK만 골라 설치한 뒤 빌드와 최소 연동 검증까지 진행합니다. Skill 설치에는 Node.js 22.20 이상이 필요합니다.

#### Codex

```bash
npx --yes skills@1.5.20 add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent codex \
  --copy \
  --yes
```

#### Claude Code

```bash
npx --yes skills@1.5.20 add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent claude-code \
  --copy \
  --yes
```

새 에이전트 세션을 열고 이렇게 요청하세요.

```text
이 프로젝트에 ABTO를 연동하고 실제 데이터 수신까지 검증해줘.
```

에이전트는 Event Key와 Calling Key를 올바른 실행 환경에 배치하도록 안내하며, 실제 키나 권한이 필요한 단계에서는 사용자 확인을 기다립니다. 설치 확인·업데이트·삭제 방법은 [ABTO Skill 설치 가이드](./abto/references/skill-installation.md)에 있습니다.

## 직접 설치하기

역할과 실행 환경에 맞는 SDK 하나부터 시작하세요. 브라우저나 앱에서 사용자 행동을 관측하려면 **Event SDK**, 서버에서 모델을 호출하려면 **Calling SDK**를 사용합니다.

| 실행 환경 | 역할 | 패키지 | 설치 | 상태 |
| --- | --- | --- | --- | --- |
| Browser JavaScript | 이벤트·자동 수집 | [`@abto-app/event`](https://www.npmjs.com/package/@abto-app/event) | `npm install @abto-app/event` | 사용 가능 |
| Node.js | Gateway 호출·요청 문맥 | [`@abto-app/calling`](https://www.npmjs.com/package/@abto-app/calling) | `npm install @abto-app/calling openai` | 사용 가능 |
| Python | Gateway 호출·요청 문맥 | [`abto`](https://pypi.org/project/abto/) | `python -m pip install "abto[openai]"` | 사용 가능 |
| Flutter / Dart | 앱 이벤트 | [`abto`](https://pub.dev/packages/abto) | `dart pub add abto` | 사용 가능 |
| Android / Kotlin | 앱 이벤트 | [`packages/mobile/android`](./packages/mobile/android) | Maven Central 공개 배포 준비 중 | 준비 중 |
| iOS / macOS | 앱 이벤트 | [`AbtoApp`](./packages/mobile/swift) | Swift Package Manager | 사용 가능 |

Swift Package Manager에서는 다음 패키지를 추가합니다.

```swift
.package(
    url: "https://github.com/greedy-co/abto-sdk.git",
    from: "0.1.1"
)
```

> Android SDK는 소스가 공개되어 있지만 Maven Central 배포 전입니다. 공개 좌표를 추측하거나 소스를 앱에 직접 복사하지 마세요. Flutter Web은 현재 Dart SDK가 지원하지 않으므로 Browser JavaScript SDK를 사용하세요.

## 하나의 흐름으로 연결하기

ABTO는 클라이언트 이벤트와 서버의 모델 호출을 같은 식별자로 이어 봅니다.

1. 클라이언트의 안정적인 `device_id`를 서버 요청에도 전달합니다.
2. 제품 기능을 `support.reply` 같은 점 표기 `nodeKey`로 구분합니다.
3. 한 번의 사용자 행동에서 발생한 모델 호출은 같은 `trace_id`로 묶습니다.
4. Gateway 응답의 `x-request-id`를 화면에 표시된 결과와 사용자 반응에 연결합니다.

Gateway는 provider 실행, token 사용량, 비용, 지연, 재시도, variant 배정과 `request_id`의 정본입니다. Event SDK나 Calling SDK에서 이 값을 따로 계산하지 않습니다.

| 구성 요소 | 하는 일 | 하지 않는 일 |
| --- | --- | --- |
| Event SDK | 사용자 행동, 제품 이벤트, 응답 결과 수집 | provider 호출, 비밀키 보관 |
| Calling SDK | LLM 요청을 Gateway로 전달하고 요청 문맥 전파 | 브라우저 이벤트 수집 |
| ABTO Skill | SDK 선택, 설치, 설정, 검증 자동화 | 키 생성, 사용자 승인 없는 비밀 변경 |

## 키와 보안 경계

| 키 | 클라이언트 번들 | 용도 |
| --- | :---: | --- |
| Event Key (`ek-abto-…`) | 허용 | 브라우저·앱 이벤트 수집 |
| Calling Key (`ck-abto-…`) | 금지 | 서버의 Gateway 인증 |
| Provider key | 금지 | upstream provider 인증 |

Calling Key와 provider key는 서버의 비밀 저장소에만 보관하세요. Browser Event SDK의 기본 privacy 설정은 prompt·response를 메타데이터 수준으로 다루며, DOM 텍스트와 입력값은 마스킹합니다. 전체 콘텐츠 수집은 데이터 정책을 검토하고 명시적으로 승인한 경우에만 활성화하세요.

## 저장소 구조와 릴리스

```text
packages/
├── browser/javascript/   # @abto-app/event
├── server/
│   ├── javascript/       # @abto-app/calling
│   └── python/           # abto
└── mobile/
    ├── dart/             # abto
    ├── android/          # 공개 배포 준비 중
    └── swift/            # AbtoApp

abto/
├── SKILL.md              # 통합 Agent Skill
└── references/           # 런타임별 연동·검증 가이드
```

같은 `major.minor` 버전의 SDK는 같은 capability contract를 구현합니다. 각 SDK의 patch 버전과 release tag는 독립적으로 올라갑니다. 예: `event-js-v0.1.1`, `calling-python-v0.1.3`, `swift-v0.1.1`.

## 문서와 도움말

| 항목 | 링크 |
| --- | --- |
| 전체 문서 | [docs.abto.app](https://docs.abto.app/) |
| Browser JavaScript | [설치 및 API 가이드](https://docs.abto.app/sdk/javascript/browser/) |
| Node.js | [설치 및 API 가이드](https://docs.abto.app/sdk/javascript/server/) |
| Python | [설치 및 API 가이드](https://docs.abto.app/sdk/python/) |
| Flutter / Dart | [설치 및 API 가이드](https://docs.abto.app/sdk/flutter/) |
| Android / Kotlin | [공개 배포 상태](https://docs.abto.app/sdk/android/) |
| iOS / macOS | [설치 및 API 가이드](https://docs.abto.app/sdk/ios/) |
| 문제 제보 | [GitHub Issues](https://github.com/greedy-co/abto-sdk/issues) |

기여할 때는 변경할 SDK 디렉터리의 README와 테스트 명령을 먼저 확인해 주세요. 모든 pull request는 공개 저장소 안전성 검사를 거치며, SDK 변경에는 해당 런타임의 검증이 추가로 실행됩니다.

## 라이선스

이 저장소의 SDK 소스는 [MIT License](./LICENSE)로 배포됩니다.
