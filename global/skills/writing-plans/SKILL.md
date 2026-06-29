---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know in plain English: which files to touch for each task, the behavior to build, how to test it, and which docs to check. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Plans are plain English — no code.** Describe behavior, interfaces, and test cases in words. No code snippets, no code blocks, no diffs anywhere in the plan. Name files and describe what each must do; exact commands to run are fine, but literal implementation code is written only during execution, after the plan is approved.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `using-git-worktrees` skill at execution time.

## Required output: the plan is a file

The plan is a **file on disk**, not a chat message. A chat-only plan does not count and does not satisfy the planning gate. Write the plan to a file, then hand off (or request approval) by naming its path and giving a short prose summary in chat — never paste the whole plan into chat.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default — e.g. `docs/<feature>-plan.md`.)

If scope changes during planning or review, update the file; it is the source of truth.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or software-engineer to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

Describe each task in plain English. Name the files, name the functions and their inputs/outputs, and describe the behavior and test cases in words — no code blocks.

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — name the exact functions
  and describe their parameters and return types in words]
- Produces: [what later tasks rely on — name the exact functions and describe
  their parameters and return types in words. A task's implementer sees only
  their own task; this block is how they learn the names and types neighboring
  tasks use.]

- [ ] **Step 1: Write the failing test** — describe the test by name: which
  behavior it pins down, the input it uses, and the expected result. In words,
  not code.

- [ ] **Step 2: Run the test to verify it fails** — give the exact command and
  the expected failure (e.g. fails with "function not defined").

- [ ] **Step 3: Write the minimal implementation** — describe what the function
  must do to make the test pass: its name, inputs, output, and behavior. No code.

- [ ] **Step 4: Run the test to verify it passes** — give the exact command and
  the expected PASS.

- [ ] **Step 5: Commit** — state the commit message and which files it covers.
```

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases" — say exactly what to validate and how it should behave
- "Write tests for the above" — describe the actual test cases: behavior, input, expected result
- "Similar to Task N" — repeat the description (the engineer may be reading tasks out of order)
- Steps that name an action without describing the behavior — say precisely what it must do
- References to types, functions, or methods not defined in any task

**Specific does not mean code.** Be exact in plain English: name the function, state its inputs and output, and describe the behavior — without writing the implementation.

## Remember
- Exact file paths always
- Complete behavior in every step — describe what the code must do, in words, not the code itself
- Exact commands with expected output
- Plain English only — no code snippets, no code blocks, no diffs
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the function names, signatures, and property names you described in later tasks match what you described in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Plain-English scan:** Search the plan for code blocks, code snippets, or diffs. There should be none — convert any to a prose description of the behavior.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using software-engineer, with checkpoints between tasks

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use software-engineer
- Batch execution with checkpoints for review
