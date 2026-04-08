# Talbot Scratchpad — 2026-04-07

## Codebase Exploration Findings

### ScreenConfig Contract (`player/app/types.ts`)

The central contract between publish pipeline and player. Four interfaces:

| Interface | Key fields | Notes |
|---|---|---|
| `ScreenConfig` | configurationEid, screenGroupEid, screenEid, publishedAt, updateInterval, schedules[] | Top-level screen JSON |
| `Schedule` | eid, crontab, cleanup, duration?, ordinal, validFrom/To?, layoutEid, name, width, height, layoutPlaylists[] | cron-based activation |
| `LayoutPlaylist` | eid, playlistEid, name, left/top/width/height, inPixels, zindex, loop, validFrom/To?, playlistMedias[] | Zone positioning |
| `PlaylistMedia` | playlistMediaEid, mediaEid, ordinal, type, duration?, delay, mute, stretch, file, name, url?, width?, height?, validFrom/To? | Media item |

### Entu Types (`player/app/types/entu.ts`)

Generic interfaces for raw Entu API responses:
- `EntuProp` — property bag with typed fields: string, boolean, number, reference, datetime, filename
- `EntuEntity` — _id + dynamic property arrays
- `EntuFetchResult` — { entities: EntuEntity[] }

### Entu API Query Patterns (from `player/app/pages/[account]/index.vue`)

Dashboard fetches ALL entity types with specific property projections:

| Entity type | Properties fetched |
|---|---|
| `sw_screen_group` | name.string, published.datetime, configuration.reference |
| `sw_screen` | name.string, screen_group.reference |
| `sw_configuration` | name.string, update_interval.number |
| `sw_schedule` | name.string, _parent.reference, crontab.string, layout.reference, ordinal.number, duration.number, valid_from.datetime, valid_to.datetime, cleanup.boolean |
| `sw_layout` | name.string, width.number, height.number |
| `sw_layout_playlist` | name.string, _parent.reference, playlist.reference, left.number, top.number, width.number, height.number, zindex.number, loop.boolean, in_pixels.boolean |
| `sw_playlist` | name.string, valid_from.datetime, valid_to.datetime |
| `sw_playlist_media` | name.string, _parent.reference, media.reference, ordinal.number, duration.number, delay.number, valid_from.datetime, valid_to.datetime, mute.boolean, stretch.boolean |
| `sw_media` | name.string, type.string, file.filename, url.string, valid_from.datetime, valid_to.datetime |

API URL pattern: `{entuUrl}/{account}/entity?_type.string={type}&props={prop_list}&limit=9999`

### Entu Utility (`player/app/utils/entu.ts`)

- `val(entity, prop, type?)` — extracts first value from property array, auto-detects type
- `byName(a, b)` — sort by name property
- `byOrdinal(a, b)` — sort by ordinal property

### Relationship Chains (from dashboard data)

```
sw_screen_group → configuration.reference → sw_configuration
sw_screen → screen_group.reference → sw_screen_group
sw_schedule → _parent.reference → sw_configuration
sw_schedule → layout.reference → sw_layout
sw_layout_playlist → _parent.reference → sw_layout
sw_layout_playlist → playlist.reference → sw_playlist
sw_playlist_media → _parent.reference → sw_playlist
sw_playlist_media → media.reference → sw_media
```

### Key Observations

1. **No publish pipeline exists yet.** `player/scripts/` is empty — pipeline not built. This is the work Daguerre will build.

2. **No `docs/entu/` exists yet.** My documentation output directory needs to be created.

3. **`fileDO` normalization quirk.** `useScreenConfig.ts:26` normalizes `fileDO` into `file` — the CDN JSON apparently uses `fileDO` as the property name from Entu, but ScreenConfig expects `file`. This is a known mapping gap.

4. **Legacy publisher URL.** Legacy code (`globals.js:212`) uses `https://swpublisher.entu.eu/screen/` — different from current CDN `https://files.screenwerk.ee`. The old publisher was a separate service.

5. **Legacy uses same JSON shape.** `sync.js` reads `publishedAt`, iterates `schedules[].layoutPlaylists[].playlistMedias[]` — the CDN JSON shape is preserved from legacy.

6. **`published.datetime` on `sw_screen_group`** — dashboard sorts screen groups by this field and shows "Published X ago". This appears to be the timestamp of last publish action. Needs verification against Entu.

7. **`_parent.reference` pattern.** Used by schedules (parent=configuration), layout_playlists (parent=layout), playlist_medias (parent=playlist). This is Entu's built-in parent-child hierarchy.

8. **Missing from ScreenConfig but present in Entu:** `sw_playlist.valid_from/valid_to` — playlists have validity windows in Entu but ScreenConfig doesn't expose them at playlist level (only at LayoutPlaylist and PlaylistMedia level).

### Questions to Investigate

- Q1: What triggers `published.datetime` to update on `sw_screen_group`? Is it a manual CMS action or automatic?
- Q2: Does `file.filename` on `sw_media` return the CDN URL directly, or does it need to be constructed?
- Q3: How does `add_from` work in Entu entity definitions? Not seen in current code.
- Q4: Are there Entu properties on these entity types beyond what the dashboard fetches?
- Q5: Is `sw_playlist.valid_from/valid_to` intentionally excluded from ScreenConfig, or is it a gap?

(*SW:Talbot*)
