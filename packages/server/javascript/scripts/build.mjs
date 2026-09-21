import { rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';

const require = createRequire(import.meta.url);
rmSync('dist', { recursive: true, force: true });
const result = spawnSync(process.execPath, [require.resolve('typescript/bin/tsc'),
  '--module', 'commonjs', '--moduleResolution', 'node', '--outDir', 'dist/cjs',
], { stdio: 'inherit' });
if (result.status !== 0) process.exit(result.status ?? 1);

// Both entry points load the same implementation and AsyncLocalStorage instance.
writeFileSync('dist/cjs/package.json', '{"type":"commonjs"}\n');
const exports = Object.keys(require('../dist/cjs/index.js')).filter(key => key !== '__esModule');
writeFileSync('dist/index.js', `import sdk from './cjs/index.js';\nexport const { ${exports.join(', ')} } = sdk;\n`);
writeFileSync('dist/index.d.ts', "export * from './cjs/index.js';\n");
