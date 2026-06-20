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

### 2. Plan (scale the rigor to the risk)
- Trivial change (typo, one-liner, obvious fix): skip straight to step 3.
- Non-trivial change: produce a short plan — files likely to change, the
  approach, risks, and the test plan. For anything with real blast radius use
  [[implementation-plan]], and consider a second pass from
  [[engineering-plan-review]] (architecture/failure modes) or
  [[design-plan-review]] (UX) before writing code.
- **Get the plan agreed before implementing** when the change is risky,
  ambiguous, or large. The plan is the only artifact in this step.

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
