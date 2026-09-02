import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const tagPattern = /^(event-js-v|calling-js-v|calling-python-v|dart-v|android-v|swift-v|v)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z.-]+))?$/;

function parseTag(tag) {
  const match = tagPattern.exec(tag.trim());
  if (!match) return null;
  return {
    tag: match[0],
    prefix: match[1],
    major: Number(match[2]),
    minor: Number(match[3]),
    patch: Number(match[4]),
    prerelease: match[5]?.split('.') ?? [],
  };
}

function comparePrerelease(left, right) {
  if (left.length === 0 || right.length === 0) {
    return left.length === right.length ? 0 : left.length === 0 ? 1 : -1;
  }
  const length = Math.max(left.length, right.length);
  for (let index = 0; index < length; index += 1) {
    const leftPart = left[index];
    const rightPart = right[index];
    if (leftPart === undefined || rightPart === undefined) {
      return leftPart === rightPart ? 0 : leftPart === undefined ? -1 : 1;
    }
    if (leftPart === rightPart) continue;
    const leftNumeric = /^\d+$/.test(leftPart);
    const rightNumeric = /^\d+$/.test(rightPart);
    if (leftNumeric && rightNumeric) {
      if (leftPart.length !== rightPart.length) return leftPart.length < rightPart.length ? -1 : 1;
      return leftPart < rightPart ? -1 : 1;
    }
    if (leftNumeric !== rightNumeric) return leftNumeric ? -1 : 1;
    return leftPart < rightPart ? -1 : 1;
  }
  return 0;
}

function compareVersions(left, right) {
  for (const field of ['major', 'minor', 'patch']) {
    const difference = left[field] - right[field];
    if (difference !== 0) return Math.sign(difference);
  }
  return Math.sign(comparePrerelease(left.prerelease, right.prerelease));
}

export function previousSdkReleaseTag(currentTag, tags) {
  const current = parseTag(currentTag ?? '');
  if (!current) throw new Error(`unsupported SDK release tag ${currentTag ?? '(missing)'}`);

  const candidates = [...new Set(tags)]
    .map(parseTag)
    .filter((tag) => tag?.prefix === current.prefix && compareVersions(tag, current) < 0)
    .sort(compareVersions);
  return candidates.at(-1)?.tag ?? '';
}

const invokedPath = process.argv[1] ? pathToFileURL(process.argv[1]).href : '';
if (import.meta.url === invokedPath) {
  try {
    const tags = readFileSync(0, 'utf8').split(/\r?\n/).filter(Boolean);
    console.log(previousSdkReleaseTag(process.argv[2], tags));
  } catch (error) {
    console.error(`✗ ${error.message}`);
    process.exit(1);
  }
}
