"""검증 스위트가 공통으로 쓰는 시나리오 태그.

시나리오 목록의 정본은 ``contracts/calling-sdk/conformance.schema.json`` 이다.
"""

from abto.policy_generated import SERVER_CONFORMANCE_SCENARIOS


def covers(scenario: str) -> None:
    """이 test 가 증명하는 공통 시나리오를 표시한다.

    목록에 없는 id 면 즉시 실패해 오타가 조용히 지나가지 않는다.
    """
    assert scenario in SERVER_CONFORMANCE_SCENARIOS, (
        f"[abto] unknown conformance scenario: {scenario}"
    )
