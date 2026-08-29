# GENERATED FILE — DO NOT EDIT.

from enum import Enum
from dataclasses import dataclass
from typing import Optional, List, Union, Any, Dict, TypeVar, Callable, Type, cast


T = TypeVar("T")
EnumT = TypeVar("EnumT", bound=Enum)


def from_bool(x: Any) -> bool:
    assert isinstance(x, bool)
    return x


def from_none(x: Any) -> Any:
    assert x is None
    return x


def from_union(fs, x):
    for f in fs:
        try:
            return f(x)
        except:
            pass
    assert False


def from_str(x: Any) -> str:
    assert isinstance(x, str)
    return x


def from_float(x: Any) -> float:
    assert isinstance(x, (float, int)) and not isinstance(x, bool)
    return float(x)


def from_list(f: Callable[[Any], T], x: Any) -> List[T]:
    assert isinstance(x, list)
    return [f(y) for y in x]


def to_enum(c: Type[EnumT], x: Any) -> EnumT:
    assert isinstance(x, c)
    return x.value


def to_float(x: Any) -> float:
    assert isinstance(x, (int, float))
    return x


def to_class(c: Type[T], x: Any) -> dict:
    assert isinstance(x, c)
    return cast(Any, x).to_dict()


def from_dict(f: Callable[[Any], T], x: Any) -> Dict[str, T]:
    assert isinstance(x, dict)
    return { k: f(v) for (k, v) in x.items() }


def from_int(x: Any) -> int:
    assert isinstance(x, int) and not isinstance(x, bool)
    return x


class CaptureMode(Enum):
    FULL = "full"
    HASH = "hash"
    METADATA_ONLY = "metadata_only"
    OFF = "off"


class SensitiveCategory(Enum):
    CREDENTIAL = "credential"
    CUSTOMER_DATA = "customer_data"
    FINANCE = "finance"
    HEALTHCARE = "healthcare"
    INTERNAL_DOCUMENT = "internal_document"
    LEGAL = "legal"
    PII = "pii"
    SOURCE_CODE = "source_code"
    UNKNOWN_SENSITIVE = "unknown_sensitive"


@dataclass
class AIPromptSubmittedProps:
    capture_mode: CaptureMode
    contains_attachment: Optional[bool] = None
    contains_code: Optional[bool] = None
    language: Optional[str] = None
    pii_detected: Optional[bool] = None
    prompt_hash: Optional[str] = None
    prompt_length_chars: Optional[float] = None
    prompt_text: Optional[str] = None
    prompt_tokens_estimated: Optional[float] = None
    sensitive_category: Optional[Union[List[SensitiveCategory], SensitiveCategory]] = None

    @staticmethod
    def from_dict(obj: Any) -> 'AIPromptSubmittedProps':
        assert isinstance(obj, dict)
        capture_mode = CaptureMode(obj.get("$capture_mode"))
        contains_attachment = from_union([from_bool, from_none], obj.get("$contains_attachment"))
        contains_code = from_union([from_bool, from_none], obj.get("$contains_code"))
        language = from_union([from_str, from_none], obj.get("$language"))
        pii_detected = from_union([from_bool, from_none], obj.get("$pii_detected"))
        prompt_hash = from_union([from_str, from_none], obj.get("$prompt_hash"))
        prompt_length_chars = from_union([from_float, from_none], obj.get("$prompt_length_chars"))
        prompt_text = from_union([from_str, from_none], obj.get("$prompt_text"))
        prompt_tokens_estimated = from_union([from_float, from_none], obj.get("$prompt_tokens_estimated"))
        sensitive_category = from_union([lambda x: from_list(SensitiveCategory, x), SensitiveCategory, from_none], obj.get("$sensitive_category"))
        return AIPromptSubmittedProps(capture_mode, contains_attachment, contains_code, language, pii_detected, prompt_hash, prompt_length_chars, prompt_text, prompt_tokens_estimated, sensitive_category)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$capture_mode"] = to_enum(CaptureMode, self.capture_mode)
        if self.contains_attachment is not None:
            result["$contains_attachment"] = from_union([from_bool, from_none], self.contains_attachment)
        if self.contains_code is not None:
            result["$contains_code"] = from_union([from_bool, from_none], self.contains_code)
        if self.language is not None:
            result["$language"] = from_union([from_str, from_none], self.language)
        if self.pii_detected is not None:
            result["$pii_detected"] = from_union([from_bool, from_none], self.pii_detected)
        if self.prompt_hash is not None:
            result["$prompt_hash"] = from_union([from_str, from_none], self.prompt_hash)
        if self.prompt_length_chars is not None:
            result["$prompt_length_chars"] = from_union([to_float, from_none], self.prompt_length_chars)
        if self.prompt_text is not None:
            result["$prompt_text"] = from_union([from_str, from_none], self.prompt_text)
        if self.prompt_tokens_estimated is not None:
            result["$prompt_tokens_estimated"] = from_union([to_float, from_none], self.prompt_tokens_estimated)
        if self.sensitive_category is not None:
            result["$sensitive_category"] = from_union([lambda x: from_list(lambda x: to_enum(SensitiveCategory, x), x), lambda x: to_enum(SensitiveCategory, x), from_none], self.sensitive_category)
        return result


class AIInteractionType(Enum):
    ABORTED = "aborted"
    ACCEPTED = "accepted"
    COLLAPSED = "collapsed"
    COPIED = "copied"
    DOWNLOADED = "downloaded"
    EXPANDED = "expanded"
    INSERTED = "inserted"
    RATED_NEGATIVE = "rated_negative"
    RATED_POSITIVE = "rated_positive"
    REGENERATED = "regenerated"
    REJECTED = "rejected"
    SHARED = "shared"


@dataclass
class AIResponseInteractedProps:
    interaction_type: AIInteractionType
    destination: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    source: Optional[str] = None
    time_since_response_ms: Optional[float] = None
    visible_output_ratio: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'AIResponseInteractedProps':
        assert isinstance(obj, dict)
        interaction_type = AIInteractionType(obj.get("$interaction_type"))
        destination = from_union([from_str, from_none], obj.get("$destination"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        source = from_union([from_str, from_none], obj.get("$source"))
        time_since_response_ms = from_union([from_float, from_none], obj.get("$time_since_response_ms"))
        visible_output_ratio = from_union([from_float, from_none], obj.get("$visible_output_ratio"))
        return AIResponseInteractedProps(interaction_type, destination, request_id, response_id, source, time_since_response_ms, visible_output_ratio)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$interaction_type"] = to_enum(AIInteractionType, self.interaction_type)
        if self.destination is not None:
            result["$destination"] = from_union([from_str, from_none], self.destination)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.source is not None:
            result["$source"] = from_union([from_str, from_none], self.source)
        if self.time_since_response_ms is not None:
            result["$time_since_response_ms"] = from_union([to_float, from_none], self.time_since_response_ms)
        if self.visible_output_ratio is not None:
            result["$visible_output_ratio"] = from_union([to_float, from_none], self.visible_output_ratio)
        return result


@dataclass
class AIResponseRenderedProps:
    capture_mode: CaptureMode
    response_id: str
    output_length_chars: Optional[float] = None
    response_text: Optional[str] = None
    time_to_render_ms: Optional[float] = None
    visible_output_ratio: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'AIResponseRenderedProps':
        assert isinstance(obj, dict)
        capture_mode = CaptureMode(obj.get("$capture_mode"))
        response_id = from_str(obj.get("$response_id"))
        output_length_chars = from_union([from_float, from_none], obj.get("$output_length_chars"))
        response_text = from_union([from_str, from_none], obj.get("$response_text"))
        time_to_render_ms = from_union([from_float, from_none], obj.get("$time_to_render_ms"))
        visible_output_ratio = from_union([from_float, from_none], obj.get("$visible_output_ratio"))
        return AIResponseRenderedProps(capture_mode, response_id, output_length_chars, response_text, time_to_render_ms, visible_output_ratio)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$capture_mode"] = to_enum(CaptureMode, self.capture_mode)
        result["$response_id"] = from_str(self.response_id)
        if self.output_length_chars is not None:
            result["$output_length_chars"] = from_union([to_float, from_none], self.output_length_chars)
        if self.response_text is not None:
            result["$response_text"] = from_union([from_str, from_none], self.response_text)
        if self.time_to_render_ms is not None:
            result["$time_to_render_ms"] = from_union([to_float, from_none], self.time_to_render_ms)
        if self.visible_output_ratio is not None:
            result["$visible_output_ratio"] = from_union([to_float, from_none], self.visible_output_ratio)
        return result


class AutocaptureEventType(Enum):
    CHANGE = "change"
    CLICK = "click"
    COPY = "copy"
    SUBMIT = "submit"


@dataclass
class AutocaptureProps:
    ce_version: float
    elements_chain: str
    event_type: AutocaptureEventType
    ai_action: Optional[str] = None
    el_name: Optional[str] = None
    el_text: Optional[str] = None
    el_value: Optional[str] = None
    href: Optional[str] = None
    input_type: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    selection_length: Optional[float] = None
    tag_name: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'AutocaptureProps':
        assert isinstance(obj, dict)
        ce_version = from_float(obj.get("$ce_version"))
        elements_chain = from_str(obj.get("$elements_chain"))
        event_type = AutocaptureEventType(obj.get("$event_type"))
        ai_action = from_union([from_str, from_none], obj.get("$ai_action"))
        el_name = from_union([from_str, from_none], obj.get("$el_name"))
        el_text = from_union([from_str, from_none], obj.get("$el_text"))
        el_value = from_union([from_str, from_none], obj.get("$el_value"))
        href = from_union([from_str, from_none], obj.get("$href"))
        input_type = from_union([from_str, from_none], obj.get("$input_type"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        selection_length = from_union([from_float, from_none], obj.get("$selection_length"))
        tag_name = from_union([from_str, from_none], obj.get("$tag_name"))
        return AutocaptureProps(ce_version, elements_chain, event_type, ai_action, el_name, el_text, el_value, href, input_type, request_id, response_id, selection_length, tag_name)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$ce_version"] = to_float(self.ce_version)
        result["$elements_chain"] = from_str(self.elements_chain)
        result["$event_type"] = to_enum(AutocaptureEventType, self.event_type)
        if self.ai_action is not None:
            result["$ai_action"] = from_union([from_str, from_none], self.ai_action)
        if self.el_name is not None:
            result["$el_name"] = from_union([from_str, from_none], self.el_name)
        if self.el_text is not None:
            result["$el_text"] = from_union([from_str, from_none], self.el_text)
        if self.el_value is not None:
            result["$el_value"] = from_union([from_str, from_none], self.el_value)
        if self.href is not None:
            result["$href"] = from_union([from_str, from_none], self.href)
        if self.input_type is not None:
            result["$input_type"] = from_union([from_str, from_none], self.input_type)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.selection_length is not None:
            result["$selection_length"] = from_union([to_float, from_none], self.selection_length)
        if self.tag_name is not None:
            result["$tag_name"] = from_union([from_str, from_none], self.tag_name)
        return result


class BrowserAIPromptSubmittedEventEventName(Enum):
    LLM_PROMPT_SUBMITTED = "llm_prompt_submitted"


class Environment(Enum):
    DEVELOPMENT = "development"
    PRODUCTION = "production"


class LIB(Enum):
    ANDROID = "android"
    FLUTTER = "flutter"
    IOS = "ios"
    WEB = "web"


@dataclass
class BrowserAIPromptSubmittedEventExtraJSON:
    capture_mode: CaptureMode
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    contains_attachment: Optional[bool] = None
    contains_code: Optional[bool] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    language: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    pii_detected: Optional[bool] = None
    prompt_hash: Optional[str] = None
    prompt_length_chars: Optional[float] = None
    prompt_template_id: Optional[str] = None
    prompt_text: Optional[str] = None
    prompt_tokens_estimated: Optional[float] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    sensitive_category: Optional[Union[List[SensitiveCategory], SensitiveCategory]] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAIPromptSubmittedEventExtraJSON':
        assert isinstance(obj, dict)
        capture_mode = CaptureMode(obj.get("$capture_mode"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        contains_attachment = from_union([from_bool, from_none], obj.get("$contains_attachment"))
        contains_code = from_union([from_bool, from_none], obj.get("$contains_code"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        language = from_union([from_str, from_none], obj.get("$language"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        pii_detected = from_union([from_bool, from_none], obj.get("$pii_detected"))
        prompt_hash = from_union([from_str, from_none], obj.get("$prompt_hash"))
        prompt_length_chars = from_union([from_float, from_none], obj.get("$prompt_length_chars"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        prompt_text = from_union([from_str, from_none], obj.get("$prompt_text"))
        prompt_tokens_estimated = from_union([from_float, from_none], obj.get("$prompt_tokens_estimated"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        sensitive_category = from_union([lambda x: from_list(SensitiveCategory, x), SensitiveCategory, from_none], obj.get("$sensitive_category"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserAIPromptSubmittedEventExtraJSON(capture_mode, anonymous_id, app_version, contains_attachment, contains_code, conversation_id, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, language, lib, lib_version, message_id, node_key, pageview_id, pii_detected, prompt_hash, prompt_length_chars, prompt_template_id, prompt_text, prompt_tokens_estimated, request_id, response_id, schema_version, sensitive_category, session_id, surface, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$capture_mode"] = to_enum(CaptureMode, self.capture_mode)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.contains_attachment is not None:
            result["$contains_attachment"] = from_union([from_bool, from_none], self.contains_attachment)
        if self.contains_code is not None:
            result["$contains_code"] = from_union([from_bool, from_none], self.contains_code)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.language is not None:
            result["$language"] = from_union([from_str, from_none], self.language)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.pii_detected is not None:
            result["$pii_detected"] = from_union([from_bool, from_none], self.pii_detected)
        if self.prompt_hash is not None:
            result["$prompt_hash"] = from_union([from_str, from_none], self.prompt_hash)
        if self.prompt_length_chars is not None:
            result["$prompt_length_chars"] = from_union([to_float, from_none], self.prompt_length_chars)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.prompt_text is not None:
            result["$prompt_text"] = from_union([from_str, from_none], self.prompt_text)
        if self.prompt_tokens_estimated is not None:
            result["$prompt_tokens_estimated"] = from_union([to_float, from_none], self.prompt_tokens_estimated)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.sensitive_category is not None:
            result["$sensitive_category"] = from_union([lambda x: from_list(lambda x: to_enum(SensitiveCategory, x), x), lambda x: to_enum(SensitiveCategory, x), from_none], self.sensitive_category)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserAIPromptSubmittedEvent:
    device_id: str
    event_id: str
    event_name: BrowserAIPromptSubmittedEventEventName
    extra_json: BrowserAIPromptSubmittedEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAIPromptSubmittedEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserAIPromptSubmittedEventEventName(obj.get("event_name"))
        extra_json = BrowserAIPromptSubmittedEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserAIPromptSubmittedEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserAIPromptSubmittedEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserAIPromptSubmittedEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


class BrowserAIResponseInteractedEventEventName(Enum):
    LLM_RESPONSE_INTERACTED = "llm_response_interacted"


@dataclass
class BrowserAIResponseInteractedEventExtraJSON:
    interaction_type: AIInteractionType
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    destination: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    source: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    time_since_response_ms: Optional[float] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    visible_output_ratio: Optional[float] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAIResponseInteractedEventExtraJSON':
        assert isinstance(obj, dict)
        interaction_type = AIInteractionType(obj.get("$interaction_type"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        destination = from_union([from_str, from_none], obj.get("$destination"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        source = from_union([from_str, from_none], obj.get("$source"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        time_since_response_ms = from_union([from_float, from_none], obj.get("$time_since_response_ms"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        visible_output_ratio = from_union([from_float, from_none], obj.get("$visible_output_ratio"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserAIResponseInteractedEventExtraJSON(interaction_type, anonymous_id, app_version, conversation_id, destination, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, lib, lib_version, message_id, node_key, pageview_id, prompt_template_id, request_id, response_id, schema_version, session_id, source, surface, task_type, tenant_id, time_since_response_ms, trace_id, user_id, visible_output_ratio, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$interaction_type"] = to_enum(AIInteractionType, self.interaction_type)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.destination is not None:
            result["$destination"] = from_union([from_str, from_none], self.destination)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.source is not None:
            result["$source"] = from_union([from_str, from_none], self.source)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.time_since_response_ms is not None:
            result["$time_since_response_ms"] = from_union([to_float, from_none], self.time_since_response_ms)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.visible_output_ratio is not None:
            result["$visible_output_ratio"] = from_union([to_float, from_none], self.visible_output_ratio)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserAIResponseInteractedEvent:
    device_id: str
    event_id: str
    event_name: BrowserAIResponseInteractedEventEventName
    extra_json: BrowserAIResponseInteractedEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAIResponseInteractedEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserAIResponseInteractedEventEventName(obj.get("event_name"))
        extra_json = BrowserAIResponseInteractedEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserAIResponseInteractedEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserAIResponseInteractedEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserAIResponseInteractedEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


class BrowserAIResponseRenderedEventEventName(Enum):
    LLM_RESPONSE_RENDERED = "llm_response_rendered"


@dataclass
class BrowserAIResponseRenderedEventExtraJSON:
    capture_mode: CaptureMode
    response_id: str
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    output_length_chars: Optional[float] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_text: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    time_to_render_ms: Optional[float] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    visible_output_ratio: Optional[float] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAIResponseRenderedEventExtraJSON':
        assert isinstance(obj, dict)
        capture_mode = CaptureMode(obj.get("$capture_mode"))
        response_id = from_str(obj.get("$response_id"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        output_length_chars = from_union([from_float, from_none], obj.get("$output_length_chars"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_text = from_union([from_str, from_none], obj.get("$response_text"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        time_to_render_ms = from_union([from_float, from_none], obj.get("$time_to_render_ms"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        visible_output_ratio = from_union([from_float, from_none], obj.get("$visible_output_ratio"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserAIResponseRenderedEventExtraJSON(capture_mode, response_id, anonymous_id, app_version, conversation_id, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, lib, lib_version, message_id, node_key, output_length_chars, pageview_id, prompt_template_id, request_id, response_text, schema_version, session_id, surface, task_type, tenant_id, time_to_render_ms, trace_id, user_id, visible_output_ratio, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$capture_mode"] = to_enum(CaptureMode, self.capture_mode)
        result["$response_id"] = from_str(self.response_id)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.output_length_chars is not None:
            result["$output_length_chars"] = from_union([to_float, from_none], self.output_length_chars)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_text is not None:
            result["$response_text"] = from_union([from_str, from_none], self.response_text)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.time_to_render_ms is not None:
            result["$time_to_render_ms"] = from_union([to_float, from_none], self.time_to_render_ms)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.visible_output_ratio is not None:
            result["$visible_output_ratio"] = from_union([to_float, from_none], self.visible_output_ratio)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserAIResponseRenderedEvent:
    device_id: str
    event_id: str
    event_name: BrowserAIResponseRenderedEventEventName
    extra_json: BrowserAIResponseRenderedEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAIResponseRenderedEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserAIResponseRenderedEventEventName(obj.get("event_name"))
        extra_json = BrowserAIResponseRenderedEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserAIResponseRenderedEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserAIResponseRenderedEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserAIResponseRenderedEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


class BrowserAutocaptureEventEventName(Enum):
    INTERACTION_AUTOCAPTURED = "interaction_autocaptured"


@dataclass
class BrowserAutocaptureEventExtraJSON:
    ce_version: float
    elements_chain: str
    event_type: AutocaptureEventType
    ai_action: Optional[str] = None
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    el_name: Optional[str] = None
    el_text: Optional[str] = None
    el_value: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    href: Optional[str] = None
    input_type: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    selection_length: Optional[float] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    tag_name: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAutocaptureEventExtraJSON':
        assert isinstance(obj, dict)
        ce_version = from_float(obj.get("$ce_version"))
        elements_chain = from_str(obj.get("$elements_chain"))
        event_type = AutocaptureEventType(obj.get("$event_type"))
        ai_action = from_union([from_str, from_none], obj.get("$ai_action"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        el_name = from_union([from_str, from_none], obj.get("$el_name"))
        el_text = from_union([from_str, from_none], obj.get("$el_text"))
        el_value = from_union([from_str, from_none], obj.get("$el_value"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        href = from_union([from_str, from_none], obj.get("$href"))
        input_type = from_union([from_str, from_none], obj.get("$input_type"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        selection_length = from_union([from_float, from_none], obj.get("$selection_length"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        tag_name = from_union([from_str, from_none], obj.get("$tag_name"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserAutocaptureEventExtraJSON(ce_version, elements_chain, event_type, ai_action, anonymous_id, app_version, conversation_id, device_id, el_name, el_text, el_value, entry_point, environment, feature_flag_key, feature_flag_variant, href, input_type, lib, lib_version, message_id, node_key, pageview_id, prompt_template_id, request_id, response_id, schema_version, selection_length, session_id, surface, tag_name, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$ce_version"] = to_float(self.ce_version)
        result["$elements_chain"] = from_str(self.elements_chain)
        result["$event_type"] = to_enum(AutocaptureEventType, self.event_type)
        if self.ai_action is not None:
            result["$ai_action"] = from_union([from_str, from_none], self.ai_action)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.el_name is not None:
            result["$el_name"] = from_union([from_str, from_none], self.el_name)
        if self.el_text is not None:
            result["$el_text"] = from_union([from_str, from_none], self.el_text)
        if self.el_value is not None:
            result["$el_value"] = from_union([from_str, from_none], self.el_value)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.href is not None:
            result["$href"] = from_union([from_str, from_none], self.href)
        if self.input_type is not None:
            result["$input_type"] = from_union([from_str, from_none], self.input_type)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.selection_length is not None:
            result["$selection_length"] = from_union([to_float, from_none], self.selection_length)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.tag_name is not None:
            result["$tag_name"] = from_union([from_str, from_none], self.tag_name)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserAutocaptureEvent:
    device_id: str
    event_id: str
    event_name: BrowserAutocaptureEventEventName
    extra_json: BrowserAutocaptureEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserAutocaptureEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserAutocaptureEventEventName(obj.get("event_name"))
        extra_json = BrowserAutocaptureEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserAutocaptureEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserAutocaptureEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserAutocaptureEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


@dataclass
class BrowserContextProperties:
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserContextProperties':
        assert isinstance(obj, dict)
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserContextProperties(anonymous_id, app_version, conversation_id, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, lib, lib_version, message_id, node_key, pageview_id, prompt_template_id, request_id, response_id, schema_version, session_id, surface, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


class BrowserDeadClickEventEventName(Enum):
    INTERACTION_DEADCLICK = "interaction_deadclick"


@dataclass
class BrowserDeadClickEventExtraJSON:
    elements_chain: str
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserDeadClickEventExtraJSON':
        assert isinstance(obj, dict)
        elements_chain = from_str(obj.get("$elements_chain"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserDeadClickEventExtraJSON(elements_chain, anonymous_id, app_version, conversation_id, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, lib, lib_version, message_id, node_key, pageview_id, prompt_template_id, request_id, response_id, schema_version, session_id, surface, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$elements_chain"] = from_str(self.elements_chain)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserDeadClickEvent:
    device_id: str
    event_id: str
    event_name: BrowserDeadClickEventEventName
    extra_json: BrowserDeadClickEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserDeadClickEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserDeadClickEventEventName(obj.get("event_name"))
        extra_json = BrowserDeadClickEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserDeadClickEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserDeadClickEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserDeadClickEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


@dataclass
class BrowserEvent:
    device_id: str
    event_id: str
    event_name: str
    extra_json: Dict[str, Optional[Union[float, bool, List[Optional[Union[float, bool, str]]], Dict[str, Optional[Union[float, bool, str]]], str]]]
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = from_str(obj.get("event_name"))
        extra_json = from_dict(lambda x: from_union([from_none, from_float, from_bool, lambda x: from_list(lambda x: from_union([from_none, from_float, from_bool, from_str], x), x), lambda x: from_dict(lambda x: from_union([from_none, from_float, from_bool, from_str], x), x), from_str], x), obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = from_str(self.event_name)
        result["extra_json"] = from_dict(lambda x: from_union([from_none, to_float, from_bool, lambda x: from_list(lambda x: from_union([from_none, to_float, from_bool, from_str], x), x), lambda x: from_dict(lambda x: from_union([from_none, to_float, from_bool, from_str], x), x), from_str], x), self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


@dataclass
class BrowserDiagnosticCounters:
    identity_persist_failed: Optional[int] = None
    outbox_write_failed: Optional[int] = None
    send_failed: Optional[int] = None
    storage_unavailable: Optional[int] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserDiagnosticCounters':
        assert isinstance(obj, dict)
        identity_persist_failed = from_union([from_int, from_none], obj.get("identity_persist_failed"))
        outbox_write_failed = from_union([from_int, from_none], obj.get("outbox_write_failed"))
        send_failed = from_union([from_int, from_none], obj.get("send_failed"))
        storage_unavailable = from_union([from_int, from_none], obj.get("storage_unavailable"))
        return BrowserDiagnosticCounters(identity_persist_failed, outbox_write_failed, send_failed, storage_unavailable)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.identity_persist_failed is not None:
            result["identity_persist_failed"] = from_union([from_int, from_none], self.identity_persist_failed)
        if self.outbox_write_failed is not None:
            result["outbox_write_failed"] = from_union([from_int, from_none], self.outbox_write_failed)
        if self.send_failed is not None:
            result["send_failed"] = from_union([from_int, from_none], self.send_failed)
        if self.storage_unavailable is not None:
            result["storage_unavailable"] = from_union([from_int, from_none], self.storage_unavailable)
        return result


class SDKName(Enum):
    BROWSER_JAVASCRIPT = "browser-javascript"


@dataclass
class BrowserDiagnosticsEnvelope:
    counters: BrowserDiagnosticCounters
    sdk_name: SDKName

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserDiagnosticsEnvelope':
        assert isinstance(obj, dict)
        counters = BrowserDiagnosticCounters.from_dict(obj.get("counters"))
        sdk_name = SDKName(obj.get("sdk_name"))
        return BrowserDiagnosticsEnvelope(counters, sdk_name)

    def to_dict(self) -> dict:
        result: dict = {}
        result["counters"] = to_class(BrowserDiagnosticCounters, self.counters)
        result["sdk_name"] = to_enum(SDKName, self.sdk_name)
        return result


@dataclass
class BrowserEventBatchRequest:
    batch: List[BrowserEvent]
    diagnostics: Optional[BrowserDiagnosticsEnvelope] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserEventBatchRequest':
        assert isinstance(obj, dict)
        batch = from_list(BrowserEvent.from_dict, obj.get("batch"))
        diagnostics = from_union([BrowserDiagnosticsEnvelope.from_dict, from_none], obj.get("diagnostics"))
        return BrowserEventBatchRequest(batch, diagnostics)

    def to_dict(self) -> dict:
        result: dict = {}
        result["batch"] = from_list(lambda x: to_class(BrowserEvent, x), self.batch)
        if self.diagnostics is not None:
            result["diagnostics"] = from_union([lambda x: to_class(BrowserDiagnosticsEnvelope, x), from_none], self.diagnostics)
        return result


class BrowserEventResultCode(Enum):
    INVALID_EVENT = "invalid_event"
    MISSING_REQUIRED = "missing_required"
    RESERVED_NAME = "reserved_name"
    SCHEMA_DISCOVERED = "schema_discovered"
    SCHEMA_DRIFT = "schema_drift"
    SCHEMA_ENUM_MISMATCH = "schema_enum_mismatch"
    SCHEMA_REQUIRED_MISSING = "schema_required_missing"
    SCHEMA_TYPE_MISMATCH = "schema_type_mismatch"
    STORAGE_UNAVAILABLE = "storage_unavailable"


class BrowserEventResultStatus(Enum):
    DROP = "drop"
    OK = "ok"
    RETRY = "retry"
    WARNING = "warning"


@dataclass
class BrowserEventResult:
    result: BrowserEventResultStatus
    code: Optional[BrowserEventResultCode] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserEventResult':
        assert isinstance(obj, dict)
        result = BrowserEventResultStatus(obj.get("result"))
        code = from_union([BrowserEventResultCode, from_none], obj.get("code"))
        return BrowserEventResult(result, code)

    def to_dict(self) -> dict:
        result: dict = {}
        result["result"] = to_enum(BrowserEventResultStatus, self.result)
        if self.code is not None:
            result["code"] = from_union([lambda x: to_enum(BrowserEventResultCode, x), from_none], self.code)
        return result


@dataclass
class BrowserEventBatchResponse:
    results: Dict[str, BrowserEventResult]

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserEventBatchResponse':
        assert isinstance(obj, dict)
        results = from_dict(BrowserEventResult.from_dict, obj.get("results"))
        return BrowserEventBatchResponse(results)

    def to_dict(self) -> dict:
        result: dict = {}
        result["results"] = from_dict(lambda x: to_class(BrowserEventResult, x), self.results)
        return result


@dataclass
class BrowserIngestEvent:
    device_id: str
    event_id: str
    event_name: str
    extra_json: Dict[str, Optional[Union[float, bool, List[Optional[Union[float, bool, str]]], Dict[str, Optional[Union[float, bool, str]]], str]]]
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None
    """Finite decimal with at most 38 integer digits and 12 fractional digits"""

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserIngestEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = from_str(obj.get("event_name"))
        extra_json = from_dict(lambda x: from_union([from_none, from_float, from_bool, lambda x: from_list(lambda x: from_union([from_none, from_float, from_bool, from_str], x), x), lambda x: from_dict(lambda x: from_union([from_none, from_float, from_bool, from_str], x), x), from_str], x), obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserIngestEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = from_str(self.event_name)
        result["extra_json"] = from_dict(lambda x: from_union([from_none, to_float, from_bool, lambda x: from_list(lambda x: from_union([from_none, to_float, from_bool, from_str], x), x), lambda x: from_dict(lambda x: from_union([from_none, to_float, from_bool, from_str], x), x), from_str], x), self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


class BrowserPageleaveEventEventName(Enum):
    PAGELEAVE = "pageleave"


@dataclass
class BrowserPageleaveEventExtraJSON:
    current_url: str
    pathname: str
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    duration_ms: Optional[float] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    last_content_percentage: Optional[float] = None
    last_content_y: Optional[float] = None
    last_scroll_percentage: Optional[float] = None
    last_scroll_y: Optional[float] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    max_content_percentage: Optional[float] = None
    max_content_y: Optional[float] = None
    max_scroll_percentage: Optional[float] = None
    max_scroll_y: Optional[float] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserPageleaveEventExtraJSON':
        assert isinstance(obj, dict)
        current_url = from_str(obj.get("$current_url"))
        pathname = from_str(obj.get("$pathname"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        duration_ms = from_union([from_float, from_none], obj.get("$duration_ms"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        last_content_percentage = from_union([from_float, from_none], obj.get("$last_content_percentage"))
        last_content_y = from_union([from_float, from_none], obj.get("$last_content_y"))
        last_scroll_percentage = from_union([from_float, from_none], obj.get("$last_scroll_percentage"))
        last_scroll_y = from_union([from_float, from_none], obj.get("$last_scroll_y"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        max_content_percentage = from_union([from_float, from_none], obj.get("$max_content_percentage"))
        max_content_y = from_union([from_float, from_none], obj.get("$max_content_y"))
        max_scroll_percentage = from_union([from_float, from_none], obj.get("$max_scroll_percentage"))
        max_scroll_y = from_union([from_float, from_none], obj.get("$max_scroll_y"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserPageleaveEventExtraJSON(current_url, pathname, anonymous_id, app_version, conversation_id, device_id, duration_ms, entry_point, environment, feature_flag_key, feature_flag_variant, last_content_percentage, last_content_y, last_scroll_percentage, last_scroll_y, lib, lib_version, max_content_percentage, max_content_y, max_scroll_percentage, max_scroll_y, message_id, node_key, pageview_id, prompt_template_id, request_id, response_id, schema_version, session_id, surface, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$current_url"] = from_str(self.current_url)
        result["$pathname"] = from_str(self.pathname)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.duration_ms is not None:
            result["$duration_ms"] = from_union([to_float, from_none], self.duration_ms)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.last_content_percentage is not None:
            result["$last_content_percentage"] = from_union([to_float, from_none], self.last_content_percentage)
        if self.last_content_y is not None:
            result["$last_content_y"] = from_union([to_float, from_none], self.last_content_y)
        if self.last_scroll_percentage is not None:
            result["$last_scroll_percentage"] = from_union([to_float, from_none], self.last_scroll_percentage)
        if self.last_scroll_y is not None:
            result["$last_scroll_y"] = from_union([to_float, from_none], self.last_scroll_y)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.max_content_percentage is not None:
            result["$max_content_percentage"] = from_union([to_float, from_none], self.max_content_percentage)
        if self.max_content_y is not None:
            result["$max_content_y"] = from_union([to_float, from_none], self.max_content_y)
        if self.max_scroll_percentage is not None:
            result["$max_scroll_percentage"] = from_union([to_float, from_none], self.max_scroll_percentage)
        if self.max_scroll_y is not None:
            result["$max_scroll_y"] = from_union([to_float, from_none], self.max_scroll_y)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserPageleaveEvent:
    device_id: str
    event_id: str
    event_name: BrowserPageleaveEventEventName
    extra_json: BrowserPageleaveEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserPageleaveEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserPageleaveEventEventName(obj.get("event_name"))
        extra_json = BrowserPageleaveEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserPageleaveEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserPageleaveEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserPageleaveEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


class BrowserPageviewEventEventName(Enum):
    PAGEVIEW = "pageview"


@dataclass
class BrowserPageviewEventExtraJSON:
    current_url: str
    pathname: str
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    referrer: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserPageviewEventExtraJSON':
        assert isinstance(obj, dict)
        current_url = from_str(obj.get("$current_url"))
        pathname = from_str(obj.get("$pathname"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        referrer = from_union([from_str, from_none], obj.get("$referrer"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserPageviewEventExtraJSON(current_url, pathname, anonymous_id, app_version, conversation_id, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, lib, lib_version, message_id, node_key, pageview_id, prompt_template_id, referrer, request_id, response_id, schema_version, session_id, surface, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$current_url"] = from_str(self.current_url)
        result["$pathname"] = from_str(self.pathname)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.referrer is not None:
            result["$referrer"] = from_union([from_str, from_none], self.referrer)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserPageviewEvent:
    device_id: str
    event_id: str
    event_name: BrowserPageviewEventEventName
    extra_json: BrowserPageviewEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserPageviewEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserPageviewEventEventName(obj.get("event_name"))
        extra_json = BrowserPageviewEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserPageviewEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserPageviewEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserPageviewEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


class BrowserRageclickEventEventName(Enum):
    INTERACTION_RAGECLICK = "interaction_rageclick"


@dataclass
class BrowserRageclickEventExtraJSON:
    elements_chain: str
    anonymous_id: Optional[str] = None
    app_version: Optional[str] = None
    click_count: Optional[float] = None
    conversation_id: Optional[str] = None
    device_id: Optional[str] = None
    entry_point: Optional[str] = None
    environment: Optional[Environment] = None
    feature_flag_key: Optional[str] = None
    feature_flag_variant: Optional[str] = None
    lib: Optional[LIB] = None
    lib_version: Optional[str] = None
    message_id: Optional[str] = None
    node_key: Optional[str] = None
    pageview_id: Optional[str] = None
    prompt_template_id: Optional[str] = None
    request_id: Optional[str] = None
    response_id: Optional[str] = None
    schema_version: Optional[str] = None
    session_id: Optional[str] = None
    surface: Optional[str] = None
    task_type: Optional[str] = None
    tenant_id: Optional[str] = None
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    window_id: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserRageclickEventExtraJSON':
        assert isinstance(obj, dict)
        elements_chain = from_str(obj.get("$elements_chain"))
        anonymous_id = from_union([from_str, from_none], obj.get("$anonymous_id"))
        app_version = from_union([from_str, from_none], obj.get("$app_version"))
        click_count = from_union([from_float, from_none], obj.get("$click_count"))
        conversation_id = from_union([from_str, from_none], obj.get("$conversation_id"))
        device_id = from_union([from_str, from_none], obj.get("$device_id"))
        entry_point = from_union([from_str, from_none], obj.get("$entry_point"))
        environment = from_union([Environment, from_none], obj.get("$environment"))
        feature_flag_key = from_union([from_str, from_none], obj.get("$feature_flag_key"))
        feature_flag_variant = from_union([from_str, from_none], obj.get("$feature_flag_variant"))
        lib = from_union([LIB, from_none], obj.get("$lib"))
        lib_version = from_union([from_str, from_none], obj.get("$lib_version"))
        message_id = from_union([from_str, from_none], obj.get("$message_id"))
        node_key = from_union([from_str, from_none], obj.get("$node_key"))
        pageview_id = from_union([from_str, from_none], obj.get("$pageview_id"))
        prompt_template_id = from_union([from_str, from_none], obj.get("$prompt_template_id"))
        request_id = from_union([from_str, from_none], obj.get("$request_id"))
        response_id = from_union([from_str, from_none], obj.get("$response_id"))
        schema_version = from_union([from_str, from_none], obj.get("$schema_version"))
        session_id = from_union([from_str, from_none], obj.get("$session_id"))
        surface = from_union([from_str, from_none], obj.get("$surface"))
        task_type = from_union([from_str, from_none], obj.get("$task_type"))
        tenant_id = from_union([from_str, from_none], obj.get("$tenant_id"))
        trace_id = from_union([from_str, from_none], obj.get("$trace_id"))
        user_id = from_union([from_str, from_none], obj.get("$user_id"))
        window_id = from_union([from_str, from_none], obj.get("$window_id"))
        return BrowserRageclickEventExtraJSON(elements_chain, anonymous_id, app_version, click_count, conversation_id, device_id, entry_point, environment, feature_flag_key, feature_flag_variant, lib, lib_version, message_id, node_key, pageview_id, prompt_template_id, request_id, response_id, schema_version, session_id, surface, task_type, tenant_id, trace_id, user_id, window_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$elements_chain"] = from_str(self.elements_chain)
        if self.anonymous_id is not None:
            result["$anonymous_id"] = from_union([from_str, from_none], self.anonymous_id)
        if self.app_version is not None:
            result["$app_version"] = from_union([from_str, from_none], self.app_version)
        if self.click_count is not None:
            result["$click_count"] = from_union([to_float, from_none], self.click_count)
        if self.conversation_id is not None:
            result["$conversation_id"] = from_union([from_str, from_none], self.conversation_id)
        if self.device_id is not None:
            result["$device_id"] = from_union([from_str, from_none], self.device_id)
        if self.entry_point is not None:
            result["$entry_point"] = from_union([from_str, from_none], self.entry_point)
        if self.environment is not None:
            result["$environment"] = from_union([lambda x: to_enum(Environment, x), from_none], self.environment)
        if self.feature_flag_key is not None:
            result["$feature_flag_key"] = from_union([from_str, from_none], self.feature_flag_key)
        if self.feature_flag_variant is not None:
            result["$feature_flag_variant"] = from_union([from_str, from_none], self.feature_flag_variant)
        if self.lib is not None:
            result["$lib"] = from_union([lambda x: to_enum(LIB, x), from_none], self.lib)
        if self.lib_version is not None:
            result["$lib_version"] = from_union([from_str, from_none], self.lib_version)
        if self.message_id is not None:
            result["$message_id"] = from_union([from_str, from_none], self.message_id)
        if self.node_key is not None:
            result["$node_key"] = from_union([from_str, from_none], self.node_key)
        if self.pageview_id is not None:
            result["$pageview_id"] = from_union([from_str, from_none], self.pageview_id)
        if self.prompt_template_id is not None:
            result["$prompt_template_id"] = from_union([from_str, from_none], self.prompt_template_id)
        if self.request_id is not None:
            result["$request_id"] = from_union([from_str, from_none], self.request_id)
        if self.response_id is not None:
            result["$response_id"] = from_union([from_str, from_none], self.response_id)
        if self.schema_version is not None:
            result["$schema_version"] = from_union([from_str, from_none], self.schema_version)
        if self.session_id is not None:
            result["$session_id"] = from_union([from_str, from_none], self.session_id)
        if self.surface is not None:
            result["$surface"] = from_union([from_str, from_none], self.surface)
        if self.task_type is not None:
            result["$task_type"] = from_union([from_str, from_none], self.task_type)
        if self.tenant_id is not None:
            result["$tenant_id"] = from_union([from_str, from_none], self.tenant_id)
        if self.trace_id is not None:
            result["$trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.user_id is not None:
            result["$user_id"] = from_union([from_str, from_none], self.user_id)
        if self.window_id is not None:
            result["$window_id"] = from_union([from_str, from_none], self.window_id)
        return result


@dataclass
class BrowserRageclickEvent:
    device_id: str
    event_id: str
    event_name: BrowserRageclickEventEventName
    extra_json: BrowserRageclickEventExtraJSON
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'BrowserRageclickEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = BrowserRageclickEventEventName(obj.get("event_name"))
        extra_json = BrowserRageclickEventExtraJSON.from_dict(obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return BrowserRageclickEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = to_enum(BrowserRageclickEventEventName, self.event_name)
        result["extra_json"] = to_class(BrowserRageclickEventExtraJSON, self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


@dataclass
class CustomEvent:
    device_id: str
    event_id: str
    event_name: str
    extra_json: Dict[str, Optional[Union[float, bool, List[Optional[Union[float, bool, str]]], Dict[str, Optional[Union[float, bool, str]]], str]]]
    occurred_at: str
    scale: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    value: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'CustomEvent':
        assert isinstance(obj, dict)
        device_id = from_str(obj.get("device_id"))
        event_id = from_str(obj.get("event_id"))
        event_name = from_str(obj.get("event_name"))
        extra_json = from_dict(lambda x: from_union([from_none, from_float, from_bool, lambda x: from_list(lambda x: from_union([from_none, from_float, from_bool, from_str], x), x), lambda x: from_dict(lambda x: from_union([from_none, from_float, from_bool, from_str], x), x), from_str], x), obj.get("extra_json"))
        occurred_at = from_str(obj.get("occurred_at"))
        scale = from_union([from_str, from_none], obj.get("scale"))
        session_id = from_union([from_str, from_none], obj.get("session_id"))
        trace_id = from_union([from_str, from_none], obj.get("trace_id"))
        value = from_union([from_float, from_none], obj.get("value"))
        return CustomEvent(device_id, event_id, event_name, extra_json, occurred_at, scale, session_id, trace_id, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["device_id"] = from_str(self.device_id)
        result["event_id"] = from_str(self.event_id)
        result["event_name"] = from_str(self.event_name)
        result["extra_json"] = from_dict(lambda x: from_union([from_none, to_float, from_bool, lambda x: from_list(lambda x: from_union([from_none, to_float, from_bool, from_str], x), x), lambda x: from_dict(lambda x: from_union([from_none, to_float, from_bool, from_str], x), x), from_str], x), self.extra_json)
        result["occurred_at"] = from_str(self.occurred_at)
        if self.scale is not None:
            result["scale"] = from_union([from_str, from_none], self.scale)
        if self.session_id is not None:
            result["session_id"] = from_union([from_str, from_none], self.session_id)
        if self.trace_id is not None:
            result["trace_id"] = from_union([from_str, from_none], self.trace_id)
        if self.value is not None:
            result["value"] = from_union([to_float, from_none], self.value)
        return result


@dataclass
class DeadClickProps:
    elements_chain: str

    @staticmethod
    def from_dict(obj: Any) -> 'DeadClickProps':
        assert isinstance(obj, dict)
        elements_chain = from_str(obj.get("$elements_chain"))
        return DeadClickProps(elements_chain)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$elements_chain"] = from_str(self.elements_chain)
        return result


class TokenBucket(Enum):
    THE_0 = "0"
    THE_10012000 = "1001-2000"
    THE_150 = "1-50"
    THE_2000 = "2000+"
    THE_201500 = "201-500"
    THE_5011000 = "501-1000"
    THE_51200 = "51-200"


@dataclass
class DerivedTextMeta:
    capture_mode: CaptureMode
    contains_attachment: Optional[bool] = None
    contains_code: Optional[bool] = None
    excerpt: Optional[str] = None
    hash: Optional[str] = None
    length_chars: Optional[float] = None
    pii_detected: Optional[bool] = None
    sensitive_category: Optional[SensitiveCategory] = None
    token_bucket: Optional[TokenBucket] = None

    @staticmethod
    def from_dict(obj: Any) -> 'DerivedTextMeta':
        assert isinstance(obj, dict)
        capture_mode = CaptureMode(obj.get("capture_mode"))
        contains_attachment = from_union([from_bool, from_none], obj.get("contains_attachment"))
        contains_code = from_union([from_bool, from_none], obj.get("contains_code"))
        excerpt = from_union([from_str, from_none], obj.get("excerpt"))
        hash = from_union([from_str, from_none], obj.get("hash"))
        length_chars = from_union([from_float, from_none], obj.get("length_chars"))
        pii_detected = from_union([from_bool, from_none], obj.get("pii_detected"))
        sensitive_category = from_union([from_none, SensitiveCategory], obj.get("sensitive_category"))
        token_bucket = from_union([TokenBucket, from_none], obj.get("token_bucket"))
        return DerivedTextMeta(capture_mode, contains_attachment, contains_code, excerpt, hash, length_chars, pii_detected, sensitive_category, token_bucket)

    def to_dict(self) -> dict:
        result: dict = {}
        result["capture_mode"] = to_enum(CaptureMode, self.capture_mode)
        if self.contains_attachment is not None:
            result["contains_attachment"] = from_union([from_bool, from_none], self.contains_attachment)
        if self.contains_code is not None:
            result["contains_code"] = from_union([from_bool, from_none], self.contains_code)
        if self.excerpt is not None:
            result["excerpt"] = from_union([from_str, from_none], self.excerpt)
        if self.hash is not None:
            result["hash"] = from_union([from_str, from_none], self.hash)
        if self.length_chars is not None:
            result["length_chars"] = from_union([to_float, from_none], self.length_chars)
        if self.pii_detected is not None:
            result["pii_detected"] = from_union([from_bool, from_none], self.pii_detected)
        if self.sensitive_category is not None:
            result["sensitive_category"] = from_union([from_none, lambda x: to_enum(SensitiveCategory, x)], self.sensitive_category)
        if self.token_bucket is not None:
            result["token_bucket"] = from_union([lambda x: to_enum(TokenBucket, x), from_none], self.token_bucket)
        return result


class MaskMode(Enum):
    ALL = "all"
    OFF = "off"
    SENSITIVE = "sensitive"


@dataclass
class PageleaveProps:
    current_url: str
    pathname: str
    duration_ms: Optional[float] = None
    last_content_percentage: Optional[float] = None
    last_content_y: Optional[float] = None
    last_scroll_percentage: Optional[float] = None
    last_scroll_y: Optional[float] = None
    max_content_percentage: Optional[float] = None
    max_content_y: Optional[float] = None
    max_scroll_percentage: Optional[float] = None
    max_scroll_y: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'PageleaveProps':
        assert isinstance(obj, dict)
        current_url = from_str(obj.get("$current_url"))
        pathname = from_str(obj.get("$pathname"))
        duration_ms = from_union([from_float, from_none], obj.get("$duration_ms"))
        last_content_percentage = from_union([from_float, from_none], obj.get("$last_content_percentage"))
        last_content_y = from_union([from_float, from_none], obj.get("$last_content_y"))
        last_scroll_percentage = from_union([from_float, from_none], obj.get("$last_scroll_percentage"))
        last_scroll_y = from_union([from_float, from_none], obj.get("$last_scroll_y"))
        max_content_percentage = from_union([from_float, from_none], obj.get("$max_content_percentage"))
        max_content_y = from_union([from_float, from_none], obj.get("$max_content_y"))
        max_scroll_percentage = from_union([from_float, from_none], obj.get("$max_scroll_percentage"))
        max_scroll_y = from_union([from_float, from_none], obj.get("$max_scroll_y"))
        return PageleaveProps(current_url, pathname, duration_ms, last_content_percentage, last_content_y, last_scroll_percentage, last_scroll_y, max_content_percentage, max_content_y, max_scroll_percentage, max_scroll_y)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$current_url"] = from_str(self.current_url)
        result["$pathname"] = from_str(self.pathname)
        if self.duration_ms is not None:
            result["$duration_ms"] = from_union([to_float, from_none], self.duration_ms)
        if self.last_content_percentage is not None:
            result["$last_content_percentage"] = from_union([to_float, from_none], self.last_content_percentage)
        if self.last_content_y is not None:
            result["$last_content_y"] = from_union([to_float, from_none], self.last_content_y)
        if self.last_scroll_percentage is not None:
            result["$last_scroll_percentage"] = from_union([to_float, from_none], self.last_scroll_percentage)
        if self.last_scroll_y is not None:
            result["$last_scroll_y"] = from_union([to_float, from_none], self.last_scroll_y)
        if self.max_content_percentage is not None:
            result["$max_content_percentage"] = from_union([to_float, from_none], self.max_content_percentage)
        if self.max_content_y is not None:
            result["$max_content_y"] = from_union([to_float, from_none], self.max_content_y)
        if self.max_scroll_percentage is not None:
            result["$max_scroll_percentage"] = from_union([to_float, from_none], self.max_scroll_percentage)
        if self.max_scroll_y is not None:
            result["$max_scroll_y"] = from_union([to_float, from_none], self.max_scroll_y)
        return result


@dataclass
class PageviewProps:
    current_url: str
    pathname: str
    referrer: Optional[str] = None

    @staticmethod
    def from_dict(obj: Any) -> 'PageviewProps':
        assert isinstance(obj, dict)
        current_url = from_str(obj.get("$current_url"))
        pathname = from_str(obj.get("$pathname"))
        referrer = from_union([from_str, from_none], obj.get("$referrer"))
        return PageviewProps(current_url, pathname, referrer)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$current_url"] = from_str(self.current_url)
        result["$pathname"] = from_str(self.pathname)
        if self.referrer is not None:
            result["$referrer"] = from_union([from_str, from_none], self.referrer)
        return result


@dataclass
class RageclickProps:
    elements_chain: str
    click_count: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'RageclickProps':
        assert isinstance(obj, dict)
        elements_chain = from_str(obj.get("$elements_chain"))
        click_count = from_union([from_float, from_none], obj.get("$click_count"))
        return RageclickProps(elements_chain, click_count)

    def to_dict(self) -> dict:
        result: dict = {}
        result["$elements_chain"] = from_str(self.elements_chain)
        if self.click_count is not None:
            result["$click_count"] = from_union([to_float, from_none], self.click_count)
        return result


@dataclass
class ScrollDepthProps:
    last_content_percentage: Optional[float] = None
    last_content_y: Optional[float] = None
    last_scroll_percentage: Optional[float] = None
    last_scroll_y: Optional[float] = None
    max_content_percentage: Optional[float] = None
    max_content_y: Optional[float] = None
    max_scroll_percentage: Optional[float] = None
    max_scroll_y: Optional[float] = None

    @staticmethod
    def from_dict(obj: Any) -> 'ScrollDepthProps':
        assert isinstance(obj, dict)
        last_content_percentage = from_union([from_float, from_none], obj.get("$last_content_percentage"))
        last_content_y = from_union([from_float, from_none], obj.get("$last_content_y"))
        last_scroll_percentage = from_union([from_float, from_none], obj.get("$last_scroll_percentage"))
        last_scroll_y = from_union([from_float, from_none], obj.get("$last_scroll_y"))
        max_content_percentage = from_union([from_float, from_none], obj.get("$max_content_percentage"))
        max_content_y = from_union([from_float, from_none], obj.get("$max_content_y"))
        max_scroll_percentage = from_union([from_float, from_none], obj.get("$max_scroll_percentage"))
        max_scroll_y = from_union([from_float, from_none], obj.get("$max_scroll_y"))
        return ScrollDepthProps(last_content_percentage, last_content_y, last_scroll_percentage, last_scroll_y, max_content_percentage, max_content_y, max_scroll_percentage, max_scroll_y)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.last_content_percentage is not None:
            result["$last_content_percentage"] = from_union([to_float, from_none], self.last_content_percentage)
        if self.last_content_y is not None:
            result["$last_content_y"] = from_union([to_float, from_none], self.last_content_y)
        if self.last_scroll_percentage is not None:
            result["$last_scroll_percentage"] = from_union([to_float, from_none], self.last_scroll_percentage)
        if self.last_scroll_y is not None:
            result["$last_scroll_y"] = from_union([to_float, from_none], self.last_scroll_y)
        if self.max_content_percentage is not None:
            result["$max_content_percentage"] = from_union([to_float, from_none], self.max_content_percentage)
        if self.max_content_y is not None:
            result["$max_content_y"] = from_union([to_float, from_none], self.max_content_y)
        if self.max_scroll_percentage is not None:
            result["$max_scroll_percentage"] = from_union([to_float, from_none], self.max_scroll_percentage)
        if self.max_scroll_y is not None:
            result["$max_scroll_y"] = from_union([to_float, from_none], self.max_scroll_y)
        return result


@dataclass
class Events:
    ai_prompt_submitted_props: Optional[AIPromptSubmittedProps] = None
    ai_response_interacted_props: Optional[AIResponseInteractedProps] = None
    ai_response_rendered_props: Optional[AIResponseRenderedProps] = None
    autocapture_props: Optional[AutocaptureProps] = None
    browser_ai_prompt_submitted_event: Optional[BrowserAIPromptSubmittedEvent] = None
    browser_ai_response_interacted_event: Optional[BrowserAIResponseInteractedEvent] = None
    browser_ai_response_rendered_event: Optional[BrowserAIResponseRenderedEvent] = None
    browser_autocapture_event: Optional[BrowserAutocaptureEvent] = None
    browser_context_properties: Optional[BrowserContextProperties] = None
    browser_dead_click_event: Optional[BrowserDeadClickEvent] = None
    browser_event_batch_request: Optional[BrowserEventBatchRequest] = None
    browser_event_batch_response: Optional[BrowserEventBatchResponse] = None
    browser_event_result: Optional[BrowserEventResult] = None
    browser_event_result_code: Optional[BrowserEventResultCode] = None
    browser_event_result_status: Optional[BrowserEventResultStatus] = None
    browser_ingest_event: Optional[BrowserIngestEvent] = None
    browser_pageleave_event: Optional[BrowserPageleaveEvent] = None
    browser_pageview_event: Optional[BrowserPageviewEvent] = None
    browser_rageclick_event: Optional[BrowserRageclickEvent] = None
    custom_event: Optional[CustomEvent] = None
    dead_click_props: Optional[DeadClickProps] = None
    derived_text_meta: Optional[DerivedTextMeta] = None
    mask_mode: Optional[MaskMode] = None
    metric_value: Optional[float] = None
    pageleave_props: Optional[PageleaveProps] = None
    pageview_props: Optional[PageviewProps] = None
    rageclick_props: Optional[RageclickProps] = None
    scroll_depth_props: Optional[ScrollDepthProps] = None
    token_bucket: Optional[TokenBucket] = None

    @staticmethod
    def from_dict(obj: Any) -> 'Events':
        assert isinstance(obj, dict)
        ai_prompt_submitted_props = from_union([AIPromptSubmittedProps.from_dict, from_none], obj.get("AiPromptSubmittedProps"))
        ai_response_interacted_props = from_union([AIResponseInteractedProps.from_dict, from_none], obj.get("AiResponseInteractedProps"))
        ai_response_rendered_props = from_union([AIResponseRenderedProps.from_dict, from_none], obj.get("AiResponseRenderedProps"))
        autocapture_props = from_union([AutocaptureProps.from_dict, from_none], obj.get("AutocaptureProps"))
        browser_ai_prompt_submitted_event = from_union([BrowserAIPromptSubmittedEvent.from_dict, from_none], obj.get("BrowserAiPromptSubmittedEvent"))
        browser_ai_response_interacted_event = from_union([BrowserAIResponseInteractedEvent.from_dict, from_none], obj.get("BrowserAiResponseInteractedEvent"))
        browser_ai_response_rendered_event = from_union([BrowserAIResponseRenderedEvent.from_dict, from_none], obj.get("BrowserAiResponseRenderedEvent"))
        browser_autocapture_event = from_union([BrowserAutocaptureEvent.from_dict, from_none], obj.get("BrowserAutocaptureEvent"))
        browser_context_properties = from_union([BrowserContextProperties.from_dict, from_none], obj.get("BrowserContextProperties"))
        browser_dead_click_event = from_union([BrowserDeadClickEvent.from_dict, from_none], obj.get("BrowserDeadClickEvent"))
        browser_event_batch_request = from_union([BrowserEventBatchRequest.from_dict, from_none], obj.get("BrowserEventBatchRequest"))
        browser_event_batch_response = from_union([BrowserEventBatchResponse.from_dict, from_none], obj.get("BrowserEventBatchResponse"))
        browser_event_result = from_union([BrowserEventResult.from_dict, from_none], obj.get("BrowserEventResult"))
        browser_event_result_code = from_union([BrowserEventResultCode, from_none], obj.get("BrowserEventResultCode"))
        browser_event_result_status = from_union([BrowserEventResultStatus, from_none], obj.get("BrowserEventResultStatus"))
        browser_ingest_event = from_union([BrowserIngestEvent.from_dict, from_none], obj.get("BrowserIngestEvent"))
        browser_pageleave_event = from_union([BrowserPageleaveEvent.from_dict, from_none], obj.get("BrowserPageleaveEvent"))
        browser_pageview_event = from_union([BrowserPageviewEvent.from_dict, from_none], obj.get("BrowserPageviewEvent"))
        browser_rageclick_event = from_union([BrowserRageclickEvent.from_dict, from_none], obj.get("BrowserRageclickEvent"))
        custom_event = from_union([CustomEvent.from_dict, from_none], obj.get("CustomEvent"))
        dead_click_props = from_union([DeadClickProps.from_dict, from_none], obj.get("DeadClickProps"))
        derived_text_meta = from_union([DerivedTextMeta.from_dict, from_none], obj.get("DerivedTextMeta"))
        mask_mode = from_union([MaskMode, from_none], obj.get("MaskMode"))
        metric_value = from_union([from_float, from_none], obj.get("MetricValue"))
        pageleave_props = from_union([PageleaveProps.from_dict, from_none], obj.get("PageleaveProps"))
        pageview_props = from_union([PageviewProps.from_dict, from_none], obj.get("PageviewProps"))
        rageclick_props = from_union([RageclickProps.from_dict, from_none], obj.get("RageclickProps"))
        scroll_depth_props = from_union([ScrollDepthProps.from_dict, from_none], obj.get("ScrollDepthProps"))
        token_bucket = from_union([TokenBucket, from_none], obj.get("TokenBucket"))
        return Events(ai_prompt_submitted_props, ai_response_interacted_props, ai_response_rendered_props, autocapture_props, browser_ai_prompt_submitted_event, browser_ai_response_interacted_event, browser_ai_response_rendered_event, browser_autocapture_event, browser_context_properties, browser_dead_click_event, browser_event_batch_request, browser_event_batch_response, browser_event_result, browser_event_result_code, browser_event_result_status, browser_ingest_event, browser_pageleave_event, browser_pageview_event, browser_rageclick_event, custom_event, dead_click_props, derived_text_meta, mask_mode, metric_value, pageleave_props, pageview_props, rageclick_props, scroll_depth_props, token_bucket)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.ai_prompt_submitted_props is not None:
            result["AiPromptSubmittedProps"] = from_union([lambda x: to_class(AIPromptSubmittedProps, x), from_none], self.ai_prompt_submitted_props)
        if self.ai_response_interacted_props is not None:
            result["AiResponseInteractedProps"] = from_union([lambda x: to_class(AIResponseInteractedProps, x), from_none], self.ai_response_interacted_props)
        if self.ai_response_rendered_props is not None:
            result["AiResponseRenderedProps"] = from_union([lambda x: to_class(AIResponseRenderedProps, x), from_none], self.ai_response_rendered_props)
        if self.autocapture_props is not None:
            result["AutocaptureProps"] = from_union([lambda x: to_class(AutocaptureProps, x), from_none], self.autocapture_props)
        if self.browser_ai_prompt_submitted_event is not None:
            result["BrowserAiPromptSubmittedEvent"] = from_union([lambda x: to_class(BrowserAIPromptSubmittedEvent, x), from_none], self.browser_ai_prompt_submitted_event)
        if self.browser_ai_response_interacted_event is not None:
            result["BrowserAiResponseInteractedEvent"] = from_union([lambda x: to_class(BrowserAIResponseInteractedEvent, x), from_none], self.browser_ai_response_interacted_event)
        if self.browser_ai_response_rendered_event is not None:
            result["BrowserAiResponseRenderedEvent"] = from_union([lambda x: to_class(BrowserAIResponseRenderedEvent, x), from_none], self.browser_ai_response_rendered_event)
        if self.browser_autocapture_event is not None:
            result["BrowserAutocaptureEvent"] = from_union([lambda x: to_class(BrowserAutocaptureEvent, x), from_none], self.browser_autocapture_event)
        if self.browser_context_properties is not None:
            result["BrowserContextProperties"] = from_union([lambda x: to_class(BrowserContextProperties, x), from_none], self.browser_context_properties)
        if self.browser_dead_click_event is not None:
            result["BrowserDeadClickEvent"] = from_union([lambda x: to_class(BrowserDeadClickEvent, x), from_none], self.browser_dead_click_event)
        if self.browser_event_batch_request is not None:
            result["BrowserEventBatchRequest"] = from_union([lambda x: to_class(BrowserEventBatchRequest, x), from_none], self.browser_event_batch_request)
        if self.browser_event_batch_response is not None:
            result["BrowserEventBatchResponse"] = from_union([lambda x: to_class(BrowserEventBatchResponse, x), from_none], self.browser_event_batch_response)
        if self.browser_event_result is not None:
            result["BrowserEventResult"] = from_union([lambda x: to_class(BrowserEventResult, x), from_none], self.browser_event_result)
        if self.browser_event_result_code is not None:
            result["BrowserEventResultCode"] = from_union([lambda x: to_enum(BrowserEventResultCode, x), from_none], self.browser_event_result_code)
        if self.browser_event_result_status is not None:
            result["BrowserEventResultStatus"] = from_union([lambda x: to_enum(BrowserEventResultStatus, x), from_none], self.browser_event_result_status)
        if self.browser_ingest_event is not None:
            result["BrowserIngestEvent"] = from_union([lambda x: to_class(BrowserIngestEvent, x), from_none], self.browser_ingest_event)
        if self.browser_pageleave_event is not None:
            result["BrowserPageleaveEvent"] = from_union([lambda x: to_class(BrowserPageleaveEvent, x), from_none], self.browser_pageleave_event)
        if self.browser_pageview_event is not None:
            result["BrowserPageviewEvent"] = from_union([lambda x: to_class(BrowserPageviewEvent, x), from_none], self.browser_pageview_event)
        if self.browser_rageclick_event is not None:
            result["BrowserRageclickEvent"] = from_union([lambda x: to_class(BrowserRageclickEvent, x), from_none], self.browser_rageclick_event)
        if self.custom_event is not None:
            result["CustomEvent"] = from_union([lambda x: to_class(CustomEvent, x), from_none], self.custom_event)
        if self.dead_click_props is not None:
            result["DeadClickProps"] = from_union([lambda x: to_class(DeadClickProps, x), from_none], self.dead_click_props)
        if self.derived_text_meta is not None:
            result["DerivedTextMeta"] = from_union([lambda x: to_class(DerivedTextMeta, x), from_none], self.derived_text_meta)
        if self.mask_mode is not None:
            result["MaskMode"] = from_union([lambda x: to_enum(MaskMode, x), from_none], self.mask_mode)
        if self.metric_value is not None:
            result["MetricValue"] = from_union([to_float, from_none], self.metric_value)
        if self.pageleave_props is not None:
            result["PageleaveProps"] = from_union([lambda x: to_class(PageleaveProps, x), from_none], self.pageleave_props)
        if self.pageview_props is not None:
            result["PageviewProps"] = from_union([lambda x: to_class(PageviewProps, x), from_none], self.pageview_props)
        if self.rageclick_props is not None:
            result["RageclickProps"] = from_union([lambda x: to_class(RageclickProps, x), from_none], self.rageclick_props)
        if self.scroll_depth_props is not None:
            result["ScrollDepthProps"] = from_union([lambda x: to_class(ScrollDepthProps, x), from_none], self.scroll_depth_props)
        if self.token_bucket is not None:
            result["TokenBucket"] = from_union([lambda x: to_enum(TokenBucket, x), from_none], self.token_bucket)
        return result


def events_from_dict(s: Any) -> Events:
    return Events.from_dict(s)


def events_to_dict(x: Events) -> Any:
    return to_class(Events, x)
