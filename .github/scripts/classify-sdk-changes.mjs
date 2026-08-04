import { readFileSync } from 'node:fs';
import { basename, extname } from 'node:path';

const DOCUMENTATION_EXTENSIONS = new Set(['.adoc', '.markdown', '.md', '.mdx', '.rst']);

const TARGET_PATHS = Object.freeze({
  'event-js': ['packages/browser/javascript/'],
  'calling-js': ['packages/server/javascript/'],
  'calling-python': ['packages/server/python/'],
  dart: ['packages/mobile/dart/'],
  android: ['packages/mobile/android/'],
  swift: ['packages/mobile/swift/', 'Package.swift'],
});

const ALL_CHANGE_PATHS = new Set([
  '.env.sdk-release.example',
  '.gitignore',
  '.github/scripts/classify-sdk-changes.mjs',
  '.github/workflows/auto-release-sdks.yml',
  '.github/workflows/ci.yml',
  '.github/workflows/cut-release.yml',
  '.github/workflows/publish-sdks.yml',
  '.github/workflows/sdk-verify.yml',
  '.github/workflows/sync-agent-skill.yml',
  'LICENSE',
  'scripts/auto-sdk-release-plan.mjs',
  'scripts/auto-sdk-release-plan.test.mjs',
  'scripts/check-js-sdk-boundaries.mjs',
  'scripts/check-npm-release.mjs',
  'scripts/check-npm-release.test.mjs',
  'scripts/check-python-release-artifacts.py',
  'scripts/check-python-release-artifacts.test.py',
  'scripts/check-public-sdk-promotion.mjs',
  'scripts/check-public-sdk-promotion.test.mjs',
  'scripts/check-sdk-publish-gate.mjs',
  'scripts/check-sdk-publish-gate.test.mjs',
  'scripts/check-sdk-recovery-registry.mjs',
  'scripts/check-sdk-recovery-registry.test.mjs',
  'scripts/check-sdk-versions.mjs',
  'scripts/classify-sdk-changes.mjs',
  'scripts/classify-sdk-changes.test.mjs',
  'scripts/create-central-bundle.sh',
  'scripts/publish-central-bundle.sh',
  'scripts/set-sdk-version.mjs',
  'scripts/set-sdk-version.test.mjs',
  'scripts/set-version.mjs',
]);

const PUBLIC_CHANGE_PATHS = new Set([
  '.github/workflows/sync-agent-skill.yml',
  'scripts/apply-public-documentation-sync.mjs',
  'scripts/apply-agent-skill-sync.mjs',
  'scripts/check-agent-skill-sdk-compatibility.mjs',
  'scripts/classify-sdk-changes.mjs',
  'scripts/classify-sdk-changes.test.mjs',
  'scripts/overlay-public-sdk.mjs',
  'scripts/verify-public-sdk.mjs',
  'scripts/write-agent-skill-sdk-compatibility.mjs',
  'scripts/write-agent-skill-sdk-compatibility.test.mjs',
]);

function normalizePath(path) {
  return path.trim().replaceAll('\\', '/').replace(/^\.\//, '');
}

function matchesPath(path, candidate) {
  return candidate.endsWith('/') ? path.startsWith(candidate) : path === candidate;
}

export function isDocumentationPath(path) {
  return DOCUMENTATION_EXTENSIONS.has(extname(normalizePath(path)).toLowerCase());
}

export function isRuntimeChangeForTarget(target, path) {
  const candidates = TARGET_PATHS[target];
  if (!candidates) throw new Error(`unknown SDK change target ${target}`);
  const normalized = normalizePath(path);
  return !isDocumentationPath(normalized)
    && candidates.some((candidate) => matchesPath(normalized, candidate));
}

function affectsPublicMirror(path) {
  return path.startsWith('packages/')
    || path.startsWith('abto/')
    || PUBLIC_CHANGE_PATHS.has(path);
}

export function classifySdkChanges(paths, { forceAll = false } = {}) {
  const normalizedPaths = paths.map(normalizePath).filter(Boolean);
  const all = forceAll || normalizedPaths.some((path) => ALL_CHANGE_PATHS.has(path));
  const targetChanged = (target) => all
    || normalizedPaths.some((path) => isRuntimeChangeForTarget(target, path));

  const eventJs = targetChanged('event-js');
  const callingJs = targetChanged('calling-js');
  const python = targetChanged('calling-python');
  const dart = targetChanged('dart');
  const android = targetChanged('android');
  const swift = targetChanged('swift');

  return {
    all,
    browser: eventJs,
    server: callingJs,
    event_js: eventJs,
    calling_js: callingJs,
    python,
    dart,
    android,
    swift,
    actions: all || normalizedPaths.some((path) => path.startsWith('.github/workflows/')),
    sdk: all || eventJs || callingJs || python || dart || android || swift,
    agent_skill: all
      || eventJs
      || callingJs
      || python
      || dart
      || android
      || swift
      || normalizedPaths.some((path) => path.startsWith('abto/')),
    public: normalizedPaths.some(affectsPublicMirror),
  };
}

if (basename(process.argv[1] ?? '') === 'classify-sdk-changes.mjs') {
  const args = process.argv.slice(2);
  if (args.some((arg) => arg !== '--all')) {
    console.error('usage: node scripts/classify-sdk-changes.mjs [--all] < changed-paths.txt');
    process.exit(1);
  }
  const flags = classifySdkChanges(readFileSync(0, 'utf8').split('\n'), {
    forceAll: args.includes('--all'),
  });
  for (const [name, value] of Object.entries(flags)) {
    console.log(`${name}=${value}`);
  }
}
