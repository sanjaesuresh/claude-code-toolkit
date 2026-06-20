---
name: plan-pipeline
description: Run a plan through several specialist reviews in one pass — engineering, design, and scope — auto-deciding the routine calls and surfacing only the real judgment calls at a single approval gate. Use when the user says "plan pipeline", "full plan review", "review this plan from all angles", or has a non-trivial implementation plan ready and wants it stress-tested before coding.
---

# plan-pipeline

Chain the plan-review specialists so you get one consolidated verdict instead of
running each review by hand and answering the same questions three times. Read-only.

## Tool contract

Read-only. No code, no file edits. The plan and this report are the only outputs.

## Input

A written implementation plan (from `/kickoff`, `/implementation-plan`, `/spec`,
or pasted). If none exists, say so and point the user to `/kickoff` first.

## Steps

1. **Route.** Pick the relevant reviews for *this* plan — don't run all of them
   blindly:
   - Always: engineering review (architecture, data flow, failure modes, tests,
     rollout) via the `engineering-manager` agent.
   - If the plan touches UI/UX: design review via the `design-reviewer` agent.
     Skip for backend-only / infra-only changes.
   - If a diff already exists for the plan: scope review via the `scope-guardian`
     agent. Skip in pure pre-code planning.
   - If migrations/schema/API contracts are involved: add `migration-risk-reviewer`.
   State which reviews you're running and why.

2. **Dispatch.** Run the chosen reviews as subagents (in parallel where they're
   independent). Collect their findings.

3. **Auto-decide the routine calls.** Resolve intermediate questions yourself
   when the choice is low-stakes, using these principles:
   - **Reversible + in-scope + low-effort** (no new infra, a few files): just
     pick the sensible default and note it.
   - **DRY** — reject duplication; prefer reusing what exists.
   - **Explicit over clever** — a 10-line obvious solution beats a 200-line
     abstraction; favor what a reader understands in 30 seconds.
   - **Pragmatic** — spend the decision budget on what matters; don't agonize
     over trivial forks.
   Do **not** auto-expand scope or auto-pick the heaviest option. When in doubt,
   keep it scoped and surface it.

4. **Surface only the taste decisions.** Anything genuinely consequential —
   competing architectures, `[one-way]` choices, scope boundaries, cross-review
   disagreements — goes to a single `AskUserQuestion` gate using the
   **Decision-brief format** (Completeness X/10, dual effort, one-way/two-way,
   recommendation). Don't drip-feed questions across the run.

## Output format

```markdown
# Plan Pipeline Review

## Reviews run
Which specialists ran, and why the others were skipped.

## Verdict
Ready to implement | Ready after the decisions below | Needs rework

## Consolidated findings
The merged, de-duplicated findings across reviews. Blockers first, then
suggestions. Quote evidence (file/section). Note any disagreement between reviews.

## Auto-decided (FYI — change if you disagree)
- <routine call> → <what I chose> (<principle>)

## Decisions for you
The taste decisions, as a decision brief (sent via AskUserQuestion).

## Recommended next step
Once decisions are settled: `/software-engineer` to build (plan on Opus,
execute on Sonnet).
```

## What not to do

- Don't run reviews that don't apply (no design review for a backend change).
- Don't auto-decide anything irreversible or scope-expanding — surface it.
- Don't write code.

## Related

- [[kickoff]] / [[engineering-plan-review]] / [[design-plan-review]] — the
  individual planning skills this orchestrates.
