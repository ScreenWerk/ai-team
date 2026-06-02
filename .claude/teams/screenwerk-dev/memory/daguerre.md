# Daguerre Scratchpad — Pipeline Builder

(*SW:Daguerre*)

## Codebase Exploration (2026-04-07)

### Key Finding: No publish pipeline exists yet

`player/scripts/` directory does **not exist**. The publish pipeline — my primary deliverable — has not been started. This is greenfield work.

### ScreenConfig Contract (`player/app/types.ts`)

The target JSON shape I must produce:

```
ScreenConfig
  ├── configurationEid: string
  ├── screenGroupEid: string
  ├── screenEid: string
  ├── publishedAt: string
  ├── updateInterval: number
  └── schedules: Schedule[]
        ├── eid, crontab, cleanup, duration?, ordinal
        ├── validFrom?, validTo?
        ├── layoutEid, name, width, height
        └── layoutPlaylists: LayoutPlaylist[]
              ├── eid, playlistEid, name
              ├── left, top, width, height, inPixels, zindex, loop
              ├── validFrom?, validTo?
              └── playlistMedias: PlaylistMedia[]
                    ├── playlistMediaEid, mediaEid, ordinal
                    ├── type: 'Image'|'Video'|'Audio'|'URL'
                    ├── duration?, delay, mute, stretch
                    ├── file (CDN URL), name, url?
                    ├── width?, height?
                    └── validFrom?, validTo?
```

### Entu Types (`player/app/types/entu.ts`)

- `EntuEntity`: `{ _id: string, [key: string]: EntuProp[] | string }`
- `EntuProp`: `{ string?, boolean?, number?, reference?, datetime?, filename? }`
- Properties are arrays of `EntuProp` objects; first element used via `val()` helper

### Entity-to-ScreenConfig Mapping (from dashboard `index.vue`)

The dashboard already fetches all 9 entity types with their props. Key property names from the `entuFetch` calls:

| Entity Type | Properties Fetched |
|---|---|
| `sw_configuration` | `name.string`, `update_interval.number` |
| `sw_screen_group` | `name.string`, `published.datetime`, `configuration.reference` |
| `sw_screen` | `name.string`, `screen_group.reference` |
| `sw_schedule` | `name.string`, `_parent.reference`, `crontab.string`, `layout.reference`, `ordinal.number`, `duration.number`, `valid_from.datetime`, `valid_to.datetime`, `cleanup.boolean` |
| `sw_layout` | `name.string`, `width.number`, `height.number` |
| `sw_layout_playlist` | `name.string`, `_parent.reference`, `playlist.reference`, `left.number`, `top.number`, `width.number`, `height.number`, `zindex.number`, `loop.boolean`, `in_pixels.boolean` |
| `sw_playlist` | `name.string`, `valid_from.datetime`, `valid_to.datetime` |
| `sw_playlist_media` | `name.string`, `_parent.reference`, `media.reference`, `ordinal.number`, `duration.number`, `delay.number`, `valid_from.datetime`, `valid_to.datetime`, `mute.boolean`, `stretch.boolean` |
| `sw_media` | `name.string`, `type.string`, `file.filename`, `url.string`, `valid_from.datetime`, `valid_to.datetime` |

### Reference Resolution Chain

```
sw_screen → screen_group.reference → sw_screen_group
sw_screen_group → configuration.reference → sw_configuration
sw_schedule → _parent.reference → sw_configuration (parent)
sw_schedule → layout.reference → sw_layout
sw_layout_playlist → _parent.reference → sw_layout (parent)
sw_layout_playlist → playlist.reference → sw_playlist
sw_playlist_media → _parent.reference → sw_playlist (parent)
sw_playlist_media → media.reference → sw_media
```

### Player-side fileDO normalization (`useScreenConfig.ts:22-26`)

The player currently normalizes `fileDO` → `file` on load. This suggests the CDN JSON currently (or historically) uses `fileDO` as the field name. My pipeline should output `file` directly (matching the type), but I should verify with Talbot what the Entu API actually returns for `sw_media.file`.

### Legacy System Notes

- **Legacy CDN base:** `https://swpublisher.entu.eu/screen/{screenId}.json` (different from current `files.screenwerk.ee`)
- Legacy fetches config JSON, compares `publishedAt` timestamp, downloads media files to local filesystem
- Media types match: `URL`, `Image`, `Video`, `Audio`
- Legacy uses `playlistMedia.file` for media URLs — same field name as ScreenConfig

### Nuxt Config (`player/.config/nuxt.config.ts`)

- CDN base: `https://files.screenwerk.ee` (env: `NUXT_PUBLIC_API_BASE`)
- Entu API: `https://entu.app/api` (env: `NUXT_PUBLIC_ENTU_URL`)
- Default account: `piletilevi`
- Workbox caching: `sw-configs` (NetworkFirst) for JSON, `sw-media` (CacheFirst) for media files

### Questions for Talbot

1. What does the Entu API return for `sw_media.file`? Is it `file.filename` with a CDN URL, or a different structure?
2. How does `fileDO` relate to the standard `file` property? Is it an alias, a computed field, or legacy naming?
3. What auth is needed for the Entu API fetch in the publish script? The dashboard uses unauthenticated requests — will the pipeline need auth?

### Gaps / Open Items

- **No test infrastructure** — `player/tests/` doesn't exist, `player/scripts/tests/` doesn't exist. Niepce and I need to set up the test framework.
- **No `vitest` or test runner** in `package.json` devDependencies
- **Pipeline output target:** CDN at `{CDN}/screen/{screenId}.json` — need to understand the upload mechanism (S3? SCP? API?)

## Session Status (2026-04-08)

### Work Done
- Explored full codebase relevant to pipeline role
- Mapped ScreenConfig contract, all 9 Entu entity types and their properties
- Mapped full reference resolution chain (screen → screen_group → config → schedules → layouts → playlists → medias)
- Documented legacy system's approach (`swpublisher.entu.eu`, `sync.js`)
- Identified that `player/scripts/` is greenfield — no pipeline code exists yet

### Issues Worked On
- None — no GitHub issues assigned yet

### Team Rules Acknowledged
1. No work without a GitHub issue
2. No issue without TDD role assignment (RED/GREEN)
3. Full workflow: Issue → Branch → TDD → PR → Merge (no direct commits to main)

### Open Questions (unanswered — need Talbot)
1. `fileDO` vs `file` semantics in Entu API responses
2. Auth requirements for Entu API in publish pipeline context
3. CDN upload mechanism for `files.screenwerk.ee`

### Next Steps (when resuming)
- Wait for GitHub issue assignment from team-lead
- Coordinate with Niepce on test infrastructure setup (vitest, test dirs)
- Ask Talbot the open questions above once he's available
