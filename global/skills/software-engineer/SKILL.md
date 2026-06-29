---
name: software-engineer
description: The default disciplined engineering loop for building a feature or fixing a bug — understand, plan, implement in small steps, verify with evidence, self-review before declaring done. Use when the user asks to implement, build, add, fix, change, or refactor something and no more specific skill clearly fits. This is the everyday "do the work well" workflow.
---

# software-engineer

The default workflow for actually building or changing code. It is the
orchestrator: it pulls in the specialist skills/agents at the right moments and
holds the discipline that the global `CLAUDE.md` describes. Use it as the main
loop; reach for a specialist skill when one clearly fits better.

## When NOT to use this

- Starting from a ticket or fresh feature (branch + interactive planning) → `/kickoff`.
- Pure product framing / "should I build this" → `/office-hours`.
- Writing a spec from vague intent → `/spec`.
- Reviewing an existing diff → `/pre-pr-review`.
- Understanding code you didn't write → `/learn-codebase`.
- Investigating a bug whose cause is unknown → `/debugging-incident-review`.

You can still call those from inside this loop — this skill just sequences them.

## The loop

### 1. Understand before touching anything
- Restate the task in one or two sentences. State what's **in scope** and,
  explicitly, what's **out of scope**.
- Surface hidden assumptions and open questions now, not after coding. If the
  ask is fuzzy at the product level, run [[office-hours]] or [[spec]] first.
- Read the actual code you're about to change and its neighbors. Don't assume
  the architecture — inspect it. Find the call sites and existing tests.

### 2. Plan — HARD GATE for medium+ work
- Trivial change (typo, one-liner, obvious localized fix, small contained blast
  radius): skip straight to step 3.
- Everything else — medium-sized-or-larger, per the **Planning gate** in the
  global CLAUDE.md — **write the plan to a project-local file** (default
  `docs/<feature>-plan.md`, or the spec's designated path) covering: files
  likely to change, the approach, scope boundaries, risks, assumptions, and the
  test plan. Keep it **plain English — no code or diffs** (file names and
  described behavior only; literal code waits for step 3). For real blast radius
  use [[implementation-plan]], and consider a second pass from
  [[engineering-plan-review]] (architecture/failure modes) or
  [[design-plan-review]] (UX) before writing code.
- **You may NOT advance to step 3 until I have approved the plan.** Write the
  plan file first, then request approval and **name its path** in the go-ahead
  ask. A complete spec from me does not bypass this gate — a spec is WHAT, the
  plan is HOW. Starting to write files before approval is a process violation,
  not a shortcut. The plan file is the only artifact in this step.
- **Plan on Opus; execute on Sonnet.** Once the plan is agreed, either delegate
  the build to the `software-engineer` subagent (Sonnet) or `/model sonnet`, then
  return to Opus for the step-5 review. See "Model tiering" in the global CLAUDE.md.

### 3. Implement in small, reviewable steps
- Follow the existing style, naming, and patterns of the file you're editing.
- Prefer the smallest change that does the job. No speculative abstraction, no
  "while I'm here" refactors, no unrelated edits. Keep the diff tight.
- Where tests exist or the behavior is testable, write the test first (or
  alongside) and watch it fail, then make it pass. Don't write tests that pass
  even when the implementation is wrong.
- If you're working in a narrow area and want a guardrail against stray edits,
  use [[freeze]]. For risky environments, [[guard]].

### 4. Verify with evidence (do not skip this)
- Run the real checks: lint, typecheck, tests, build — whatever the project has.
  `/health-check` or `~/.claude/scripts/health-check.sh` can run them for you.
- **Evidence before assertions.** Do not claim something works, is fixed, or
  passes until you've run the command and seen the output. When you can't
  verify, say UNVERIFIABLE — never imply DONE because related code shipped.
- Cover the edge cases and failure paths you identified in step 1, not just the
  happy path.

### 5. Self-review before declaring done
- Run [[pre-pr-review]] on your own diff (it's read-only). Treat its verdict
  honestly — fix blockers before you call the work complete.
- If it flags a specialist follow-up (security, tests, architecture, scope),
  run that agent. For a heavier pass, `/deep-codebase-audit current diff`.

### 6. Report honestly
State what you did, what you verified (with the commands/results), what's still
unverified, and any risks. Then stop — don't expand scope on your own.

## Discipline (non-negotiable)

- Tight scope. Touch only what the task needs.
- No broad rewrites unless explicitly asked.
- Respect existing patterns and project-local `CLAUDE.md` over global preferences.
- Separate "the change works" from "I ran it and saw it work." Only the second
  counts as done.
- Honor `careful`/`freeze`/`guard` if active; don't route around the hooks.

## Escalation map

| Situation | Go to |
|---|---|
| Fuzzy product ask | [[office-hours]], [[spec]] |
| Needs a real plan | [[implementation-plan]], [[engineering-plan-review]] |
| Bug with unknown cause | [[debugging-incident-review]] |
| Unfamiliar code | [[learn-codebase]] |
| Risky/large refactor | [[safe-refactor-plan]] |
| Ready to wrap up | [[pre-pr-review]], `/pr-description` |
