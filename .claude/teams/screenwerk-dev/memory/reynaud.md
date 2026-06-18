# Reynaud — Player Builder Scratchpad

_Last updated: 2026-06-18_

## Session 2026-06-18

### #2 — Duration unit: CONFIRMED FIXED, closed (PR #10 merged)
Re-verified from scratch this session. `useScheduler.ts:43` = `s.duration * 1_000` (seconds→ms), no `*60_000` anywhere. All duration/delay sites consistent: `useMediaTimer.ts:36` media duration `*1000`, `useMediaTimer.ts:49` + `useMediaPlayback.ts:41` delay `*1000`, `types.ts:23/55` documented Seconds, dashboard renders `s`. Plateau's `tests/unit/scheduler.test.ts` correctly captures seconds semantics (TICK+35s→null assertion would fail under old buggy code). Tests 8/8, lint clean. No code change from me — confirm-only task.

### #9 — PARKED for next session (player-side validFrom)
Next task: future-`validFrom` media must NOT display before its start at the render/poll layer. Plateau will have a RED test. I write GREEN. Check `usePlaylist.ts` (PlaylistMedia validity filter), `useScreen.ts` validLayoutPlaylists, and `utils/date.ts isWithinValidityWindow()` — already exists per overview, so #9 may be confirming/extending render-layer enforcement rather than net-new filter logic. Start by reading Plateau's test.

---

## Codebase Overview

**Stack:** Nuxt 4 (SSR=false), Vue 3, TypeScript, Tailwind, Vite PWA (Workbox), cron-parser v5, VueUse

---

## Key Files

| File | Purpose |
|------|---------|
| `player/app/types.ts` | ScreenConfig contract — single source of truth |
| `player/app/composables/useScreen.ts` | Master orchestration: config poll, clock tick, schedule resolution, CSS scaling |
| `player/app/composables/useScreenConfig.ts` | CDN fetch, `publishedAt` skip-if-unchanged, precache trigger |
| `player/app/composables/useScheduler.ts` | Pure functions: `getLastCronTick()`, `resolveActiveSchedule()` |
| `player/app/composables/usePlaylist.ts` | Index advancement, validity filter, loop/cleanup logic |
| `player/app/composables/useMediaPlayback.ts` | Delayed play for video/audio elements |
| `player/app/composables/useMediaTimer.ts` | Delay+duration timer chain for image/URL |
| `player/app/composables/usePrecache.ts` | Proactive Cache API warming, stale file cleanup (confirmed exists) |
| `player/app/composables/useDashboard.ts` | Lightweight inject wrapper for dashboard tree |
| `player/app/utils/date.ts` | `isWithinValidityWindow()` — shared by all validity filtering |
| `player/app/utils/entu.ts` | `val()`, `byName()`, `byOrdinal()` — Entu entity helpers |
| `player/app/components/layout-playlist.vue` | Zone renderer — positions, picks media type, relays `@ended` |
| `player/app/components/media/*.vue` | image, video, audio, url — each emits `ended` |
| `player/app/pages/[account]/[screenId].vue` | Thin player page — delegates to `useScreen`, startup console.log |
| `player/app/pages/[account]/index.vue` | Dashboard — Entu API browser (live, not CDN) |
| `player/app/version.ts` | `BUILD_PR` number — updated by pre-merge script on each merge |
| `player/.config/nuxt.config.ts` | Workbox config, runtime env vars, PWA setup |
| `player/.config/eslint.config.ts` | ESLint flat config: tailwind whitelist, prettier integration, test overrides |
| `player/.prettierrc` | Prettier config: single quotes, no semis, no trailing commas, always arrow parens |
| `player/vitest.config.ts` | Vitest with `defineVitestConfig`, happy-dom, targets `tests/**/*.test.ts` |

---

## Architecture Patterns

### Getter Function Composables (Vue 3.5+ idiom)
Every composable takes getters (`() => value`) not raw refs. Decouples reactivity from instantiation.

### Validity Window Filtering — 3 Levels
1. **Schedule** — `resolveActiveSchedule()` filters by `validFrom`/`validTo` before cron evaluation
2. **LayoutPlaylist** — `useScreen.validLayoutPlaylists` filters active schedule's zones
3. **PlaylistMedia** — `usePlaylist` filters `playlistMedias` reactively on each tick

### Responsive Canvas Scaling
If a schedule has fixed `width`/`height` > 0, CSS `scale()` transform fits canvas to browser window.

### Cron-Driven Reset
If `layoutPlaylist.loop` + `cleanup=true`, playlist resets to index 0 on each cron tick.

### Dual Timer (delay + duration)
`useMediaTimer` and `useMediaPlayback` apply delay seconds then duration seconds.

### Config Polling Optimization
`useScreenConfig` skips full update if `publishedAt` unchanged — avoids redundant precache cycles.

### PWA Media Strategy
- Config JSON: NetworkFirst (5s timeout → cache fallback, 7-day TTL)
- Media files: CacheFirst (serve cached, 30-day TTL, range requests enabled)
- Precache batched in groups of 3 after each config load

---

## Runtime Config (env vars)
```
NUXT_PUBLIC_API_BASE              = https://files.screenwerk.ee
NUXT_PUBLIC_ENTU_URL              = https://entu.app/api
NUXT_PUBLIC_ENTU_ACCOUNT          = piletilevi
clockIntervalSeconds              = 30
defaultUpdateIntervalMinutes      = 10
defaultMediaDurationSeconds       = 10
precacheBatchSize                 = 3
```

---

## Test Infrastructure

- **Runner:** Vitest v4.1.3 with `defineVitestConfig` from `@nuxt/test-utils`
- **Environment:** happy-dom
- **Location:** `tests/unit/*.test.ts`
- **Scripts:** `npm run test` (single run), `npm run test:watch`
- **Current coverage:** 4 test files, 8 tests passing

| Test file | What it covers |
|-----------|----------------|
| `smoke.test.ts` | Infrastructure sanity (trivial assertion) |
| `scheduler.test.ts` | `resolveActiveSchedule()` duration unit (seconds) |
| `version.test.ts` | `BUILD_PR` is a positive number |
| `nuxt-config.test.ts` | Workbox globIgnores includes 404/200 patterns |

---

## Issues Worked On Today

### #1 — Test Infrastructure (branch: `1-test-infrastructure`, merged PR #3)
- Phase 1: Whitelisted `db-` prefix in tailwindcss eslint plugin (62 warnings → 0)
- Phase 2: Added Prettier (`.prettierrc`, `eslint-config-prettier`), format/format:check scripts, formatted 27 files
- Phase 3 GREEN: Scaffolded Vitest — `vitest.config.ts`, test/test:watch scripts, smoke test passes
- Hotfix: Added `.nuxtrc` to `.gitignore` (generated by @nuxt/test-utils)

### #2 — Duration Unit Fix (branch: `2-duration-unit-fix`, merged PR #4)
- **Bug:** `s.duration * 60_000` treated duration as minutes → banners 60× too long
- **Fix:** Changed to `s.duration * 1_000` (seconds)
- Also fixed `types.ts` comment and dashboard `min` → `s` label
- Reported by Tomas (Bilietai) — outdated banners on client screens

### #5 — Version Tracking (branch: `5-version-tracking`, merged PR #6)
- Created `app/version.ts` exporting `BUILD_PR` (hardcoded, updated by pre-merge script)
- Added `console.log('[Screenwerk] ScreenWerk/2026#${BUILD_PR}')` to player startup

### #7 — Workbox globIgnores (branch: `7-workbox-glob-ignores`, PR open)
- Added `'**/404*'` and `'**/200*'` to `globIgnores` in nuxt.config.ts
- Also added `@typescript-eslint/no-explicit-any: off` override for `tests/**` in eslint.config.ts
  (Plateau's nuxt-config test uses `config as any` — right place to relax this rule)

---

## ESLint Config State
Current `.config/eslint.config.ts` structure:
1. Tailwind flat/recommended (prepended)
2. Tailwind settings: config path + `db-.+` whitelist (prepended)
3. Main rules: `object-shorthand: always`
4. Test override: `@typescript-eslint/no-explicit-any: off` for `tests/**/*.ts`
5. `eslint-config-prettier` (appended — disables formatting rules)

---

## Open Questions

- For Talbot: Is the Entu API for dashboard public or does it need auth?
- For Daguerre: Is the `fileDO→file` normalization still needed or a legacy artifact from the pipeline?
- General: `BUILD_PR` pre-merge script — Daguerre's domain or mine? Need to coordinate.

---

## Gaps Still Present (no issue filed yet)

1. No media retry on error — failed media calls `advance()` immediately
2. No heartbeat / health check back to server
3. No offline visual indicator for operators
4. `mediaEid` and `layoutEid` in ScreenConfig — present in types, not used at runtime (telemetry only?)
5. Audio component shows black — no background image support for audio-only zones
