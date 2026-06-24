---
name: researcher
description: >
  Deep, multi-source, fact-checked research on any topic. Fans out parallel
  research workers, adversarially verifies the load-bearing claims, then
  synthesizes a cited report with a confidence/gaps section. Use when the user
  wants a researched, sourced answer — "research X", "find out about X", "what's
  the state of X", a buying/decision question, or a literature/landscape scan.
  BEFORE researching, if the question is underspecified (missing budget, region,
  timeframe, use-case, or scope), ask 2–3 clarifying questions and weave the
  answers in. NOT for questions about THIS codebase — use /learn-codebase.
argument-hint: "[--quick | --deep] <question>"
---

## What this does

Orchestrates a fleet of `deep-researcher` worker subagents to research a
question on the public web, verifies the key claims with skeptic subagents, and
writes one cited report. You run in the main thread; each worker runs in its own
context so raw findings don't flood yours.

## Cost & safety (read first)

- Multi-agent research costs roughly 10–15× a single chat in tokens. The effort
  tier (below) is the throttle. **State the chosen tier before fanning out** so
  the cost is visible.
- PUBLIC WEB ONLY. Warn the user not to include proprietary, internal, or
  private information in the question, and never pass such text to workers.
- Never write API keys or fetched content to disk unless the user asks to save
  the report.

## How to work

### 1. Scope
Read the argument. If a `--quick` or `--deep` flag is present, use that tier;
otherwise pick one in step 3. If the question is underspecified — a decision
question with no constraints, an ambiguous entity, or a recency-sensitive topic
with no timeframe — ask 2–3 clarifying questions and stop until answered. Don't
research the wrong question.

### 2. Plan
Decompose the question into focused, mostly-independent sub-questions (one
research thread each). Restate the question, list the sub-questions, and name
the tier in 3–5 lines so the user sees the plan before the spend.

### 3. Pick the effort tier

| Tier | Sub-questions | Rounds | Verifiers / key claim | Use when |
|---|---|---|---|---|
| **Quick** | ~3 | 1 | 1 (key claims only) | a focused factual question |
| **Standard** (default) | 4–6 | up to 2 | 1 | most research |
| **Deep** | 6–8 | up to 3 | 2–3 (majority vote) | high-stakes or broad topics |

Tell each worker its search budget: Quick ≈ 3 searches / 3 fetches,
Standard ≈ 5 / 5, Deep ≈ 8 / 8.

### 4. Round 1 — fan out
Dispatch one `deep-researcher` subagent per sub-question, **all in a single
message** so they run in parallel. Give each: its sub-question, brief search
directions, and its budget.

### 5. Recurse (bounded)
Read the workers' follow-up questions and gaps. If important threads are
unresolved and you're under the tier's round cap, run another round with
**tapered breadth** (about half as many workers, aimed at the gaps). Stop at the
round cap regardless of how much is left.

### 6. Consolidate
Merge all findings. Deduplicate claims that repeat across workers (keep the
best-sourced version). Group by theme. Note where workers disagree.

### 7. Adversarial verification
Identify the **load-bearing claims** — the few the conclusion actually depends
on, not every minor fact. For each, dispatch a skeptic `deep-researcher`
subagent told to try to refute it with fresh searches:

> "Find evidence that the following claim is FALSE, outdated, or misleading:
> '<claim>'. Report what you find, with sources. If after a real search you
> cannot refute it, say 'could not refute' and give the strongest supporting
> source."

- **Contradicted** → drop the claim, or rewrite it with the correction.
- **Could not refute** → mark verified.
- **No support either way** → mark low-confidence in the report.

Deep tier: 2–3 skeptics per key claim; take the majority verdict.

### 8. Synthesize the report
Write the report (format below) with inline `[n]` citations tied to the Sources
list. Be honest about uncertainty — the Confidence & gaps section is mandatory.

### 9. Offer to save
After printing the report, offer:

> "Want me to save this to `docs/research/<date>-<slug>.md`?"

Only write if the user agrees. Scan for sensitive content first. Never write
without confirmation.

## Report format

```markdown
# Research: <question>

## TL;DR
The answer in 2–4 sentences.

## Findings
### <Sub-question or theme>
Prose with inline citations [1][2]. ...

(repeat per theme)

## Confidence & gaps
- **Verified:** claims that survived refutation.
- **Low confidence / unresolved:** claims with weak or conflicting support.
- **Refuted & corrected:** what was wrong and the correction.
- **Not covered:** what we couldn't answer, and why.

## Sources
1. <title> — <URL>
2. ...
```

## Notes
- If a worker returns "inconclusive," say so in the report — don't paper over it.
- Prefer fewer well-sourced claims over a long list of weakly-sourced ones.
- If the whole question can't be answered from public sources, say so plainly.
