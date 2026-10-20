import re

from conftest import covers
from abto import (
    ABTO_HEADER,
    AbtoContext,
    create_trace_id,
    create_traceparent,
    get_context,
    get_headers,
    with_context,
)


def test_headers_only_include_set_identifiers():
    covers("context.emits_only_configured_identifiers")
    headers = get_headers(AbtoContext(device_id="d1", feature_id="resume.make"))
    assert headers[ABTO_HEADER["device_id"]] == "d1"
    assert headers[ABTO_HEADER["feature_id"]] == "resume.make"
    assert ABTO_HEADER["traceparent"] not in headers


def test_trace_id_is_sent_as_its_own_header():
    headers = get_headers(AbtoContext(trace_id="run-1"))
    assert headers[ABTO_HEADER["trace_id"]] == "run-1"
    assert ABTO_HEADER["traceparent"] not in headers


def test_create_trace_id_is_uuidv7_hex():
    trace_id = create_trace_id()
    assert re.fullmatch(r"[0-9a-f]{32}", trace_id)
    assert trace_id[12] == "7"
    assert trace_id[16] in "89ab"


def test_outermost_scope_opens_one_trace_shared_by_nested_scopes():
    covers("context.opens_trace_when_absent")
    with with_context(feature_id="agent.plan") as outer:
        with with_context(node_id="agent.write") as inner:
            assert inner.trace_id == outer.trace_id
        with with_context(trace_id=None) as emptied:
            assert emptied.trace_id == outer.trace_id
    with with_context(feature_id="agent.plan") as following:
        pass
    assert re.fullmatch(r"[0-9a-f]{32}", outer.trace_id)
    assert following.trace_id != outer.trace_id
    assert re.fullmatch(r"[0-9a-f]{32}", get_headers(AbtoContext(feature_id="agent.plan"))[ABTO_HEADER["trace_id"]])
    assert get_headers()[ABTO_HEADER["trace_id"]] != get_headers()[ABTO_HEADER["trace_id"]]


def test_explicit_context_keeps_the_scope_trace_on_node_switch():
    covers("context.node_change_keeps_trace")
    with with_context(feature_id="agent.plan") as scope:
        explicit = get_headers(AbtoContext(feature_id="agent.plan", node_id="agent.write"))
    assert explicit[ABTO_HEADER["trace_id"]] == scope.trace_id


def test_with_context_keeps_a_continued_trace_id():
    with with_context(trace_id="run-from-upstream") as ctx:
        assert ctx.trace_id == "run-from-upstream"


def test_with_context_sets_and_resets():
    covers("context.propagates_and_isolates")
    assert get_context().device_id is None
    with with_context(device_id="d2", feature_id="resume.make") as ctx:
        assert ctx.device_id == "d2"
        assert get_context().feature_id == "resume.make"
        assert get_headers()[ABTO_HEADER["device_id"]] == "d2"
    assert get_context().device_id is None


def test_with_context_can_explicitly_clear_an_inherited_value():
    with with_context(device_id="d2", feature_id="resume.make"):
        with with_context(device_id=None) as cleared:
            assert cleared.device_id is None
            assert cleared.feature_id == "resume.make"
        assert get_context().device_id == "d2"


def test_with_context_drops_the_outer_node_when_switching_feature():
    with with_context(feature_id="chat.default", node_id="chat.draft"):
        with with_context(feature_id="chat.default", device_id="d1"):
            assert get_headers()[ABTO_HEADER["node_id"]] == "chat.draft"
        with with_context(node_id="chat.review"):
            assert get_context().feature_id == "chat.default"
            assert get_headers()[ABTO_HEADER["node_id"]] == "chat.review"
        with with_context(feature_id="chat.rewrite"):
            assert ABTO_HEADER["node_id"] not in get_headers()
        with with_context(feature_id="chat.rewrite", node_id="chat.polish"):
            assert get_headers()[ABTO_HEADER["node_id"]] == "chat.polish"
        assert get_context().node_id == "chat.draft"


def test_traceparent_format():
    tp = create_traceparent("b" * 32)
    parts = tp.split("-")
    assert len(parts) == 4
    assert parts[0] == "00" and parts[3] == "01"
