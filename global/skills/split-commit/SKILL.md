---
name: split-commit
description: >
  Review the working tree and split it into several focused, logically-separate
  git commits — one per feature / fix / refactor / docs / chore — instead of one
  catch-all commit. Proposes the grouping and waits for approval before
  committing. Use when the user says "split this into commits", "commit these
  changes separately", "/split-commit", or has a mixed batch of changes that
  should not land as a single commit. Commits only — never pushes, branches, or
  opens a PR.
---

## Tool contract

This skill **writes to git history** (it runs `git add` and `git commit`). It
does **not** push, create branches, or open PRs. It stops after the last commit.

## When this fires

The working tree has changes that span more than one logical unit — e.g. a bug
fix plus an unrelated refactor plus a doc tweak — and they should be recorded as
separate commits so history stays reviewable and revertable. If the diff is
genuinely one unit, say so and make a single commit (or defer to `/commit`).

## Hard rules

- **Propose, then wait.** Never stage or commit before the user approves the
  plan. The proposal is the gate.
- **Commit only.** No `git push`, no new branches, no `gh pr create`. Even if the
  changes are on `main`, commit straight to `main` — do not branch. (Matches the
  user's workflow: personal projects commit directly to main.)
- **Plain imperative messages.** Subject lines like `Add split-commit skill` or
  `Fix race in notify hook` — no `feat:` / `fix:` conventional-commit prefixes.
- **Never invent changes.** Group only what `git diff` actually shows. If you
  can't cleanly separate two concerns that live in the same hunk, say so and
  propose the least-bad split rather than fabricating a clean one.
- **Don't commit junk.** Flag (don't auto-stage) anything that looks like a
  secret, a large binary, a `.env`, or an accidental file. Ask before including.

## Procedure

### 1. Gather state

Run, and read the full output before grouping:

```
git status --porcelain=v1
git diff HEAD            # staged + unstaged, full patch
git log --oneline -10    # match the repo's existing message voice
git branch --show-current
```

If `git diff HEAD` is empty, there is nothing to commit — report that and stop.

### 2. Group into logical units

Partition the changes by **intent**, not by file. One commit may span several
files; one file may contribute to several commits (split with `git add -p` /
pathspecs). Typical buckets:

- **Feature** — new user-visible capability
- **Fix** — corrects a bug
- **Refactor** — behavior-preserving restructure
- **Docs** — README / comments / docs only
- **Chore** — deps, config, formatting, tooling

Order them by **dependency**: a refactor that a feature builds on commits first,
so each commit builds and tests on its own where practical.

### 3. Propose — then STOP

Show a plan and wait for explicit approval. Format:

```
Proposed split (N commits):

1. [refactor] Extract commit grouping into helper
     global/skills/split-commit/SKILL.md
2. [fix] Stop notify hook from firing twice
     scripts/notify.sh
3. [docs] Document split-commit in README
     README.md  (only the "Skills" table rows)

Files NOT included: .env.local (looks like a secret — confirm?)
```

Do not run any `git add` / `git commit` yet. Ask: "Commit these as-is, or adjust
the grouping?" Apply any edits the user asks for and re-show if the change is
material.

### 4. Commit each unit, in order

Only after approval. For each group, stage exactly its changes and commit:

- Whole-file groups: `git add <paths>` then `git commit -m "<subject>"`.
- Partial-file groups: stage hunks with `git add -p <path>` (or
  `git apply --cached` for precise hunks), then commit.
- Use a one-line imperative subject; add a short body only when the *why* isn't
  obvious from the subject.
- After each commit, verify with `git status` that the right things left the
  index before moving to the next group — avoid bleeding changes across commits.

### 5. Report

Print `git log --oneline -<N>` for the new commits and a one-line summary. Note
anything deliberately left uncommitted (e.g. the flagged secret). Do **not**
push or offer to push unless the user asks.

## Notes

- If the user invoked this on a single trivial change, don't force a split —
  make the one commit and say why splitting wasn't warranted.
- This skill is the multi-commit counterpart to the `/commit` command, which
  always makes exactly one commit.
