# Install this agent skill

The commands require Node.js 22.20 or later.
Use copy mode so each agent receives a real skill directory instead of depending on a global symlink.

## Codex

```bash
npx --yes skills@latest add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent codex \
  --copy \
  --yes
```

Verify:

```bash
npx --yes skills@latest list --global --agent codex
```

The expected global directory is `~/.agents/skills/abto`.
Codex still reads `~/.codex/skills` for backward compatibility, but new user-installed skills use the shared `~/.agents/skills` location.

## Claude Code

```bash
npx --yes skills@latest add https://github.com/greedy-co/abto-sdk/tree/main/abto \
  --skill abto \
  --global \
  --agent claude-code \
  --copy \
  --yes
```

Verify:

```bash
npx --yes skills@latest list --global --agent claude-code
```

The expected global directory is `~/.claude/skills/abto`.

The direct GitHub tree URL restricts discovery and installation to `abto`.
Repositories outside the CLI's blob-download allowlist are still shallow-cloned before that subdirectory is selected.
The installed skill directory contains only the selected skill, but the network fetch is not a sparse checkout.

Restart an agent session after first installation if it does not refresh its skill catalog.

## Update and remove

```bash
npx --yes skills@latest update abto --global --yes
npx --yes skills@latest remove abto --global --agent codex --yes
npx --yes skills@latest remove abto --global --agent claude-code --yes
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

### The command succeeds but the skill is not listed

1. Confirm that `--agent codex` or `--agent claude-code` was used.
2. Confirm that `--copy` was used.
3. Inspect the expected global directory.
4. Re-run the relevant `npx --yes skills@latest list` command.
5. Restart the agent session.
