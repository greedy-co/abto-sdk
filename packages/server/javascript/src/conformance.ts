// 검증 스위트가 공통으로 쓰는 시나리오 태그.
// 시나리오 목록의 정본은 contracts/calling-sdk/conformance.schema.json 이다.
import { SERVER_CONFORMANCE_SCENARIOS } from './policy.generated.js';

/**
 * 이 test 가 증명하는 공통 시나리오를 표시한다.
 *
 * 목록에 없는 id 면 즉시 실패해 오타가 조용히 지나가지 않는다.
 * 어느 시나리오가 아직 비었는지는 conformance.test.ts 가 test source 를 훑어 판정한다 —
 * vitest 는 파일마다 워커가 달라 런타임 집계로는 파일 간 커버리지를 모을 수 없다.
 */
export function covers(scenario: string): void {
  if (!(SERVER_CONFORMANCE_SCENARIOS as readonly string[]).includes(scenario)) {
    throw new Error(`[abto] unknown conformance scenario: ${scenario}`);
  }
}
