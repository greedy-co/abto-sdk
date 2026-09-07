// @vitest-environment node
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from 'vitest';

import { SERVER_CONFORMANCE_SCENARIOS } from './policy.generated.js';

const here = dirname(fileURLToPath(import.meta.url));

function taggedScenarios(): Set<string> {
  const tagged = new Set<string>();
  for (const entry of readdirSync(here)) {
    if (!entry.endsWith('.test.ts') || entry === 'conformance.test.ts') continue;
    const source = readFileSync(join(here, entry), 'utf8');
    for (const match of source.matchAll(/covers\('([^']+)'\)/g)) tagged.add(match[1]!);
  }
  return tagged;
}

describe('server conformance', () => {
  it('every declared scenario is claimed by a test', () => {
    const tagged = taggedScenarios();
    const missing = (SERVER_CONFORMANCE_SCENARIOS as readonly string[])
      .filter((scenario) => !tagged.has(scenario));
    expect(missing, 'server conformance scenarios not covered by this SDK').toEqual([]);
  });

  it('no test claims a scenario the contract does not declare', () => {
    const declared = new Set<string>(SERVER_CONFORMANCE_SCENARIOS as readonly string[]);
    const unknown = [...taggedScenarios()].filter((scenario) => !declared.has(scenario));
    expect(unknown, 'tests claim scenarios missing from the contract').toEqual([]);
  });
});
