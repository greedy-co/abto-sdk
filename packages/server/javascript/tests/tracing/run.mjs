import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { cpSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const root = resolve('.');
const temporary = mkdtempSync(join(tmpdir(), 'abto-calling-tracing-'));
function run(command, args, cwd = temporary) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', timeout: 180000 });
  if (result.status !== 0) throw new Error(`${command} failed\n${result.stdout}\n${result.stderr}`, { cause: result.error });
  return result.stdout;
}
try {
  const packed = JSON.parse(run('npm', ['pack', '--ignore-scripts', '--json', '--pack-destination', temporary], root))[0];
  cpSync(join(root, 'tests/tracing/server.mjs'), join(temporary, 'server.mjs'));
  for (const version of ['legacy', 'modern']) {
    const fixture = join(temporary, version);
    cpSync(join(root, 'tests/tracing', version), fixture, { recursive: true });
    cpSync(join(root, 'tests/tracing/probe.mjs'), join(fixture, 'probe.mjs'));
    run('npm', ['ci', '--ignore-scripts', '--no-audit', '--no-fund'], fixture);
    run('npm', ['install', '--ignore-scripts', '--no-audit', '--no-fund', '--no-save', '--package-lock=false', join(temporary, packed.filename)], fixture);
    const output = run(process.execPath, ['probe.mjs', version], fixture);
    const report = JSON.parse(readFileSync(join(fixture, 'report.json')));
    assert.equal(report.status, 'passed');
    console.log(output.trim());
  }
} finally {
  rmSync(temporary, { recursive: true, force: true });
}
