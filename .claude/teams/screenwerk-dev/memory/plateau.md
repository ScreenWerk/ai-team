# Plateau — scratchpad

(*SW:Plateau*)

## Conventions
- Player tests: `player/tests/unit/*.test.ts`, vitest 4, `import { describe, expect, it } from 'vitest'`.
- Run: `cd player && npx vitest run [path]`. Lint: `cd player && npm run lint`.
- Schedule fixture helper `makeSchedule()` in scheduler.test.ts.

## Issue #2 — duration unit (seconds vs minutes) — DONE, awaiting PR by Lumiere
- Branch: `fix/issue-2-duration-unit-regression-test`.
- Fix already present: `useScheduler.ts:43` → `lastTick.getTime() + s.duration * 1_000` (seconds→ms).
- types.ts:23 documents `duration?: number // Seconds active after cron tick`.
- Old bug (commit 8004e92 fixed it): multiplier was `* 60_000` (treated as minutes) → 60× too-long windows. Tomas/Bilietai banners stayed active 60× too long.
- A regression test already existed (mine) but its comments were stale RED-phase ("will FAIL until fixed").
- Action taken: rewrote doc comments to GREEN/locked framing, added a 4th test ("inactive 5 min after tick" — strongly discriminates seconds vs the 60× minutes bug).
- Verified regression-guard property: temporarily flipped multiplier to `60_000`, the "35 s after" test FAILED; restored to `1_000`, all pass.
- Results: 4/4 scheduler tests pass; full suite 9/9 pass; lint clean.
- NO implementation change needed — Reynaud not required. Only `tests/unit/scheduler.test.ts` changed.

## Queued / next (do NOT start without Lumiere's go)
- Issue #9 — player-side RED test: future-`validFrom` media must NOT display before its start even once already fetched/precached. Target = render/poll layer (not just date.ts). HELD — wait for explicit go from Lumiere.
- Backlog (after #9, separate issue): useMediaTimer.ts:36 `media.duration` duration-unit regression test — impl already correct (`* 1000`) but untested. Lumiere logging as own issue; do NOT fold into #2.

## Status of #2 — CLOSED
- PR #10 reviewed + merged by Lumiere (squash, branch deleted). Issue #2 confirmed and closed 2026-06-18.

## Related
- See team memory: project_bilietai_duration_bug — needs retest after fix confirmed.
