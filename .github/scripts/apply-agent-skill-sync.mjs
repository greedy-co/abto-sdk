import { createHash } from 'node:crypto';
import {
  cpSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
} from 'node:fs';
import { basename, extname, join, relative, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';

const SKILL_DIRECTORY = 'skills/abto-sdk';
const ALLOWED_ROOT_FILES = new Set(['SKILL.md']);
const ALLOWED_DIRECTORIES = new Map([
  ['agents', new Set(['.yaml'])],
  ['references', new Set(['.md'])],
]);

function publicPath(root, path) {
  return relative(root, path).split(sep).join('/');
}

function collectFiles(root, directory = root, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    const stat = lstatSync(path);
    if (stat.isSymbolicLink()) {
      throw new Error(`Agent Skill sync rejects symbolic links: ${publicPath(root, path)}`);
    }
    if (stat.isDirectory()) {
      collectFiles(root, path, files);
      continue;
    }
    if (!stat.isFile()) {
      throw new Error(`Agent Skill sync only accepts regular files: ${publicPath(root, path)}`);
    }
    if ((stat.mode & 0o111) !== 0) {
      throw new Error(`Agent Skill sync rejects executable files: ${publicPath(root, path)}`);
    }
    files.push({ path, stat });
  }
  return files;
}

function assertAllowedPath(relativePath) {
  const prefix = `${SKILL_DIRECTORY}/`;
  if (!relativePath.startsWith(prefix)) {
    throw new Error(`Agent Skill sync rejects a path outside ${SKILL_DIRECTORY}: ${relativePath}`);
  }

  const skillRelative = relativePath.slice(prefix.length);
  if (ALLOWED_ROOT_FILES.has(skillRelative)) return;

  const [directory, ...segments] = skillRelative.split('/');
  const extensions = ALLOWED_DIRECTORIES.get(directory);
  if (
    extensions
    && segments.length > 0
    && extensions.has(extname(basename(relativePath)))
  ) {
    return;
  }

  throw new Error(`Agent Skill sync rejects a non-allowlisted path: ${relativePath}`);
}

export function applyAgentSkillSync({ candidateRoot, manifestPath, repositoryRoot }) {
  const candidate = resolve(candidateRoot);
  const repository = resolve(repositoryRoot);
  const manifest = JSON.parse(readFileSync(resolve(manifestPath), 'utf8'));

  if (manifest.schemaVersion !== 1 || !Array.isArray(manifest.files)) {
    throw new Error('Agent Skill sync requires a schemaVersion 1 manifest');
  }

  const entries = collectFiles(candidate)
    .map(({ path, stat }) => ({
      path,
      relativePath: publicPath(candidate, path),
      stat,
    }))
    .sort((left, right) => left.relativePath.localeCompare(right.relativePath));

  if (entries.length !== manifest.fileCount || entries.length !== manifest.files.length) {
    throw new Error('Agent Skill sync file count does not match the verified manifest');
  }

  const aggregate = createHash('sha256');
  for (const [index, entry] of entries.entries()) {
    assertAllowedPath(entry.relativePath);
    const expected = manifest.files[index];
    const buffer = readFileSync(entry.path);
    const sha256 = createHash('sha256').update(buffer).digest('hex');

    if (
      expected.path !== entry.relativePath
      || expected.bytes !== buffer.length
      || expected.sha256 !== sha256
    ) {
      throw new Error(`Agent Skill sync manifest mismatch for ${entry.relativePath}`);
    }

    aggregate.update(entry.relativePath);
    aggregate.update('\0');
    aggregate.update(sha256);
    aggregate.update('\0');
  }

  const aggregateSha256 = aggregate.digest('hex');
  if (aggregateSha256 !== manifest.sha256) {
    throw new Error('Agent Skill sync aggregate hash does not match the verified manifest');
  }

  const sourceSkill = join(candidate, SKILL_DIRECTORY);
  const destinationSkill = join(repository, SKILL_DIRECTORY);
  rmSync(destinationSkill, { recursive: true, force: true });
  mkdirSync(join(destinationSkill, '..'), { recursive: true });
  cpSync(sourceSkill, destinationSkill, { recursive: true });

  return manifest;
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : '';
if (import.meta.url === invokedPath) {
  const [candidateRoot, manifestPath, repositoryRoot] = process.argv.slice(2);
  if (!candidateRoot || !manifestPath || !repositoryRoot) {
    console.error(
      'usage: node .github/scripts/apply-agent-skill-sync.mjs <candidate-root> <manifest> <repository-root>',
    );
    process.exit(1);
  }

  const manifest = applyAgentSkillSync({
    candidateRoot,
    manifestPath,
    repositoryRoot,
  });
  console.log(`✓ applied verified Agent Skill ${manifest.sha256}`);
}
