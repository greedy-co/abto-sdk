import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

export function publishedReleaseState({
  expectedName,
  expectedVersion,
  localPackage,
  registryPackage,
}) {
  if (localPackage.name !== expectedName || localPackage.version !== expectedVersion) {
    throw new Error(
      `local npm package is ${localPackage.name}@${localPackage.version}, expected ${expectedName}@${expectedVersion}`,
    );
  }
  if (registryPackage === null) {
    return { alreadyPublished: false };
  }
  if (registryPackage.name !== expectedName || registryPackage.version !== expectedVersion) {
    throw new Error(
      `registry returned ${registryPackage.name}@${registryPackage.version}, expected ${expectedName}@${expectedVersion}`,
    );
  }
  if (!registryPackage.dist?.integrity) {
    throw new Error(`registry package ${expectedName}@${expectedVersion} has no dist.integrity`);
  }
  if (localPackage.integrity !== registryPackage.dist.integrity) {
    throw new Error(
      `published npm artifact ${expectedName}@${expectedVersion} does not match the release source`,
    );
  }
  return { alreadyPublished: true };
}

function pack(packageDirectory) {
  const destination = mkdtempSync(join(tmpdir(), 'abto-npm-release-'));
  try {
    const result = spawnSync(
      'npm',
      ['pack', '--json', '--ignore-scripts', '--pack-destination', destination, packageDirectory],
      { encoding: 'utf8' },
    );
    if (result.status !== 0) {
      throw new Error(`npm pack failed: ${result.stderr.trim() || result.stdout.trim()}`);
    }
    const packages = JSON.parse(result.stdout);
    if (!Array.isArray(packages) || packages.length !== 1) {
      throw new Error('npm pack did not return exactly one package');
    }
    return packages[0];
  } finally {
    rmSync(destination, { recursive: true, force: true });
  }
}

async function fetchRegistryPackage(name, version) {
  const packagePath = encodeURIComponent(name);
  const response = await fetch(`https://registry.npmjs.org/${packagePath}/${version}`, {
    headers: { accept: 'application/json' },
  });
  if (response.status === 404) {
    return null;
  }
  if (!response.ok) {
    throw new Error(
      `npm registry lookup failed for ${name}@${version}: HTTP ${response.status}`,
    );
  }
  return response.json();
}

async function runCli(args) {
  const [packageDirectory, expectedName, expectedVersion] = args;
  if (!packageDirectory || !expectedName || !expectedVersion) {
    throw new Error(
      'usage: node scripts/check-npm-release.mjs <package-directory> <package-name> <version>',
    );
  }
  const state = publishedReleaseState({
    expectedName,
    expectedVersion,
    localPackage: pack(resolve(packageDirectory)),
    registryPackage: await fetchRegistryPackage(expectedName, expectedVersion),
  });
  process.stdout.write(`already_published=${state.alreadyPublished}\n`);
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : '';
if (import.meta.url === invokedPath) {
  try {
    await runCli(process.argv.slice(2));
  } catch (error) {
    console.error(`::error::${error instanceof Error ? error.message : String(error)}`);
    process.exitCode = 1;
  }
}
