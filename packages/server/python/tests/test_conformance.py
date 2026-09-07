"""공통 시나리오를 모두 덮었는지 test source 를 훑어 확인한다."""

import pathlib
import re

from abto.policy_generated import SERVER_CONFORMANCE_SCENARIOS

_HERE = pathlib.Path(__file__).parent
_TAG = re.compile(r'covers\("([^"]+)"\)')


def _tagged() -> set:
    tagged = set()
    for path in _HERE.glob("test_*.py"):
        if path.name == "test_conformance.py":
            continue
        tagged.update(_TAG.findall(path.read_text()))
    return tagged


def test_every_declared_scenario_is_claimed_by_a_test():
    missing = [s for s in SERVER_CONFORMANCE_SCENARIOS if s not in _tagged()]
    assert missing == [], f"server conformance scenarios not covered by this SDK: {missing}"


def test_no_test_claims_a_scenario_the_contract_does_not_declare():
    unknown = sorted(_tagged() - set(SERVER_CONFORMANCE_SCENARIOS))
    assert unknown == [], f"tests claim scenarios missing from the contract: {unknown}"
