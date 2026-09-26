#!/usr/bin/env bash
# Verify the public Python package in a clean environment before publishing.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
verification_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/abto-python-verify.XXXXXX")"
trap 'rm -rf -- "$verification_dir"' EXIT
unset PYTHONPATH PYTHONHOME

python3 -m venv "$verification_dir/venv"
verification_python="$verification_dir/venv/bin/python"
cd "$repo_root/packages/server/python"
"$verification_python" -m pip install --upgrade build pytest
"$verification_python" -m build
wheels=( "$repo_root"/packages/server/python/dist/*.whl )
test "${#wheels[@]}" -eq 1
test -f "${wheels[0]}"
"$verification_python" -m pip install "${wheels[0]}[openai]"
# Run outside the source tree so imports exercise the wheel to be published.
cd "$verification_dir"
"$verification_python" -m pytest "$repo_root/packages/server/python/tests"
