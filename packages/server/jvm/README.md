# ABTO Calling SDK for Java and Kotlin

Java 17+에서 ABTO Gateway의 비스트리밍 Chat Completions와 Responses를 사용합니다. 공식 OpenAI Java 타입을 재사용하고, 요청별 식별·인증·선택적 fallback을 같은 전송 정책으로 처리합니다. 모델·프롬프트·A/B 정책은 Gateway가 담당합니다.

## 설치

Maven Central에서 사용 경로에 맞는 패키지 하나를 선택하세요. 다섯 패키지는 같은 버전으로 발행하며 core는 전이 의존성으로 설치됩니다.

| 좌표 | 용도 |
| --- | --- |
| `app.abto:abto-calling-core` | 순수 JDK HTTP, 설정·컨텍스트·fallback |
| `app.abto:abto-calling` | 공식 OpenAI Java 동기·비동기 클라이언트 |
| `app.abto:abto-calling-spring-ai-1` | Spring AI 1.1 / Boot 3 |
| `app.abto:abto-calling-spring-ai-2` | Spring AI 2.0 / Boot 4 |
| `app.abto:abto-calling-langchain4j` | LangChain4j, LangGraph4j |

```kotlin
repositories { mavenCentral() }
dependencies { implementation("app.abto:abto-calling:1.2.2") }
```

```xml
<dependency>
  <groupId>app.abto</groupId>
  <artifactId>abto-calling</artifactId>
  <version>1.2.2</version>
</dependency>
```

Spring AI 1과 2 어댑터는 서로 다른 애플리케이션에서 사용하세요. 기본 `abto-calling`에는 Spring·LangChain 의존성이 없습니다.

## Java: 클라이언트 생성

서버 환경에 `ABTO_API_KEY`, `ABTO_GATEWAY_BASE_URL`, 사용할 provider의 `OPENAI_API_KEY` 등을 설정합니다. Gateway 주소는 Dashboard에서 확인한 Chat Completions base URL을 사용합니다. 키는 서버에서만 보관하세요.

```java
import app.abto.calling.*;
import app.abto.calling.openai.AbtoOpenAI;
import com.openai.models.chat.completions.ChatCompletionCreateParams;

var config = AbtoConfig.builder().build();
try (var abto = AbtoOpenAI.create(config)) {
    var client = abto.forContext(AbtoContext.builder("support.reply").deviceId("device-id").build()).openai();
    var completion = client.chat().completions().create(
        ChatCompletionCreateParams.builder()
            .model("gpt-4o-mini").addUserMessage("Hello").build());
    System.out.println(completion.choices().get(0).message().content());
}
```

애플리케이션 수명 동안 root `abto` 하나를 유지하고 요청마다 불변 `forContext`를 만드세요. 연결 풀과 circuit은 공유됩니다. `featureId`, `nodeId`, `deviceId`, `traceId`는 요청 컨텍스트이고(`AbtoContext.builder(featureId).nodeId(..).deviceId(..).traceId(..).build()`, 기능 ID만 있으면 `AbtoContext.of(featureId)`), Calling Key·provider key·Gateway 주소는 공통 설정입니다. `traceId`는 에이전트나 워크플로 실행 한 번이 만든 호출을 묶는 실행 ID로 `x-abto-trace-id`로 전송됩니다. `AbtoContext`를 만들 때 넣지 않으면 새 값이 생기므로 실행 하나 동안 같은 context를 재사용하고, 노드를 바꿀 때는 `withNodeId(..)`로 같은 실행을 이어 가며, 다른 서비스가 넘겨준 실행을 이어 갈 때만 `.traceId(..)`로 넣습니다. `withContext(context, scope -> ...)`는 동기 콜백 편의 기능이며 비동기 경계에서는 `forContext`를 명시적으로 전달합니다.

## Java: 기존 클라이언트 설정

공식 SDK의 `withOptions`는 숨겨진 transport의 redirect 정책을 노출하지 않습니다. 따라서 config 경로는 **안전한 JDK transport를 명시적으로 받습니다**. 해당 풀·proxy·TLS·executor는 유지되며 실제 키는 전송 직전에 주입됩니다.

```java
var transport = java.net.http.HttpClient.newBuilder()
    .followRedirects(java.net.http.HttpClient.Redirect.NEVER)
    .connectTimeout(java.time.Duration.ofSeconds(5))
    .build();
try (var abto = AbtoOpenAI.create(config, transport)) {
    var scope = abto.forContext(AbtoContext.of("support.reply"));
    var configured = existingClient.withOptions(scope.openaiOptions(transport));
    configured.chat().completions().create(params);
}
```

`existingClient`의 retry 횟수·전체 요청 timeout·사용자 헤더·로깅 설정은 유지됩니다. HTTP 전송은 명시한 JDK transport로 교체됩니다. 기존 OkHttp 전용 interceptor 등은 자동 복사되지 않습니다. redirect, CookieHandler, Authenticator가 활성화된 JDK transport는 거부합니다. JDK 연결 timeout은 transport builder에서 설정하세요. 더 짧은 개별 read/write timeout이나 다른 개별 connect timeout은 지원하지 않으므로 오류로 안내합니다.

`AbtoOpenAI.create(config, existingClient, transport)`로 기존 옵션을 factory 경로에서도 재사용할 수 있습니다. 빌린 클라이언트·풀은 고객이 종료합니다. SDK가 만든 풀은 root facade의 `close()`로 종료하며, JDK 17에서는 JDK API 특성상 참조 해제 후 정리됩니다. 요청별 facade와 반환된 클라이언트의 `close()`는 빌린 자원을 닫지 않습니다.

## Kotlin: 생성·설정·코루틴

```kotlin
val config = AbtoConfig.builder().build()
AbtoOpenAI.create(config, safeJdkTransport).use { abto ->
    val cancellation = AbtoCancellation()
    val scope = abto.forContext(AbtoContext.builder("support.reply").deviceId("device-id").build())
        .withCancellation(cancellation)
    val params = ChatCompletionCreateParams.builder()
        .model("gpt-4o-mini").addUserMessage("Hello").build()
    val result = cancellation.bind(
        scope.openai().async().chat().completions().create(params)
    ).await() // kotlinx.coroutines.future.await
    // 같은 정책을 기존 클라이언트에 적용
    val configured = existingClient.withOptions(
        abto.forContext(AbtoContext.of("support.reply")).openaiOptions(safeJdkTransport)
    )
}
```

공식 OpenAI Future 자체의 `cancel()`은 HTTP 취소를 전달하지 않습니다. 비동기 요청마다 `AbtoCancellation`을 만들고 반환 Future를 `bind`하세요. bound Future의 취소, 코루틴 취소 또는 `cancellation.cancel()`은 실제 HTTP 요청과 circuit probe를 해제합니다. 취소된 핸들은 재사용하지 않습니다.

실행 가능한 [Java 예제](examples/java/src/main/java/example/JavaExample.java)와 [Kotlin 예제](examples/kotlin/src/main/kotlin/example/KotlinExample.kt)를 참고하세요.

## Spring AI 1.1

```java
var scoped = abtoSpringAI1.forContext(AbtoContext.of("support.reply"));
var api = OpenAiApi.builder();
scoped.openAiApiOptions(existingRestClientBuilder).accept(api);
scoped.chatModelOptions(api.build()).accept(existingChatModelBuilder);
var model = existingChatModelBuilder.build();
```

`AbtoSpringAI1.create(config, safeJdkTransport)` 또는 소유 transport를 만드는 `create(config)`로 초기화합니다. RestClient builder를 복제하고 request factory를 교체하므로 interceptors·observation 설정은 유지됩니다. 기존 request factory 전용 설정은 명시한 JDK transport로 옮기세요. 모델 옵션·tool manager·retry template·ObservationRegistry는 고객 builder에 남습니다. 간단한 생성 경로는 `scoped.chatModel()`입니다.

[Boot 3 실행 예제](examples/spring-ai-1/src/main/java/example/SpringAI1Example.java)와 [Kotlin 설정 예제](examples/spring-ai-1/src/main/kotlin/example/FrameworkKotlinExample.kt)를 참고하세요.

## Spring AI 2.0

```java
var scoped = abtoSpringAI2.forContext(AbtoContext.of("support.reply"));
scoped.chatModelOptions().accept(existingChatModelBuilder);
var model = existingChatModelBuilder.build();
```

`AbtoSpringAI2.create(config)` 또는 명시적 JDK transport overload를 사용합니다. 공식 OpenAI 동기·비동기 클라이언트만 주입하며 기존 model options·tool 설정·ObservationRegistry를 유지합니다. `withCancellation`과 root `close`도 제공합니다.

[Boot 4 실행 예제](examples/spring-ai-2/src/main/java/example/SpringAI2Example.java)와 [Kotlin 설정 예제](examples/spring-ai-2/src/main/kotlin/example/FrameworkKotlinExample.kt)를 참고하세요. Kotlin에서도 같은 builder에 `.accept(builder)`를 호출합니다.

## LangChain4j · LangGraph4j

```java
var abto = AbtoLangChain4j.create(config, java.net.http.HttpClient.newBuilder()
    .followRedirects(java.net.http.HttpClient.Redirect.NEVER));
var scope = abto.forContext(AbtoContext.builder("graph.answer").deviceId("device-id").build());
scope.openAiOptions().accept(existingOpenAiChatModelBuilder);
var model = existingOpenAiChatModelBuilder.build();
```

기존 listeners·모델 옵션·tool 설정·retry 횟수를 유지합니다. factory는 `scope.openAiChatModel()`입니다. 공유 JDK 풀을 처음 만들 때 LangChain4j의 connect timeout을 적용합니다. 같은 root에서 다른 connect timeout을 사용하면 명확한 오류가 발생합니다. 다른 사용자 정의 HTTP 구현은 지원 대상으로 검증하지 않았습니다.

LangGraph4j는 노드에서 이 모델을 호출하고 요청별 `AbtoContext`를 명시적으로 전달하면 됩니다. 그래프·상태·체크포인트를 교체하지 않습니다. [실행 예제](examples/langchain4j/src/main/java/example/LangChainExample.java)는 그래프 호출까지 포함합니다.

## 순수 HTTP

```java
var http = AbtoHttpClient.wrap(safeJdkTransport,
    new AbtoGateway(config).forContext(AbtoContext.of("support.http")));
var request = java.net.http.HttpRequest.newBuilder(
        config.gatewayBaseUrl().resolve("chat/completions"))
    .header("Content-Type", "application/json")
    .POST(java.net.http.HttpRequest.BodyPublishers.ofString(json))
    .build();
var response = http.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
```

Kotlin은 같은 API의 `send` 또는 `sendAsync(...).await()`를 사용합니다. fallback을 사용하는 요청 body publisher는 재생 가능해야 합니다. `ofString`·`ofByteArray`를 사용하세요.

## Fallback과 인증

Fallback은 목적지를 명시했을 때만 활성화됩니다.

```java
var config = AbtoConfig.builder()
    .apiKey(() -> secretStore.callingKey())
    .providerKey("openai", () -> secretStore.openAiKey())
    .gatewayBaseUrl(gatewayUrl)
    .fallback(AbtoFallback.builder().baseUrl("https://api.openai.com/v1").build())
    .build();
```

직접 호출은 Chat Completions와 Responses 경로에서 원래 본문을 그대로 사용합니다. Responses 요청은 앱이 보낸 `store` 값 그대로 나가므로, 생략하면 OpenAI 기본값대로 응답이 저장됩니다. Gateway를 거친 요청은 OpenAI에 항상 `store: false`로 나갑니다([Gateway Responses](https://docs.abto.app/gateway/responses/)).

키 공급자는 매 요청 전송 시 평가됩니다. config의 `toString()`과 framework 설정에는 실제 키를 넣지 않습니다. 허용 Gateway 목적지와 예약 헤더를 검사하며 직접 호출에서 ABTO 키·provider 후보 키·쿠키를 제거합니다.

명확한 연결 실패·Gateway 수용 거절에서만 직접 호출합니다. provider 오류·불명확한 연결 단절·호출자 취소는 fallback하지 않습니다. timeout 재실행은 `.onTimeout(true)`라는 명시적 opt-in이며 중복 실행 가능성을 고려해야 합니다. SDK 자체 retry loop는 없고 공식 SDK·framework의 retry 정책이 그대로 적용됩니다. circuit은 30초 후 단일 복구 probe를 허용합니다.

## Tool calling · structured output · 관측

공식 `ChatCompletionCreateParams`의 tools, tool 결과 메시지, `ResponseFormatJsonSchema`를 그대로 사용합니다. ABTO는 본문의 모델·프롬프트·옵션을 임의 변경하지 않습니다. raw response 경로의 상태·본문·헤더도 유지합니다.

기존 Langfuse의 Micrometer/OpenTelemetry exporter·LangChain4j listeners를 유지하세요. ABTO는 전역 tracing 설정이나 exporter를 등록하지 않습니다. 기존 `traceparent`·`tracestate`는 보존하고, 필요한 경우 `AbtoContext.builder(feature).deviceId(device).traceparent(traceparent).tracestate(tracestate).build()`로 명시합니다. exporter의 HTTP 헤더 수집에서 인증 헤더를 제외하세요.

고객 tracing에 기록되는 입력은 Gateway 정책 적용 전의 요청일 수 있습니다. 실제 실행 모델·프롬프트·비용은 Gateway 실행 기록을 기준으로 확인하세요. 로컬 OTLP 수집기까지의 trace 연결·callback·키 비노출은 테스트하며, 실제 Langfuse 계정 수신은 별도 운영 검증입니다. [Langfuse Spring AI 안내](https://langfuse.com/integrations/frameworks/spring-ai).

## 지원 및 검증

지원 범위는 **비스트리밍 Chat Completions와 Responses**입니다. Responses는 공식 OpenAI Java client에서 쓸 수 있고, Spring AI와 LangChain4j 연동은 Chat Completions만 사용합니다. 토큰 스트리밍, embeddings, 자체 agent 실행기는 포함하지 않습니다. RAG embeddings는 기존 별도 클라이언트를 유지하세요.

| 대상 | 고정 검증 조합 |
| --- | --- |
| Java | 17 · 21 · 25 |
| Kotlin | 2.3.21, 코루틴 1.10.2 |
| OpenAI Java | 4.49.0 · 4.81.0 |
| Spring AI 1 | 1.1.8 + Boot 3.4.13 · 3.5.16 |
| Spring AI 2 | 2.0.1 + Boot 4.0.8 · 4.1.1 |
| LangChain4j / LangGraph4j | 1.22.0 / 1.9.5 |
| 소비 빌드 | Maven 3.9.11 · Gradle 9.3.0 |

CI 조합은 Java 17 / OpenAI 4.49.0 / Boot 3.4.13·4.0.8, Java 21 / OpenAI 4.49.0 / Boot 3.5.16·4.1.1, Java 25 / OpenAI 4.81.0 / Boot 3.5.16·4.1.1입니다. 다른 버전 전체의 호환성을 보장하지 않습니다. [예제 검증 방법](examples/README.md)에서 소스 참조 없는 Maven·Gradle 소비와 로컬 fixture 실행 방법을 확인할 수 있습니다.

## 소스 빌드

Java 17과 Gradle 9.3.0으로 이 디렉터리에서 실행합니다. 생성된 공통 계약 상수도 공개 소스에 포함되므로 별도 내부 도구가 필요하지 않습니다.

```sh
gradle build publishAllPublicationsToCentralBundleRepository --no-daemon
```

Sources·Javadoc·POM을 포함한 다섯 Maven artifact가 `build/central-staging`에 생성됩니다.
