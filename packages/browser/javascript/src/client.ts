import { installAutocapture, type AutocaptureHit } from './autocapture.js';
import { ContextStore } from './context.js';
import { BrowserDiagnostics } from './diagnostics.js';
import {
  validateCustomEventName,
  validateCustomPropertyNames,
  validateEventProperties,
  type EventRegistry,
} from './event-registry.js';
import type { BrowserIdentity } from './identity.js';
import { derivePromptMeta } from './privacy.js';
import { Transport } from './transport.js';
import type {
  AbtoBrowserConfig,
  AIInteractionType,
  BrowserSystemEventName,
  BrowserSystemEventPropsMap,
  CapturedEvent,
  CommonProperties,
  CustomEventProperties,
  Environment,
  EventNameFor,
  EventPropertiesFor,
  LlmTrace,
  PromptMetadata,
  RequestIdSource,
  ResolvedConfig,
  ResponseInteractionMetadata,
  ResponseRenderedMetadata,
  TraceHeaders,
} from './types.js';
import { ABTO_SCHEMA_VERSION as SCHEMA_VERSION } from './types.js';
import { ABTO_AI_INTERACTION_TYPES, isAIInteractionType } from './system-events.generated.js';
import { newUuidV7 } from './uuid.js';

const SDK_VERSION = '0.4.0';

function requireProjectKey(value: string | undefined): void {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error('[abto] projectKey is required. Check your init config.');
  }
}

function requireValidApiHost(value: string): void {
  let parsed: URL | undefined;
  try {
    parsed = new URL(value);
  } catch {
    // Handled by the common validation below.
  }
  if (parsed === undefined || (parsed.protocol !== 'http:' && parsed.protocol !== 'https:')) {
    throw new Error(`[abto] apiHost is not a valid http(s) URL: "${value}"`);
  }
}

function resolveConfig<R extends EventRegistry>(config: AbtoBrowserConfig<R>): ResolvedConfig<R> {
  requireProjectKey(config.projectKey);
  const apiHost = config.apiHost ?? 'https://api.abto.app';
  requireValidApiHost(apiHost);
  const endpoint = `${apiHost.replace(/\/$/, '')}/v1/collect/events`;
  const environment: Environment =
    config.environment === 'development' ? 'development' : 'production';
  return {
    endpoint,
    projectKey: config.projectKey,
    environment,
    appVersion: config.appVersion,
    events: (config.events ?? {}) as R,
    capturePrompt: config.capture?.prompt ?? 'metadata_only',
    captureResponse: config.capture?.response ?? 'metadata_only',
    mask: config.capture?.mask ?? 'all',
    autocapture: config.autocapture?.enabled ?? false,
  };
}

function compact<T extends Record<string, unknown>>(input: T): Record<string, unknown> {
  const output: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    if (value !== undefined) output[key] = value;
  }
  return output;
}

function normalizeRequestId(value: string | null | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed === '' ? undefined : trimmed;
}

function readHeader(source: RequestIdSource, name: string): string | undefined {
  if (source === null || source === undefined || typeof source === 'string') return undefined;
  if ('headers' in source && typeof source.headers !== 'string') return readHeader(source.headers, name);
  if ('get' in source && typeof source.get === 'function') return normalizeRequestId(source.get(name));
  const record = source as Record<string, string | null | undefined>;
  const exact = normalizeRequestId(record[name]);
  if (exact !== undefined) return exact;
  const lower = name.toLowerCase();
  for (const [key, value] of Object.entries(record)) {
    if (key.toLowerCase() === lower) return normalizeRequestId(value);
  }
  return undefined;
}

function readRequestId(source: RequestIdSource): string | undefined {
  if (typeof source === 'string') return normalizeRequestId(source);
  return readHeader(source, 'x-abto-request-id');
}

function contextProperties(
  common: CommonProperties,
  config: ResolvedConfig,
): CustomEventProperties {
  return compact({
    $lib: 'web',
    $lib_version: SDK_VERSION,
    $app_version: config.appVersion,
    $environment: config.environment,
    $schema_version: SCHEMA_VERSION,
    $tenant_id: common.tenant_id,
    $user_id: common.user_id,
    $device_id: common.device_id,
    $anonymous_id: common.anonymous_id,
    $session_id: common.session_id,
    $window_id: common.window_id,
    $pageview_id: common.pageview_id,
    $feature_id: common.feature_id,
    $trace_id: common.trace_id,
    $request_id: common.request_id,
    $response_id: common.response_id,
    $surface: common.surface,
    $conversation_id: common.conversation_id,
    $message_id: common.message_id,
    $prompt_template_id: common.prompt_template_id,
  }) as CustomEventProperties;
}

class BrowserLlmTrace implements LlmTrace {
  requestId?: string;

  constructor(
    private readonly client: AbtoBrowserClient<any>,
    readonly traceId: string,
    private readonly emitSystem: <N extends BrowserSystemEventName>(
      event: N,
      properties: BrowserSystemEventPropsMap[N],
      envelope?: Partial<CommonProperties>,
    ) => void,
  ) {}

  attachRequestId(source: RequestIdSource): string | undefined {
    const requestId = readRequestId(source);
    if (requestId !== undefined) this.requestId = requestId;
    return requestId;
  }

  // The trace id is not carried: the Gateway does not read it yet, so relaying it
  // to the backend cannot reach the call record. Browser events already join on the
  // trace_id in their own envelope, so dropping this hop leaves analytics unchanged.
  getHeaders(): TraceHeaders {
    return {
      'x-abto-device-id': this.client.getIdentity().deviceId,
    };
  }

  async submitPrompt(metadata: PromptMetadata = {}): Promise<void> {
    const mode = metadata.promptCaptureMode ?? this.client.config.capturePrompt;
    const derived =
      mode !== 'full' && metadata.prompt !== undefined
        ? await derivePromptMeta(metadata.prompt, mode, this.client.config.projectKey)
        : undefined;
    this.emitSystem(
      '$ai_prompt_submitted',
      compact({
        $capture_mode: mode,
        $prompt_text: mode === 'full' ? metadata.prompt : undefined,
        $prompt_hash: metadata.promptHash ?? derived?.hash,
        $prompt_length_chars: metadata.promptLengthChars ?? derived?.lengthChars,
        $prompt_tokens_estimated: metadata.promptTokensEstimated,
        $language: metadata.language,
        $contains_attachment: metadata.containsAttachment,
        $contains_code: metadata.containsCode ?? derived?.containsCode,
        $pii_detected: metadata.piiDetected ?? derived?.piiDetected,
        $sensitive_category: metadata.sensitiveCategory ?? derived?.sensitiveCategory ?? undefined,
      }) as unknown as BrowserSystemEventPropsMap['$ai_prompt_submitted'],
      this.envelope(),
    );
  }

  async markResponseRendered(metadata: ResponseRenderedMetadata): Promise<void> {
    const requestId = metadata.requestId ?? this.requestId;
    this.client.bindResponseRequestId(metadata.responseId, requestId);
    const mode = metadata.responseCaptureMode ?? this.client.config.captureResponse;
    this.emitSystem(
      '$ai_response_rendered',
      compact({
        $capture_mode: mode,
        $response_id: metadata.responseId,
        $response_text: mode === 'full' ? metadata.responseText : undefined,
        $time_to_render_ms: metadata.timeToRenderMs,
        $output_length_chars:
          metadata.outputLengthChars ?? (mode === 'off' ? undefined : metadata.responseText?.length),
        $visible_output_ratio: metadata.visibleOutputRatio,
      }) as unknown as BrowserSystemEventPropsMap['$ai_response_rendered'],
      this.envelope(
        compact({ response_id: metadata.responseId, request_id: requestId }) as Partial<CommonProperties>,
      ),
    );
  }

  async captureResponseInteraction(
    type: AIInteractionType,
    metadata: ResponseInteractionMetadata = {},
  ): Promise<void> {
    if (!isAIInteractionType(type)) {
      console.warn(
        `[abto] response interaction was dropped: type must be one of ${ABTO_AI_INTERACTION_TYPES.join(', ')}. Use a custom event for other product actions.`,
      );
      return;
    }
    const requestId = metadata.requestId ?? this.requestId;
    this.emitSystem(
      '$ai_response_interacted',
      compact({
        $interaction_type: type,
        $response_id: metadata.responseId,
        $request_id: requestId,
        $time_since_response_ms: metadata.timeSinceResponseMs,
        $visible_output_ratio: metadata.visibleOutputRatio,
        $source: metadata.source,
        $destination: metadata.destination,
      }) as unknown as BrowserSystemEventPropsMap['$ai_response_interacted'],
      this.envelope(
        compact({ response_id: metadata.responseId, request_id: requestId }) as Partial<CommonProperties>,
      ),
    );
  }

  private envelope(overrides: Partial<CommonProperties> = {}): Partial<CommonProperties> {
    return {
      trace_id: this.traceId,
      ...overrides,
    };
  }
}

class AbtoBrowserClient<R extends EventRegistry = EventRegistry> {
  readonly config: ResolvedConfig<R>;
  private readonly context: ContextStore;
  private readonly transport: Transport;
  private detachAutocapture: (() => void) | null = null;
  private readonly responseRequestIds = new Map<string, string>();

  constructor(config: AbtoBrowserConfig<R>) {
    this.config = resolveConfig(config);
    const diagnostics = new BrowserDiagnostics();
    this.context = new ContextStore(this.config.projectKey, diagnostics);
    this.transport = new Transport(this.config, diagnostics);
    if (this.config.autocapture) {
      this.detachAutocapture = installAutocapture(
        (hit) => this.onAutocapture(hit),
        this.config.mask,
      );
    }
  }

  identify(userId: string, tenantId?: string): void {
    this.context.identify(userId, tenantId);
  }

  reset(): void {
    this.context.reset();
    this.responseRequestIds.clear();
  }

  forgetDevice(): void {
    this.transport.discard();
    this.context.forgetDevice();
    this.responseRequestIds.clear();
  }

  getIdentity(): BrowserIdentity {
    return this.context.getIdentity();
  }

  startLlmTrace(): LlmTrace {
    return new BrowserLlmTrace(
      this,
      newUuidV7().replace(/-/g, ''),
      (event, properties, envelope) => this.#captureSystem(event, properties, envelope),
    );
  }

  bindResponseRequestId(responseId: string, requestId: string | undefined): void {
    if (requestId === undefined) return;
    if (!this.responseRequestIds.has(responseId) && this.responseRequestIds.size >= 1000) {
      const oldest = this.responseRequestIds.keys().next().value;
      if (oldest !== undefined) this.responseRequestIds.delete(oldest);
    }
    this.responseRequestIds.set(responseId, requestId);
  }

  capture<N extends EventNameFor<R>>(event: N, properties: EventPropertiesFor<R, N>): void {
    const name = event as string;
    const eventNameIssue = validateCustomEventName(name);
    if (eventNameIssue !== undefined) {
      console.warn(`[abto] custom event name "${name}" ${eventNameIssue}.`);
      return;
    }

    const reservedPropertyIssues = validateCustomPropertyNames(
      properties as Record<string, unknown>,
    );
    if (reservedPropertyIssues.length > 0) {
      console.warn(`[abto] custom event "${name}" schema drift: ${reservedPropertyIssues.join('; ')}`);
      return;
    }

    const definition = this.config.events[name];
    if (definition === undefined) {
      if (this.config.environment === 'production') {
        console.warn(`[abto] custom event "${name}" is not registered and was dropped.`);
        return;
      }
      console.warn(`[abto] Discovered unregistered custom event "${name}" in development.`);
      this.emit(name, properties as CustomEventProperties);
      return;
    }

    const result = validateEventProperties(definition, properties as Record<string, unknown>);
    if (!result.valid) {
      const message = `[abto] custom event "${name}" schema drift: ${result.issues.join('; ')}`;
      console.warn(message);
      if (this.config.environment === 'production') return;
    }
    this.emit(name, properties as CustomEventProperties);
  }

  #captureSystem<N extends BrowserSystemEventName>(
    event: N,
    properties: BrowserSystemEventPropsMap[N],
    envelope: Partial<CommonProperties> = {},
  ): void {
    this.emit(event, properties as unknown as CustomEventProperties, envelope);
  }

  flush(): Promise<void> {
    return this.transport.flush();
  }

  shutdown(): void {
    this.detachAutocapture?.();
    this.detachAutocapture = null;
    void this.transport.flush(true);
    this.transport.shutdown();
  }

  private emit(
    event: string,
    properties: CustomEventProperties,
    envelope: Partial<CommonProperties> = {},
  ): void {
    const common = { ...this.context.toCommonProperties(), ...envelope };
    const captured: CapturedEvent = {
      uuid: newUuidV7(),
      event,
      timestamp: new Date().toISOString(),
      distinct_id: common.user_id ?? common.anonymous_id ?? common.device_id ?? newUuidV7(),
      properties: {
        ...properties,
        ...contextProperties(common, this.config),
      },
    };
    if (this.config.environment === 'development') console.log('[abto]', captured.event, captured);
    this.transport.enqueue(captured);
  }

  private onAutocapture(hit: AutocaptureHit): void {
    if (hit.kind === 'pageview') {
      const currentUrl = new URL(hit.path, globalThis.location?.href ?? 'https://localhost/').href;
      if (hit.eventType === 'pageview') {
        this.context.newPageview();
        this.#captureSystem('$pageview', {
          $current_url: currentUrl,
          $pathname: hit.path,
          ...(hit.referrer !== undefined ? { $referrer: hit.referrer } : {}),
        });
      } else {
        const scroll = hit.scroll;
        this.#captureSystem('$pageleave', {
          $current_url: currentUrl,
          $pathname: hit.path,
          ...(hit.durationMs !== undefined ? { $duration_ms: hit.durationMs } : {}),
          ...(scroll?.last_scroll_y !== undefined ? { $last_scroll_y: scroll.last_scroll_y } : {}),
          ...(scroll?.last_scroll_percentage !== undefined
            ? { $last_scroll_percentage: scroll.last_scroll_percentage }
            : {}),
          ...(scroll?.max_scroll_y !== undefined ? { $max_scroll_y: scroll.max_scroll_y } : {}),
          ...(scroll?.max_scroll_percentage !== undefined
            ? { $max_scroll_percentage: scroll.max_scroll_percentage }
            : {}),
          ...(scroll?.last_content_y !== undefined ? { $last_content_y: scroll.last_content_y } : {}),
          ...(scroll?.last_content_percentage !== undefined
            ? { $last_content_percentage: scroll.last_content_percentage }
            : {}),
          ...(scroll?.max_content_y !== undefined ? { $max_content_y: scroll.max_content_y } : {}),
          ...(scroll?.max_content_percentage !== undefined
            ? { $max_content_percentage: scroll.max_content_percentage }
            : {}),
        });
        if (hit.unload) void this.transport.flush(true);
      }
      return;
    }

    if (hit.kind === 'signal') {
      if (hit.eventType === 'rageclick') {
        this.#captureSystem(
          '$rageclick',
          compact({
            $elements_chain: hit.elementsChain,
            $click_count: hit.clickCount,
          }) as unknown as BrowserSystemEventPropsMap['$rageclick'],
        );
      } else {
        this.#captureSystem('$dead_click', { $elements_chain: hit.elementsChain });
      }
      return;
    }

    const target = hit.target;
    const requestId =
      target.request_id ??
      (target.response_id ? this.responseRequestIds.get(target.response_id) : undefined);
    const envelope = compact({
      surface: target.surface,
      feature_id: target.feature_id,
      request_id: requestId,
      response_id: target.response_id,
      conversation_id: target.conversation_id,
      message_id: target.message_id,
      prompt_template_id: target.template_id,
    }) as Partial<CommonProperties>;

    this.#captureSystem(
      '$autocapture',
      compact({
        $event_type: hit.eventType,
        $ce_version: 1,
        $elements_chain: hit.elementsChain,
        $tag_name: hit.element.tag,
        $el_text: hit.element.text,
        $el_value: hit.element.value,
        $input_type: hit.element.input_type,
        $el_name: hit.element.name,
        $href: hit.element.href,
        $selection_length: hit.selectionLength,
        $ai_action: target.action || undefined,
        $response_id: target.response_id,
        $request_id: requestId,
      }) as unknown as BrowserSystemEventPropsMap['$autocapture'],
      envelope,
    );
  }
}

type AbtoBrowser<R extends EventRegistry> = Pick<
  AbtoBrowserClient<R>,
  | 'identify'
  | 'reset'
  | 'forgetDevice'
  | 'getIdentity'
  | 'startLlmTrace'
  | 'capture'
  | 'flush'
  | 'shutdown'
>;

export function initAbto<const R extends EventRegistry>(
  config: AbtoBrowserConfig<R>,
): AbtoBrowser<R> {
  return new AbtoBrowserClient(config);
}
