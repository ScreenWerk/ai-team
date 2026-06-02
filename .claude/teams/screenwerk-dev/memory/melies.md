# Melies Scratchpad
<!-- (*SW:Melies*) -->

## Session: 2026-04-07 — Initial Codebase Exploration

### Legacy File Map

```
legacy/app/
├── main.js          — Electron shell: window creation, multi-display, kiosk, PID management
├── index.html       — Renderer entry: #player div, #downloads div, #screenEid input UI
├── js/
│   ├── globals.js   — Init: credentials (YAML), paths, connectivity check, logging
│   ├── screenwerk.js — Orchestrator: readConfiguration, playConfiguration, pollUpdates
│   ├── sync.js      — Network: fetchConfiguration, loadMedias (download queue)
│   ├── renderDom.js — Renderer: DOM tree construction, cron scheduling, playback state machine
│   └── logging.js   — (not read yet — low priority)
└── theme.css        — (not read yet)
```

### Player File Map (relevant to migration)

```
player/app/
├── types.ts                          — ScreenConfig contract
├── composables/
│   ├── useScreenConfig.ts            — Fetch + publishedAt dedup + fileDO normalization
│   ├── useScheduler.ts               — getLastCronTick, resolveActiveSchedule
│   ├── useScreen.ts                  — Lifecycle: poll, clock tick, schedule eval
│   ├── usePlaylist.ts                — Media index, validity filter, loop/advance
│   ├── useMediaPlayback.ts           — Video/audio: delay, play/pause, cleanup
│   ├── usePrecache.ts                — Cache API: batch fetch, stale eviction
│   └── useDashboard.ts, useMediaTimer.ts — (not read)
```

---

## Behavior Mapping (initial pass)

### 1. Configuration Fetching

| Aspect | Legacy (sync.js) | New (useScreenConfig.ts) | Status |
|---|---|---|---|
| URL pattern | `https://swpublisher.entu.eu/screen/{screenEid}.json` | `{apiBase}/screen/{screenId}.json` (default: `files.screenwerk.ee`) | **API endpoint changed** |
| Dedup check | `publishedAt` timestamp comparison | `publishedAt` comparison | **Equivalent** |
| Temp file | `.json.download` while downloading | N/A (fetch API, no temp file) | **Electron-specific** |
| User-Agent | App version + git branch | Default browser UA | **Gap** (minor, diagnostic) |
| fileDO normalization | Not present (uses `playlistMedia.file` directly) | Promotes `fileDO` → `media.file` | **Improvement** |
| Error handling | Retry after 30s on failure | Silent catch, Workbox serves cache | **Equivalent** |

### 2. Media Handling / Caching

| Aspect | Legacy (sync.js loadMedias) | New (usePrecache.ts) | Status |
|---|---|---|---|
| Storage | Local filesystem (`local/sw-media/{mediaEid}`) | Cache API (`sw-media` cache) | **Different mechanism** |
| Timing | Blocking — ALL media downloaded before config applied | Non-blocking — config applied immediately, cache in background | **Improvement** |
| Concurrency | `async.queue` with concurrency=4 | `Promise.allSettled` batches (`precacheBatchSize` from config) | **Equivalent** |
| Retry on failure | Infinite retry loop | Best-effort, silent failure | **Gap** |
| Progress UI | DOM progress bars (2px tall, per-media) | None | **Gap** (minor, diagnostic) |
| Stale cleanup | On startup: cleans `.download` files | After each config load: removes URLs not in new config | **Improvement** |
| URL-type skip | Skips URL media (no file to download) | Skips URLs with falsy `file` field | **Equivalent** |
| Temp file | `{mediaEid}.download` → `{mediaEid}` on success | N/A | **Electron-specific** |
| Size validation | Compares `downloadedSize === content-length`, deletes on mismatch | HTTP response `r.ok` check only | **Gap** (robustness) |

### 3. Schedule Resolution / Playback

| Aspect | Legacy (renderDom.js) | New (useScheduler.ts + useScreen.ts) | Status |
|---|---|---|---|
| Cron library | `later` (`later.parse.cron`, `later.schedule`) | `cron-parser` v5 (`CronExpressionParser.parse()`) | **Different library** |
| Schedule sort | Most recent past tick, tie-break: higher ordinal wins | Same algorithm | **Equivalent** |
| `duration` unit | **SECONDS** (`duration * 1e3` ms) | **MINUTES** (`duration * 60_000` ms) | **⚠ CRITICAL: Unit changed** |
| `duration` field | Schedule-level | Schedule-level | **Equivalent** |
| `cleanup` flag — behavior | Stops ALL layouts on screen before starting this one | Resets playlist index to 0 on new cron tick (usePlaylist) | **⚠ Gap: semantics differ** |
| `ordinal` | Used for tie-breaking | Used for tie-breaking | **Equivalent** |
| `validFrom`/`validTo` | Checked per-media at play time only | Checked at schedule, layoutPlaylist, AND media level reactively | **Improvement** |
| Polling interval | Hard-coded 30 seconds | `updateInterval` minutes from config | **Improvement** |
| On config update | `app.relaunch()` + `app.quit()` (full process restart) | Reactive in-place update | **Improvement** |
| Clock tick | N/A (event-driven via setTimeout chains) | 30s interval (configurable `clockIntervalSeconds`) | **Different** |

### 4. Layout / Playlist Rendering

| Aspect | Legacy (renderDom.js) | New (usePlaylist.ts + components) | Status |
|---|---|---|---|
| Position | `inPixels` → convert to %; else direct % | `inPixels` field present in types.ts | **Equivalent** |
| Loop | `lastMediaNode.nextMediaNode = firstMediaNode` linked list | `loop` boolean in LayoutPlaylist | **Equivalent** |
| Media advance | Linked list traversal | `advance()` index increment | **Equivalent** |
| Media `delay` | `swMedia.delay * 1e3` (seconds → ms) | `media.delay * 1000` (seconds → ms) | **Equivalent** |
| Media `mute` | `mediaDomElement.muted = swMedia.mute` | `mute` in PlaylistMedia types.ts | **Equivalent** |
| Media `stretch` | NOT PRESENT | `stretch: boolean` in PlaylistMedia | **New feature (new only)** |
| URL media | Double-IFRAME: two created, first removed after 1s hack | Single IFRAME (presumably) | **Gap: reload behavior** |
| Image play/pause | Stubs: `mediaDomElement.play = () => {}` | Component-based | **Equivalent** |
| Visibility | `mediaNode.style.visibility = hidden/visible` | Component-based | **Equivalent** |
| Stop/start state machine | `playbackStatus` on DOM nodes | Vue reactive refs | **Equivalent** |

### 5. Offline Handling

| Aspect | Legacy | New | Status |
|---|---|---|---|
| Config offline | Reads `local/{screenEid}.json` from filesystem | Workbox NetworkFirst → falls back to cached response | **Equivalent** |
| Media offline | Reads `local/sw-media/{mediaEid}` from filesystem | CacheFirst via Workbox | **Equivalent** |
| Initial boot offline | Reads existing `.json` file; shows "CONFIGURATION_FILE_NOT_PRESENT" if absent | Workbox serves previously cached config | **Equivalent** |

### 6. Electron-Specific (No 2026 Equivalent)

| Feature | Legacy | 2026 | Status |
|---|---|---|---|
| Multi-display | `DISPLAY_NUM` in `screen.yml` → Electron display selection | N/A (browser tab) | **Electron-only** |
| Kiosk mode | `setFullScreen(true)` + `setKiosk(true)` | N/A | **Electron-only** |
| Skip taskbar | `setSkipTaskbar(true)` | N/A | **Electron-only** |
| PID file management | `local/.{pid}.pid` files, kills prior instances | N/A | **Electron-only** |
| Dev mode cursor | `body.style.cursor = 'crosshair'` | N/A | **Electron-only** |
| VBS launchers | Not yet read — `local/` directory only has `screen.yml` | N/A | Need to investigate |
| Playback log file | Rotating `{screenEid}.playback.log` | `console.log` | **Gap** (diagnostic) |
| YAML credentials | `local/screen.yml`: SCREEN_EID, SCREEN_KEY, DISPLAY_NUM | URL param / dashboard | **Different** |

---

## ⚠ Critical Findings for TDD Pairs

### 1. Duration Unit Change (CRITICAL)
- **Legacy**: `schedule.duration` = **seconds** (`renderDom.js:128`: `duration * 1e3`)
- **New**: `schedule.duration` = **minutes** (`types.ts:18`, `useScheduler.ts:39`: `duration * 60_000`)
- **Question**: Is the CDN JSON now publishing minutes, or did the unit change without updating the data?
- **Client impact**: A schedule with `duration: 30` would run 30s in legacy, 30min in new player. HIGH IMPACT.
- **Owner**: Needs Daguerre (pipeline) + Reynaud (player) + Talbot (Entu source) to verify.

### 2. `cleanup` Flag Semantics Differ (HIGH)
- **Legacy** (`renderDom.js:105-108`): `schedule.cleanup` → stops ALL other layout nodes on the screen before starting this schedule. "Hard takeover."
- **New** (`usePlaylist.ts:43-48`): `getCleanup()` → resets playlist index to 0 on new cron tick. "Soft reset."
- **Missing**: No equivalent of "stop all other active schedules" logic in new player.
- **Client impact**: If Piletilevi uses cleanup schedules for event overrides, behavior will differ visually.
- **Owner**: Plateau (test) + Reynaud (implementation).

### 3. URL Media Double-IFRAME Hack
- **Legacy** (`renderDom.js:390-408`): Creates two IFRAMEs, removes first after 1s. Forces reload on `play()` via `contentWindow.location.reload()`.
- **New**: Unknown — need to check URL media component. The `play()` reload behavior is important for URL-type refreshes.
- **Owner**: Need to read player URL media component.

### 4. No Retry on Media Download Failure
- **Legacy**: Infinite retry on any download failure.
- **New**: Silent best-effort (`Promise.allSettled`, `catch → warn`).
- **Client impact**: On flaky networks, media may not precache and will show blank on offline.
- **Owner**: Plateau (test) + Reynaud (implementation).

---

## Session: 2026-04-08 — Issue #2 Work

### Issue ScreenWerk/2026#2 — Confirm legacy duration interpretation

**Status: COMPLETE — reported to team-lead**

Task: confirm legacy codebase treats `schedule.duration` as seconds.

**Findings (all from `renderDom.js`):**

| Line | Code | Meaning |
|---|---|---|
| 128 | `self.swSchedule.duration * 1e3 < ms_from_latest_playback` | Stop if duration (s→ms) already exceeded |
| 137 | `self.swSchedule.duration * 1e3 < (ms_from_latest_playback + ms_until_next_playback)` | Need to schedule stop timeout |
| 138 | `self.swSchedule.duration * 1e3 - ms_from_latest_playback` | Compute remaining ms |
| 294 | `self.swMedia.duration * 1e3` | Media-level duration also seconds |

**Conclusion delivered to team-lead:**
- Legacy: `schedule.duration` = **seconds**
- New player `useScheduler.ts:39`: `duration * 60_000` = **minutes** → breaking unit mismatch
- Entu source values (30, 900, 3600) are seconds — confirmed by Talbot
- Fix decision delegated to Daguerre + Reynaud + Talbot (pipeline convert vs player revert)
- `media.duration` unit is **consistent** — seconds in both legacy and new `types.ts`

---

## Team Rules (as of 2026-04-08)

1. No task without a GitHub issue
2. No issue without TDD role assignments (RED = who, GREEN = who)
3. Full chain: Issue → Branch → TDD → PR → Merge
4. No direct commits to `main`

---

## Open Questions

1. What does `SCREEN_KEY` do in legacy? (stored in globals.js but not seen used in sync/render — may be auth header?)
2. Are VBS launcher scripts somewhere in the repo? (`legacy/local/` only has `screen.yml`)
3. What is `logging.js`? (not yet read — low priority)
4. New player URL media component — where is it? (need `player/app/components/`)
5. Does the CDN JSON currently publish `schedule.duration` in seconds or minutes? (pending pipeline team decision from issue #2)

---

## Next Steps (awaiting GitHub issues)

- Write `docs/migration/checklist.md` (master tracking document)
- Write individual domain analysis files (`config-fetching.md`, `media-handling.md`, `playback.md`, `offline.md`, `electron-specific.md`)
- Feed `cleanup` flag gap description to Plateau as test case input (once issue created)
- Feed URL media reload gap to Plateau once confirmed
