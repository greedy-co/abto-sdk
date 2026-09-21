import assert from 'node:assert/strict';
import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve('.');
const temporary = mkdtempSync(join(tmpdir(), 'abto-calling-package-'));
function run(command, args, cwd = temporary) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', env: process.env });
  if (result.status !== 0) throw new Error(`${command} ${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
  if (result.stdout.trim() && !args.includes('--json')) console.log(result.stdout.trim());
  return result.stdout;
}
try {
  const packed = JSON.parse(run('npm', ['pack', '--ignore-scripts', '--json', '--pack-destination', temporary], root))[0];
  const tarball = join(temporary, packed.filename);
  assert(packed.files.some(file => file.path === 'dist/cjs/index.js'));
  assert(packed.files.some(file => file.path === 'dist/index.d.ts'));
  // A transport-only consumer must not need an installed OpenAI package.
  run('npm', ['install', '--ignore-scripts', '--no-audit', '--no-fund', tarball]);
  const node = process.env.ABTO_TEST_NODE || process.execPath;
  run(node, ['--input-type=module', '-e', `
    import assert from 'node:assert/strict';
    import { createRequire } from 'node:module';
    import { initAbto } from '@abto-app/calling';
    const require = createRequire(import.meta.url);
    assert.throws(() => require.resolve('openai'), { code: 'MODULE_NOT_FOUND' });
    assert.equal(initAbto, require('@abto-app/calling').initAbto);
    const options = initAbto({ abtoApiKey: 'test', gatewayBaseURL: 'https://gateway.abto.app/v1' }).openaiOptions();
    assert.equal(typeof options.fetch, 'function');
  `]);
  cpSync(join(root, 'tests/fixtures'), temporary, { recursive: true });
  run('npm', ['ci', '--ignore-scripts', '--no-audit', '--no-fund']);
  run('npm', ['install', '--ignore-scripts', '--no-audit', '--no-fund', '--no-save', '--package-lock=false', tarball]);
  const typescript = join(temporary, 'node_modules/typescript/bin/tsc');
  const common = ['--noEmit', '--strict', '--skipLibCheck', '--target', 'ES2022', '--esModuleInterop'];
  run(node, [typescript, ...common, '--module', 'commonjs', '--moduleResolution', 'node', 'types.ts']);
  writeFileSync(join(temporary, 'types.mts'), readFileSync(join(temporary, 'types.ts')));
  run(node, [typescript, ...common, '--module', 'NodeNext', '--moduleResolution', 'NodeNext', 'types.mts']);
  writeFileSync(join(temporary, 'types.cts'), readFileSync(join(temporary, 'types.ts')));
  run(node, [typescript, ...common, '--module', 'NodeNext', '--moduleResolution', 'NodeNext', 'types.cts']);
  run(node, ['runtime.cjs']);
  run(node, ['node_modules/ts-node/dist/bin.js', '-T', '--compiler-options', '{"module":"commonjs","moduleResolution":"node"}', 'types.ts']);
  run(node, ['node_modules/esbuild/bin/esbuild', 'runtime.cjs', '--bundle', '--platform=node', '--format=cjs', '--packages=external', '--outfile=bundled.cjs']);
  run(node, ['bundled.cjs']);
} finally {
  rmSync(temporary, { recursive: true, force: true });
}
