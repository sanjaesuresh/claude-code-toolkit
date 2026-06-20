---
name: kickoff
description: Start a new piece of work the right way — from a work ticket (e.g. Jira) or a side-project feature. Creates a branch from ticket info when it's work, investigates the codebase to answer its own questions, asks ONLY the decision-altering questions (with pros/cons), then produces a scoped plan before any code. Use when the user pastes a ticket, says "kickoff", "new ticket", "start work on X", "I'm picking up TICKET-123", or "plan this feature".
argument-hint: <ticket id/text, or feature description>
---

# kickoff

The front door for new work: **classify → branch (if work) → investigate →
ask only what matters → plan → hand off to implementation.** No code is written
in this skill; the branch and the plan are the only artifacts.

## Tool contract

Read-only investigation plus, in work mode, one git branch operation (after you
confirm the name). Do not edit project files. Do not write code here.

## Step 1 — Classify the work

- **Work mode** — the input is, or references, a ticket (a project-key ID like
  `PROJ-1234`, or pasted ticket text). A branch WILL be created.
- **Personal mode** — the input is a feature description with no ticket. **Stay
  on `main`; do not create a branch.**

If a ticket ID is given with no detail, **ask the user to paste the ticket body**
(title, description, acceptance criteria). Do **not** try to fetch from an
internal Jira/issue tracker — assume no API access, and never reach into
employer systems.

## Step 2 — Branch (work mode only)

Branch name format:

```
sanjae-<team>-<ticket-number>-<short-name>
```

- `sanjae` — fixed user handle.
- `<team>` — default to the lowercased project key from the ticket ID
  (`INFRA-4521` → `infra`). If the repo's existing branches use a different team
  token (check `git branch -a`), follow that. Ask once only if it's genuinely
  ambiguous and not derivable.
- `<ticket-number>` — the numeric part (`4521`).
- `<short-name>` — a 3–5 word kebab summary of the ticket title
  (`add-retry-to-upload`).

Example: `sanjae-infra-4521-add-retry-to-upload`

Then:

1. Detect the base branch (`git symbolic-ref refs/remotes/origin/HEAD`, else
   `main`/`master`). Note if the working tree is dirty — warn before branching.
2. **Propose the branch name and wait for the user's OK.** Adjust if they tweak it.
3. On approval, branch from an up-to-date base:
   `git checkout <base> && git pull --ff-only` (if a remote exists), then
   `git checkout -b <name>`. Confirm the branch is created and current.

## Step 3 — Investigate before asking (do the homework)

Answer as many questions as you can **yourself** from the codebase. Only what you
genuinely cannot resolve should reach the user.

- Find the relevant files, entry points, and call sites for this work.
- Identify existing patterns, conventions, and similar features already in the
  repo — new work should match them unless there's a reason not to.
- Note constraints the code imposes (data models, interfaces, libraries already
  in use, test patterns, config).
- For unfamiliar areas, lean on [[learn-codebase]] or dispatch the
  `codebase-teacher` / `Explore` agents to map it fast.

## Step 4 — Ask ONLY decision-altering questions

Use the **AskUserQuestion** tool. Ask a question only when the answer would
**change the final solution** and you can't settle it from the codebase or the
ticket. Examples worth asking:

- Two real implementation pathways (different technologies, libraries, or
  architectures) with meaningfully different tradeoffs.
- Data model / schema choices that are hard to reverse later.
- Scope boundaries (is X in or out of this ticket?).
- UX/behavior forks where the ticket is silent.
- Sync vs async, build vs buy, new dependency vs existing tool.

For each question:

- Give 2–4 concrete options. Put your **recommended** option first and mark it
  `(Recommended)`.
- Put the **pros/cons / tradeoffs** of each option in its description.
- When comparing concrete code shapes, file layouts, or architectures, use the
  option **`preview`** field to show a short side-by-side sketch.

**Do NOT ask** about things that are obvious, already answered by the ticket, or
derivable from the codebase. If nothing material is unresolved, say so plainly
and skip straight to the plan — don't manufacture questions.

## Step 5 — Produce the plan

Once decisions are settled, output the plan below. Keep it scoped and concrete.

```markdown
# Plan: <ticket-id or feature> — <short title>

## Understanding
What the work is, in two or three sentences. In scope vs out of scope.

## Decisions locked
- <decision> — chosen because <reason> (from your answer / the codebase)

## Files likely to change
- path — what changes and why

## Approach
The implementation strategy, grounded in existing patterns (reference real files).

## Risks
What could go wrong; edge cases and failure modes to handle.

## Test plan
What to test and where; the behaviors that prove it works.

## Out of scope
Explicitly not part of this work (follow-ups noted separately).

## Open assumptions
Anything I assumed rather than confirmed — flag for a quick check.

## Next step
Recommend whether to run [[engineering-plan-review]] (risky/large) or
[[design-plan-review]] (UX-heavy) first, then [[software-engineer]] to build.
```

## Work-safety

- Never fetch from internal ticket systems; the user pastes ticket content.
- Keep ticket details and the plan **project-local**. Do not persist ticket
  text, internal identifiers, or employer specifics into global files, global
  memory, or the toolkit repo.
- No employer team names are hardcoded in this skill — `<team>` is resolved at
  runtime.

## Related

- [[implementation-plan]] — lighter "just plan this area" with no branch/ticket flow.
- [[spec]] — when the ask is vague and needs a precise definition of done first.
- [[office-hours]] — when it's not yet clear the work is worth doing.
