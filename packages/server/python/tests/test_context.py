from abto import (
    ABTO_HEADER,
    AbtoContext,
    create_traceparent,
    get_context,
    get_headers,
    with_context,
)


def test_headers_only_include_set_identifiers():
    headers = get_headers(AbtoContext(device_id="d1", node_key="resume.make"))
    assert headers[ABTO_HEADER["device_id"]] == "d1"
    assert headers[ABTO_HEADER["node_key"]] == "resume.make"
    assert ABTO_HEADER["traceparent"] not in headers


def test_trace_id_becomes_traceparent():
    headers = get_headers(AbtoContext(trace_id="a" * 32))
    assert headers[ABTO_HEADER["traceparent"]].startswith("00-" + "a" * 32 + "-")


def test_with_context_sets_and_resets():
    assert get_context().device_id is None
    with with_context(device_id="d2", node_key="resume.make") as ctx:
        assert ctx.device_id == "d2"
        assert get_context().node_key == "resume.make"
        assert get_headers()[ABTO_HEADER["device_id"]] == "d2"
    assert get_context().device_id is None


def test_with_context_can_explicitly_clear_an_inherited_value():
    with with_context(device_id="d2", node_key="resume.make"):
        with with_context(device_id=None) as cleared:
            assert cleared.device_id is None
            assert cleared.node_key == "resume.make"
        assert get_context().device_id == "d2"


def test_traceparent_format():
    tp = create_traceparent("b" * 32)
    parts = tp.split("-")
    assert len(parts) == 4
    assert parts[0] == "00" and parts[3] == "01"
