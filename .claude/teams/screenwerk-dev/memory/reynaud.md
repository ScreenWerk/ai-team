# Reynaud — Player Builder Scratchpad

_Last updated: 2026-04-07_

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
| `player/app/composables/useDashboard.ts` | Lightweight inject wrapper for dashboard tree |
| `player/app/utils/date.ts` | `isWithinValidityWindow()` — shared by all validity filtering |
| `player/app/utils/entu.ts` | `val()`, `byName()`, `byOrdinal()` — Entu entity helpers |
| `player/app/components/layout-playlist.vue` | Zone renderer — positions, picks media type, relays `@ended` |
| `player/app/components/media/*.vue` | image, video, audio, url — each emits `ended` |
| `player/app/pages/[account]/[screenId].vue` | Thin player page — delegates to `useScreen` |
| `player/app/pages/[account]/index.vue` | Dashboard — Entu API browser (live, not CDN) |
| `player/.config/nuxt.config.ts` | Workbox config, runtime env vars, PWA setup |

---

## Architecture Patterns

### Getter Function Composables (Vue 3.5+ idiom)
Every composable takes getters (`() => value`) not raw refs. This decouples reactivity from instantiation. All composables follow this pattern.

### Validity Window Filtering — 3 Levels
1. **Schedule** — `resolveActiveSchedule()` filters by `validFrom`/`validTo` before cron evaluation
2. **LayoutPlaylist** — `useScreen.validLayoutPlaylists` filters active schedule's zones
3. **PlaylistMedia** — `usePlaylist` filters `playlistMedias` reactively on each tick

### Responsive Canvas Scaling
If a schedule has fixed `width`/`height` > 0, `useScreen` computes a CSS `scale()` transform to fit the canvas to the browser window. Zones use px positioning against the fixed canvas.

### Cron-Driven Reset
If `layoutPlaylist.loop` + `cleanup=true`, playlist resets to index 0 on each cron tick. Otherwise advances linearly and holds last frame.

### Dual Timer (delay + duration)
`useMediaTimer` and `useMediaPlayback` both apply:
- `delay` seconds before start
- `duration` seconds total (image/URL) OR natural end (video/audio)

### Config Polling Optimization
`useScreenConfig` skips full update if `publishedAt` is unchanged — avoids redundant precache cycles.

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

## CRITICAL GAP: No Tests Exist

- ❌ No `player/tests/` directory
- ❌ No test runner (Vitest not in dependencies)
- ❌ No `.spec.ts` or `.test.ts` files anywhere

**Priority test targets for Plateau:**
1. `useScheduler.ts` — `getLastCronTick()`, `resolveActiveSchedule()` (pure functions, highest ROI)
2. `usePlaylist.ts` — index advancement, cleanup reset, validity filtering, loop behavior
3. `useMediaTimer.ts` — delay/duration chain, timer cleanup
4. `isWithinValidityWindow()` in `date.ts` — edge cases (null, past, future)
5. `useScreenConfig.ts` — skip-if-unchanged logic, fileDO normalization

---

## Gaps / Questions

1. **`usePrecache.ts` exists** — confirmed at `app/composables/usePrecache.ts` (missed in initial exploration; was reformatted in Phase 2).
2. **No `player/tests/` dir** — Plateau needs to scaffold Vitest before TDD can begin
3. **`mediaEid` field in `PlaylistMedia`** — referenced in types but not used in rendering; just telemetry?
4. **`layoutEid` in `Schedule`** — also in types but not used at runtime (denormalized into `layoutPlaylists`)
5. **Audio component background** — audio.vue renders black; if an audio-only playlist zone needs a background image, that's not supported today
6. **No media retry on error** — failed media calls `advance()` immediately with no retry
7. **No heartbeat** — no health check back to server; if player hangs silently, nobody knows

---

## Dashboard vs Player API Endpoints

| Context | Source | Auth |
|---------|--------|------|
| Player | `{apiBase}/screen/{screenId}.json` (CDN) | None |
| Dashboard | `{entuUrl}/{account}/entity?...` (Entu API) | None (public?) |

---

## Questions for Talbot
- Is the Entu API for dashboard public or does it need auth?
- Are `mediaEid` and `layoutEid` in ScreenConfig used anywhere beyond telemetry?

## Questions for Plateau
- Which test runner to scaffold? (Vitest is standard for Nuxt/Vite)
- Start with pure functions (`useScheduler`) or composables requiring mount?

## Questions for Daguerre
- Does the pipeline produce `fileDO` or `file`? The normalization in `useScreenConfig` converts `fileDO→file` — is this still needed or a legacy artifact?
