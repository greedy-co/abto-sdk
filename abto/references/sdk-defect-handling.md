# SDK defect handling

## Contents

- [Confirm the boundary](#confirm-the-boundary)
- [Protect customer code](#protect-customer-code)
- [Fix an authorized upstream defect](#fix-an-authorized-upstream-defect)
- [Release and retry](#release-and-retry)
- [Allow a temporary workaround only as an exception](#allow-a-temporary-workaround-only-as-an-exception)
- [Report the blocked flow](#report-the-blocked-flow)

## Confirm the boundary

Treat unexpected behavior as a suspected defect until evidence separates the integration, Skill guidance, installed artifact, SDK implementation, and ABTO service.
Record only non-sensitive evidence:

- package coordinate, installed version, lockfile resolution, runtime, and environment;
- the released documentation, public type, or public source contract that defines the expected behavior;
- a sanitized minimal operation that reproduces the behavior without copying proprietary customer code;
- expected result, actual result, error, relevant non-secret headers, and whether the behavior reproduces outside the customer application.

Classify the result before changing code:

| Classification | Action |
|---|---|
| Customer integration error | Correct only the approved customer integration path. |
| Skill or documentation error | Correct the Skill or released documentation; do not change SDK runtime code. |
| Version mismatch | Use the verified released API or wait for its public release; do not target unreleased source. |
| Released SDK defect | Mark the affected Core or Event path `blocked-sdk-defect` and use the upstream flow below. |
| Unsupported capability | Report it as incompatible or a product gap; do not invent an adapter. |
| Gateway or collection-service defect | Report the service boundary; do not hide it in SDK or customer code. |

Do not call a behavior a released SDK defect unless it reproduces against the installed public artifact and contradicts a released contract.

## Protect customer code

- Stop adding customer integration code at the affected path.
- Do not edit `node_modules`, package caches, generated vendor source, downloaded artifacts, or lockfile-resolved package contents.
- Do not create a monkey patch, generic wrapper, parallel endpoint, duplicate SDK, or alternate event solely to bypass the defect.
- Preserve unrelated customer changes and do not copy customer secrets, payloads, prompts, responses, or private source into an upstream report or fixture.
- Keep unaffected approved paths only when they still deliver the selected ABTO outcome without depending on the defect.
- Ask for the ABTO SDK source repository path or maintainer handoff when it is unavailable.
- Obtain explicit approval before editing an upstream SDK repository, opening an external issue or PR, publishing a package, or adding a customer workaround.

## Fix an authorized upstream defect

Use the corresponding package directory only after confirming the ABTO monorepo:

| Public package | Upstream package directory |
|---|---|
| `@abto-app/event` | `packages/browser/javascript` |
| `@abto-app/calling` | `packages/server/javascript` |
| `abto[openai]` | `packages/server/python` |
| Dart `abto` | `packages/mobile/dart` |
| `app.abto:abto-app` | `packages/mobile/android` |
| `AbtoApp` | `packages/mobile/swift` |

Add or update the smallest SDK-owned regression check that fails for the sanitized reproduction.
Do not add a customer test scaffold or an Agent Skill text assertion solely to encode this policy.
Change the narrowest SDK implementation surface, preserve its public request and response semantics, and avoid unrelated refactors or coordinated version changes.
Run the affected package's existing test, type, build, and package or artifact checks.

## Release and retry

Treat source fix, merge, registry publication, public source mirror, customer installation, and runtime proof as separate states.
Do not update the Skill compatibility declaration to unreleased source.

After the fix is authorized and merged:

1. Cut only the affected SDK's patch release unless a coordinated release was separately requested.
2. Verify the immutable package in its canonical registry and the matching public source mirror.
3. Refresh the Skill compatibility declaration through the existing release or public-mirror workflow.
4. Update the customer dependency with its existing package manager and lockfile convention.
5. Re-run the original sanitized reproduction and the approved Core or Event path.
6. Remove any approved temporary workaround before changing `blocked-sdk-defect` to `wired`.

## Allow a temporary workaround only as an exception

Default to no customer-side workaround.
Offer one only for a user-confirmed operational need when waiting for a public patch is unacceptable.
Require explicit approval of the exact file, behavior, risk, and removal plan.
Keep it isolated, tied to a defect ID and affected version range, and removable after one fixed public version is installed.
Never patch dependency contents or present the workaround as the SDK fix.

## Report the blocked flow

Keep the required three-section report.
In the affected Core or Event section, report the defect classification, evidence, public version, customer-code impact, approval state, upstream change, release state, and retry result.
Mark later work pending while the public artifact is unavailable.
In the final Mermaid diagram, show the customer path stopped at the defective SDK and the separate upstream fix → release → reinstall → retry loop.
