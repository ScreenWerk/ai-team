# Niepce — Scratchpad

(*SW:Niepce*) — last updated 2026-04-07

---

## Codebase Exploration Findings

### Critical: player/scripts/ does NOT exist yet

The publish pipeline (`player/scripts/`) is entirely greenfield. There are zero pipeline scripts and zero test files. This is correct — TDD means I write RED tests before Daguerre writes any GREEN implementation.

### Critical: No test framework configured

`player/package.json` has no test runner. Before any pipeline tests can run, vitest must be added. This is a prerequisite blocker — I should flag this to Daguerre (needs `vitest` + `@vitest/coverage-v8` or similar added to devDependencies) before first RED test is written.

Natural choice: **Vitest** (native Vite/Nuxt ecosystem, fast, TypeScript-first).

---

## ScreenConfig Contract (`player/app/types/types.ts`)

Re-exported from `player/app/types.ts`.

```
ScreenConfig
  configurationEid: string
  screenGroupEid: string
  screenEid: string
  publishedAt: string          // ISO 8601
  updateInterval: number       // minutes
  schedules: Schedule[]

Schedule
  eid: string
  crontab: string
  cleanup: boolean
  duration?: number            // MINUTES active after cron tick
  ordinal: number
  validFrom?: string           // ISO 8601 optional
  validTo?: string             // ISO 8601 optional
  layoutEid: string
  name: string
  width: number                // 0 = fullscreen
  height: number               // 0 = fullscreen
  layoutPlaylists: LayoutPlaylist[]

LayoutPlaylist
  eid: string
  playlistEid: string
  name: string
  left: number
  top: number
  width: number
  height: number
  inPixels: boolean            // false = % (0-100); true = pixels
  zindex: number
  loop: boolean
  validFrom?: string
  validTo?: string
  playlistMedias: PlaylistMedia[]

PlaylistMedia
  playlistMediaEid: string
  mediaEid: string
  ordinal: number
  type: MediaType              // 'Image' | 'Video' | 'Audio' | 'URL'
  duration?: number            // SECONDS; for Image/URL only
  delay: number                // seconds before starting
  mute: boolean
  stretch: boolean             // true = object-fit: fill; false = contain
  file: string                 // CDN URL (normalized from fileDO)
  name: string
  url?: string                 // external URL; URL type only
  width?: number
  height?: number
  validFrom?: string
  validTo?: string
```

Also present:
- `player/app/types/entu.ts` — `EntuProp`, `EntuEntity`, `EntuFetchResult`
- `player/app/types/dashboard.ts` — `DashboardData` (for dashboard UI, not pipeline)

---

## Legacy vs New: Key Differences (Pipeline Must Handle)

| Concern | Legacy | New ScreenConfig | Test Required? |
|---|---|---|---|
| `schedules` shape | Object map `{ [id]: Schedule }` | Array `Schedule[]` | YES — transform test |
| `duration` unit (Schedule) | seconds | **minutes** | YES — unit conversion test |
| Media URL field | `fileName` + `file` | `file` only (normalized from `fileDO`) | YES — fileDO→file normalization |
| `playlistMedias` shape | Array | Array | OK |
| `validFrom`/`validTo` | ISO 8601 strings | ISO 8601 strings | Check formatting |
| CDN endpoint | `swpublisher.entu.eu` | `files.screenwerk.ee` | Reference only |
| `stretch` field | Not present in legacy | Required in new type | Flag to Talbot |
| `zindex` on LayoutPlaylist | Not in legacy | Required in new type | Flag to Talbot |
| `updateInterval` | Hardcoded 30s in player | Field in ScreenConfig | Check Entu source |
| `ordinal` on PlaylistMedia | Present | Present | Sort order test |

---

## Entu Entity Chain (publish pipeline traversal)

```
sw_configuration
  └── sw_screen_group (ref)
        └── sw_screen (ref, multiple)
              └── sw_schedule (ref, multiple)
                    └── sw_layout (ref)
                          └── sw_layout_playlist (ref, multiple)
                                └── sw_playlist (ref)
                                      └── sw_playlist_media (ref, multiple)
                                            └── sw_media (ref)
```

Entu API: `https://entu.app/api/{account}/entity`
Accounts: `piletilevi`, `bilietai`

Property model: `EntuEntity` has `_id: string` + typed prop arrays.
Utility `val(entity, propName, type)` in `player/app/utils/entu.ts` handles extraction.

---

## Entu Types Available in Codebase

```typescript
interface EntuProp {
  _id?: string
  string?: string
  boolean?: boolean
  number?: number
  reference?: string
  datetime?: string
  filename?: string
  [key: string]: unknown
}

interface EntuEntity {
  _id: string
  [key: string]: EntuProp[] | string
}
```

---

## Test Categories to Write (priority order)

1. **Test framework setup** — prerequisite, flag to Daguerre
2. **Field mapping** — each ScreenConfig field traced to Entu source prop
3. **Entity reference resolution** — follow the chain configuration→screen_group→screen
4. **`fileDO` → `file` URL normalization** — media CDN URL must be `file`, not `fileDO`
5. **`schedules` as array** — must be sorted by `ordinal`
6. **`playlistMedias` sorted by `ordinal`**
7. **`duration` unit on Schedule** — verify pipeline outputs minutes, not seconds
8. **`validFrom`/`validTo` formatting** — ISO 8601 strings from Entu `datetime` props
9. **Missing/null property handling** — optional fields absent when Entu prop missing
10. **Empty playlists** — `layoutPlaylists: []` or `playlistMedias: []` handled gracefully
11. **`publishedAt` updates on every republish**
12. **`updateInterval` sourced from Entu** (or default value)

---

## Open Questions / Flags

- **Q1 (→ Talbot):** Which Entu property on `sw_schedule` maps to `duration` in minutes? Legacy used seconds. Need confirmation.
- **Q2 (→ Talbot):** What Entu prop provides `stretch` (object-fit) for PlaylistMedia? Not in legacy system.
- **Q3 (→ Talbot):** What Entu prop provides `zindex` on `sw_layout_playlist`?
- **Q4 (→ Talbot):** What Entu prop provides `updateInterval` on `sw_configuration`?
- **Q5 (→ Daguerre):** Confirm test framework choice (Vitest) and add to `player/package.json` before first RED.
- **Q6 (→ Lumiere):** Should I create a GitHub issue for "add vitest to pipeline" as prerequisite?

---

## Player Composables (read-only reference)

| Composable | Relevant to pipeline tests? |
|---|---|
| `useScheduler.ts` — `resolveActiveSchedule()`, `getLastCronTick()` | NO — player side |
| `useScreenConfig.ts` — fetches + normalizes JSON | Partial: `fileDO→file` logic here shows expected field name |
| `usePrecache.ts` | NO |
| `useScreen.ts` | NO |

The `fileDO→file` normalization in `useScreenConfig.ts` is currently done on the **player side**. The pipeline should output `file` directly; the player normalization may be redundant/defensive. This is a point to clarify with Daguerre — but tests should assert pipeline outputs `file`.

---

## Status

- [x] Read common-prompt, role prompt, player README
- [x] Explored `player/scripts/` — does not exist
- [x] Explored `player/app/types.ts` — fully understood
- [x] Explored legacy sync/render scripts — key diffs noted
- [ ] Vitest setup (prerequisite — needs Daguerre)
- [ ] First RED test (awaiting GitHub issue + branch)
