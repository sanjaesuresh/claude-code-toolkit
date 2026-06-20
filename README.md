# claude-code-toolkit

A private, portable Claude Code setup: reusable **skills**, **subagents**,
**hooks**, **safety guardrails**, and **project templates** that turn Claude Code
into a *team of specialists* — product, engineering, design, security, QA, and
release — instead of one generic assistant.

It is designed to be **safe**, **reusable**, and **work-safe**: usable on
personal projects and inside an employer environment (e.g. Bloomberg) **without
encoding any proprietary information**.

## What this is

- **Global, generic tooling** lives in `global/` and installs into `~/.claude`.
- **Project-specific** context stays in each repo's own `CLAUDE.md` / `.claude/`.
- **Local/private** settings (`settings.local.json`, credentials, saved context)
  are never committed and never synced into this repo.

## Inspiration (not a dependency)

The role-based structure is inspired by Garry Tan's open-source
[`gstack`](https://github.com/garrytan/gstack) — the strongest ideas borrowed:
role-based specialists, plan-before-implementation, a skeptical pre-merge review
culture, `careful`/`freeze`/`guard` safety hooks, context save/restore, health
checks, and Diataxis docs.

This toolkit **does not depend on gstack** and does not clone it. It is simpler,
private, and hardened for work use:

- ~23 skills + ~17 agents, all plain markdown — no external binaries, no telemetry,
  no analytics directory, no required browser automation.
- Every reusable file is generic; nothing proprietary is ever persisted globally.
- Safety hooks are minimal and "careful, not annoying" (confirm, don't block).

You do **not** need to install gstack. Recommended: keep this toolkit standalone.

## Repo layout

```
claude-code-toolkit/
  README.md
  bootstrap.sh / bootstrap.ps1     # one-shot install (mac/linux | windows)
  .gitignore                       # aggressive: nothing private lands here
  global/                          # installs into ~/.claude
    CLAUDE.md                      # global operating instructions
    settings.json                  # safe starter settings + hooks
    skills/<name>/SKILL.md         # 23 reusable skills
    agents/<name>.md               # 17 reusable subagents
  templates/                       # examples to copy into real repos
    project-claude.md              # example project CLAUDE.md
    project-settings.json          # example project .claude/settings.json
    create-new-skill.prompt.md     # scaffold a new skill
    create-new-agent.prompt.md     # scaffold a new agent
    project-skills/  project-agents/  # drop project-specific ones here
  scripts/                         # hook + helper scripts (install to ~/.claude/scripts)
    install.sh  sync.sh  validate-claude-config.sh
    block-dangerous-commands.sh  freeze-edits.sh  unfreeze-edits.sh  notify.sh
    context-save.sh  context-restore.sh  health-check.sh
```

## Install

```bash
git clone https://github.com/sanjaesuresh/claude-code-toolkit.git
cd claude-code-toolkit
bash bootstrap.sh                  # copy mode (default, safe everywhere)
# or: bash bootstrap.sh --symlink  # symlink mode (personal machines)
```

Windows (PowerShell, copy mode only):

```powershell
git clone https://github.com/sanjaesuresh/claude-code-toolkit.git
cd claude-code-toolkit
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Install copies `CLAUDE.md`, `settings.json`, `skills/`, `agents/`, and `scripts/`
into `~/.claude`, makes scripts executable, **backs up** anything it overwrites
(`~/.claude/.toolkit-backups/<timestamp>/`), and **never** touches
`settings.local.json` or credentials.

> Symlink vs copy: **copy is the default** because some corporate environments
> dislike symlinks. Use `--symlink` only on machines you control.

## Sync across machines

On each machine after the first:

```bash
cd claude-code-toolkit
bash scripts/sync.sh               # git pull --ff-only + re-install (copy mode)
bash scripts/sync.sh --symlink     # ...symlink mode
bash scripts/sync.sh --no-pull     # re-install without pulling
```

## Verify the install

```bash
bash scripts/validate-claude-config.sh        # checks ~/.claude
bash scripts/validate-claude-config.sh --repo # checks this repo's global/
```

## Using the workflows

Invoke any skill by `/name` (or just describe the task — descriptions are written
so Claude auto-invokes the right one).

### Build something (the default loop)

```
/software-engineer
```

The everyday engineering loop: understand → plan → implement in small steps →
verify with evidence → self-review before declaring done. It's the orchestrator
that pulls in the specialists below at the right moments and holds scope tight.
Use it when you're actually building or fixing and no more specific skill fits.

### Plan first

| Command | Role | Use it to |
|---|---|---|
| `/office-hours` | Founder/mentor | Challenge a product idea before building |
| `/spec` | — | Turn vague intent into a precise, executable spec |
| `/implementation-plan` | — | Scoped plan + risks before any code |
| `/product-plan-review` | Product/founder | Review a feature plan (expand / hold / cut) |
| `/engineering-plan-review` | Eng manager | Architecture, failure modes, tests, rollout |
| `/design-plan-review` | Designer-coder | Score a UX plan, find the 10/10 |

### Pre-PR review (the centerpiece)

```
/pre-pr-review
```

Strict, **read-only** review of your current diff: task completion, scope creep,
AI slop, correctness, tests, security, and production-risk bugs that pass CI.
Ends with a verdict, a prioritized issue list, test gaps, a suggested PR
description, and a final checklist. It recommends specialist follow-ups
(security, tests, architecture, scope) when warranted. For a fresh second
opinion, the `pre-pr-reviewer` subagent runs the same review in isolation.

### Learn a codebase

```
/learn-codebase how does auth work here
```

Reads the real implementation and teaches it: 30-second explanation, code map,
the main call flow, key data, edge cases, what the tests prove, and how to change
it safely. The `codebase-teacher` subagent does the same in an isolated context.
For whole-repo orientation use `/onboarding-map`.

### Deep audit

```
/deep-codebase-audit current diff
```

Fans out the relevant specialist subagents in parallel and synthesizes one
report with the top issues to fix first — and what *not* to churn.

### Safety: careful / freeze / guard

```
/careful            # warn + confirm before destructive shell commands
/freeze src/auth    # block edits outside src/auth this session
/guard src/auth     # careful + freeze together (max safety)
/unfreeze           # lift the freeze   (or: bash ~/.claude/scripts/unfreeze-edits.sh)
```

These are enforced by global `PreToolUse` hooks. Safe cleanups
(`rm -rf node_modules`, `dist`, `build`, ...) pass through silently. The freeze
lock prevents accidental `Edit`/`Write` outside scope — it is not a security
boundary (Bash can still write anywhere).

### Context save / restore

```
/context-save       # save task, decisions, git state, remaining work (project-local)
/context-restore    # resume and reconcile with current git state
```

Saved context defaults to `.claude/context/current-session.md` (gitignored,
project-local). It scans for secrets/PII first and **warns before writing**.
Work context is **never** synced into this toolkit or global memory.

### Health & ship

```
/health-check       # lint/typecheck/test/build score + top fixes
/pr-description     # PR description from the diff + validation
```

## Add a new skill or agent

Paste the relevant template prompt into Claude Code:

- New skill: `templates/create-new-skill.prompt.md`
- New agent: `templates/create-new-agent.prompt.md`

Each asks the right questions and tells you whether it should be **global** (put
it in `global/skills` or `global/agents` here) or **project-specific** (put it in
the repo's `.claude/skills` or `.claude/agents` — or stage it under
`templates/project-skills` / `templates/project-agents`), and whether it is safe
for work repos.

## Global vs project-specific

- **Global** (this repo → `~/.claude`): generic skills/agents/instructions that
  apply everywhere. Must contain **no** project or employer specifics.
- **Project** (a repo's own `CLAUDE.md` / `.claude/`): everything specific to
  that codebase. A project `CLAUDE.md` **overrides** the global one on conflict.
- Use `templates/project-claude.md` and `templates/project-settings.json` as
  starting points for a new repo.

## Work / Bloomberg safety rules

Read this before using the toolkit at work.

- **Never persist proprietary/work information into global files** — not into
  `~/.claude/CLAUDE.md`, global skills/agents, saved contexts, generated docs, or
  this toolkit repo.
- Do **not** copy internal code, repo/service names, internal URLs, logs, stack
  traces, screenshots, secrets, or proprietary architecture into any reusable file.
- In a **work repo, rely only on that repo's local `CLAUDE.md` / `.claude/` and
  the current session** for project context.
- `context-save` and `docs-generate` default to **project-local, gitignored**
  files and scan for secrets/PII before writing.
- The global `CLAUDE.md` already encodes these rules so every session honors them.
- **Check your employer's policy** before installing third-party tooling or
  enabling hooks on a work device.

### What must never be committed (here or anywhere)

`settings.local.json`, `.credentials.json`, `.claude.json`, `.env*`, any secrets
or tokens, saved session context, and anything project/employer-specific. The
`.gitignore` enforces the obvious cases, but treat it as a backstop, not a license.

## Test the setup

1. `bash scripts/validate-claude-config.sh --repo` — structure + JSON + frontmatter.
2. Install into `~/.claude`, then `bash scripts/validate-claude-config.sh`.
3. In a throwaway personal repo, try: `/office-hours`, `/spec`,
   `/engineering-plan-review`, `/pre-pr-review`, `/learn-codebase <topic>`,
   `/careful`, `/freeze <path>` then try editing outside it (should be blocked),
   `/unfreeze`, `/context-save` then `/context-restore`, `/health-check`.
4. Confirm a dangerous command (e.g. `git reset --hard`) prompts for confirmation
   and that `rm -rf node_modules` does not.

## Recommended rollout order

1. Create the private repo.
2. Add global `CLAUDE.md`.
3. Add safety skills: `careful`, `freeze`, `guard`.
4. Add `pre-pr-review` skill.
5. Add `learn-codebase` skill.
6. Add `pre-pr-reviewer` agent.
7. Add `codebase-teacher` agent.
8. Add `scope-guardian`, `ai-slop-detector`, `security-reviewer`, `test-strategist`.
9. Add planning skills: `office-hours`, `spec`, `product-plan-review`,
   `engineering-plan-review`, `design-plan-review`.
10. Add the bootstrap script.
11. Test on a personal repo.
12. Only then install on a work device — **after checking internal policy**.

## License

Private. For personal use across your own machines.
