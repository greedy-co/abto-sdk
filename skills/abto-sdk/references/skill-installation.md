# Install this agent skill

The commands require Node.js 22.20 or later.
Use copy mode so each agent receives a real skill directory instead of depending on a global symlink.

## Codex

```bash
npx skills add https://github.com/greedy-co/abto-sdk \
  --skill abto-sdk \
  --global \
  --agent codex \
  --copy \
  --yes
```

Verify:

```bash
npx skills list --global --agent codex
```

The expected global directory is `~/.agents/skills/abto-sdk`.
Codex still reads `~/.codex/skills` for backward compatibility, but new user-installed
skills use the shared `~/.agents/skills` location.

## Claude Code

```bash
npx skills add https://github.com/greedy-co/abto-sdk \
  --skill abto-sdk \
  --global \
  --agent claude-code \
  --copy \
  --yes
```

Verify:

```bash
npx skills list --global --agent claude-code
```

The expected global directory is `~/.claude/skills/abto-sdk`.

Restart an agent session after first installation if it does not refresh its skill catalog.

## Update and remove

```bash
npx skills update abto-sdk --global --yes
npx skills remove abto-sdk --global --agent codex --yes
npx skills remove abto-sdk --global --agent claude-code --yes
```

If a project-local skill with the same name exists, inspect both before removing anything.
Prefer one source of truth for a workspace.
Do not overwrite a locally modified skill without showing the diff and getting approval.

## Troubleshooting

### `npx` is missing

```bash
node --version
npm --version
npx --version
```

Install a supported Node.js release with the user's existing version manager.
Do not introduce a second version manager.

### mise reports no version for the `npx` shim

```bash
mise current node
mise ls node
```

If a compatible version is already installed, activate it in the intended scope with `mise use`.
Ask before changing a global default.
Use Node.js 22.20 or later because the current `skills` CLI requires it.

### The command succeeds but the skill is not listed

1. Confirm that `--agent codex` or `--agent claude-code` was used.
2. Confirm that `--copy` was used.
3. Inspect the expected global directory.
4. Re-run the relevant `npx skills list` command.
5. Restart the agent session.

### The repository cannot be fetched

Confirm network access to GitHub and retry the exact command.
Do not substitute an untrusted fork or copy a skill from an unknown source.
