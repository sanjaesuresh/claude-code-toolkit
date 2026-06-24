---
name: frontend-engineer
description: >-
  The disciplined build/fix loop for frontend work — UI components, pages, web apps,
  dashboards, landing pages. Like software-engineer, but specialized for the browser: it
  bakes in not-AI-looking design (reference-first brief + the vibe-coded-tells catalog and
  a CI scanner) AND production-grade engineering gates (WCAG 2.2 AA accessibility, Core Web
  Vitals / INP performance, every-state coverage, semantic HTML, forms UX, responsive,
  design tokens, testing). Use whenever you are building, styling, or changing any web UI
  and want it to look human-made and hold up in production — not just render in a demo.
  Trigger on "build a page/component/dashboard/landing page", "make this UI", "frontend",
  "doesn't look AI-generated", "production-grade UI".
---

# frontend-engineer

The default loop for building or changing **frontend** code. It is the browser-facing
counterpart to `software-engineer`: same discipline (understand → plan → small steps →
verify with evidence → self-review), plus the two things that separate production UI from
a pretty demo — **it doesn't read as AI-generated**, and **it handles accessibility,
performance, and every state**, not just the happy path.

A working render is not done. Done is: a deliberate look, keyboard-operable, contrast-safe,
fast (LCP/INP/CLS in budget), and correct in its empty/loading/error/overflow states.

## When to use something else

- Backend / non-UI build or fix → `/software-engineer`.
- Pure visual de-slop **audit** of existing code, or "does this look AI" → run this skill's
  bundled `scripts/devibe_scan.py` (the Verify step below) for the review-only pass. The
  standalone `unslop-ui` skill does the same audit with a fuller catalog if you have it
  installed — it is optional and not bundled here.
- Open-ended *creative* direction / "make it beautiful from scratch" → `/frontend-design`
  or `/impeccable`; then return here to engineer it properly.
- Reviewing a UX/frontend plan before code → `/design-plan-review`.
- Reviewing a frontend diff → `design-reviewer` agent or `/pre-pr-review`.

This skill is the implementer that pulls those in at the right moment. It is the only
frontend skill that combines deliberate-look enforcement with the engineering gates.

## The loop

### 1. Brief before CSS (this is where "looks AI" is won or lost)

Most "looks AI" outcomes are a *specification* problem, not a styling one. An unspecified
prompt returns the median of the training data, and everyone's median is identical. Before
generating UI, establish the brief — pull it from the user, or state the choices you are
making and why. Do not silently fall back to defaults.

Establish concretely (method in [references/choosing-a-look.md](references/choosing-a-look.md)):

- **A reference.** One real site, brand, or screenshot whose design language to follow.
  This single input does more than every other rule combined. If none exists, commit to a
  *named direction* (editorial, brutalist, utilitarian-dense, warm-consumer, technical-mono)
  — never "modern and clean."
- **A color decision.** A real or deliberately chosen brand color, stated. Not the
  framework indigo/violet default, and not the cream/sage "tasteful" default either.
- **A type decision.** A specific typeface/pairing with a reason. Avoid the autopilot picks
  (Inter, Geist; and Instrument Serif, Fraunces, Playfair) unless they are a real choice.
- **A layout intent.** What the page is *for* and what the user should do first — this is
  how you avoid the centered-hero + three-feature-cards skeleton. Structure follows goal.

### 2. Build, avoiding the tells

While building, avoid the specific signatures in
[references/ai-tells-catalog.md](references/ai-tells-catalog.md) (data-ranked from ~3.2M
Reddit posts). The top ones: default shadcn/Tailwind look, AI purple, gradient text, motion
on everything, rounded-everything, unprompted neon glow, emoji-as-icons, generic fonts, the
hero+3-cards skeleton, and the cream+serif+sage "tasteful default." A tell is an
*unspecified default*, not a banned value — if the user genuinely chose purple or cream as a
brand decision, that is not slop; leave it and mark `unslop-ignore`.

The trap: don't fix one default by reaching for another (`bg-purple-600` →
`bg-emerald-700` is not unslopping, it just resets the clock). Apply the project's actual
choice from step 1.

### 3. Engineer it as you build (not as a cleanup pass)

These are gates, not nice-to-haves. Pull the rules from the references and apply them while
writing the component, because retrofitting accessibility and state handling is far more
expensive than building them in:

- **Semantic HTML + accessibility** → [references/accessibility.md](references/accessibility.md).
  Native element for the job (`<button>` for actions, `<a href>` for nav, `<dialog>` for
  modals), keyboard-operable with a visible focus ring, ARIA only for true custom widgets,
  contrast ≥ 4.5:1 / 3:1.
- **Every state** → [references/states-and-forms.md](references/states-and-forms.md).
  Loading (skeleton vs spinner), empty, error+retry, zero/one/many, long content, offline.
  Forms: validate on blur, specific error messages, correct `autocomplete`/`inputmode`,
  focus the first invalid field.
- **Performance** → [references/performance.md](references/performance.md). LCP element
  prioritized (never lazy-loaded), no >50ms long tasks, dimensions on all media, fonts with
  `swap` + preload, animate only `transform`/`opacity`.
- **Architecture + tokens** → [references/architecture-and-tokens.md](references/architecture-and-tokens.md).
  No derived state in `useEffect`, `"use client"` at leaves, semantic design tokens (no
  hardcoded hex/px), no secrets across the server→client boundary.
- **Production readiness** (for the surfaces that need it) →
  [references/production-readiness.md](references/production-readiness.md). SEO/metadata
  and social cards on public pages, security headers + CSP + SRI, the image/media
  pipeline, real-user observability, and the CI gates (`eslint-plugin-jsx-a11y`, axe,
  Lighthouse budgets) that actually enforce the rules above.

### 4. Verify before declaring done

Evidence-gated, like the rest of the toolkit. Run the checks; don't claim what you didn't
verify. When unsure between DONE and UNVERIFIABLE, say UNVERIFIABLE.

```bash
# From this skill's directory. Exit code = high-severity count → CI can gate on it.
python3 scripts/devibe_scan.py <path>                  # full report + vibe score
python3 scripts/devibe_scan.py <path> --severity high  # strongest signals only
python3 scripts/devibe_scan.py <path> --json           # machine-readable for CI
```

The scanner catches the mechanical tells (colors, fonts, gradients, the cream+serif combo).
It **cannot** see layout coherence, spacing consistency, focus order, or whether text
overflows — check those by eye and by keyboard.

## Definition of done (frontend)

Not done until every line is true (or explicitly N/A with a reason):

- [ ] **Deliberate look** — color, type, and layout each trace to a stated reason, not a
      default. `devibe_scan.py` high-severity count is 0 (or every finding is a justified
      `unslop-ignore`).
- [ ] **Keyboard** — full flow operable with the mouse unplugged; visible focus ring
      everywhere; focus managed on modal open/close and route change; no traps.
- [ ] **Contrast** — body ≥ 4.5:1, UI/large text ≥ 3:1, verified in light *and* dark.
- [ ] **Semantics** — right native element for each role; one `<main>`/`<h1>`; headings
      don't skip; ARIA only where a native element couldn't do it.
- [ ] **States** — loading, empty, error+retry, zero/one/many, long-content, and offline
      all handled and seen. Forms validate on blur with specific, linked error messages.
- [ ] **Core Web Vitals** — LCP element prioritized; no obvious >50ms main-thread tasks;
      all media has dimensions; fonts load without invisible-text or swap-shift.
- [ ] **Responsive** — works at ~320px, tablet, desktop, and 200% zoom; tap targets
      ≥ 24×24px; no horizontal scroll or clipping.
- [ ] **Tokens** — spacing/color/type/radius reference tokens; no stray hardcoded hex/px.
- [ ] **Tests** (when the project has a suite) — behavior queried by role/label; axe run on
      the primary flow; critical user flow has an E2E.
- [ ] **`prefers-reduced-motion`** honored; motion only where it signals causality.
- [ ] **Production readiness** (where it applies) — public pages have unique title/meta +
      canonical + OG card; third-party scripts use SRI; `target="_blank"` has
      `rel="noopener"`; images use modern formats with correct `srcset`/`sizes`; a CI gate
      (`eslint-plugin-jsx-a11y`/axe/Lighthouse) enforces the above.

For the full highest-leverage list, the references carry the thresholds and the sources.

## Attribution

The tell catalog and `devibe_scan.py` are vendored from
[vibecoded-design-tells](https://github.com/JCarterJohnson/vibecoded-design-tells) (Carter
Johnson, MIT) — see [ATTRIBUTION.md](ATTRIBUTION.md). The engineering reference files are
original to this skill.
