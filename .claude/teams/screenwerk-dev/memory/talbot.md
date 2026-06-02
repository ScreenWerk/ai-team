# Talbot Scratchpad — updated 2026-06-02

## 2026-06-02 RE-VERIFICATION — Bilietai S/G situation RESOLVED + API HOST CORRECTION

**8-week gap since last update (2026-04-08).** Team-lead asked me to re-verify the deleted Bilietai screen group state, read-only. Findings:

**CRITICAL CORRECTION TO PRIOR FINDINGS:** The correct Entu API host is `https://api.entu.app/{account}/...`, NOT `https://entu.app/api/{account}/...`. The latter serves the SPA HTML and returns misleading 404/200 on the *page route*, not the entity. My 2026-04-08 "entity 404 / deleted" conclusion may have been partly a host artifact (querying the wrong host). Whether a real DELETE also occurred is now moot — see below.

**Current live state (all via `https://api.entu.app/piletilevi/...`, read-only):**
1. Screen group `5541ec724ecca5c17a5992dc` — RESOLVES (200). Healthy: name "Bilietai RIMI and other Live S/G", `configuration.reference` → `5541ec554ecca5c17a5992da` (intact), `published.datetime` = 2026-05-29T09:38:21.240Z (published days ago), `ispublished.boolean` = false. NOT 404. NOT orphaned.
2. Configuration `5541ec554ecca5c17a5992da` — RESOLVES (200). "BP RIMI Live Conf", update_interval=1.
3. Screen `5562c3374ecca5c17a59938d` (BP_Rimi_T763_Vilnius) — exists; `screen_group.reference` correctly points to `5541ec72...`. NO LONGER orphaned.
4. **Q7 ANSWERED:** 78 screens reference S/G `5541ec72...` (query `_type.string=sw_screen&screen_group.reference=5541ec72...`). All correctly pointed. No orphans found.
5. CDN JSON `https://files.screenwerk.ee/screen/5562c3374ecca5c17a59938d.json` — 200, `publishedAt` = 2026-05-29T09:38:21.240Z (matches S/G published.datetime exactly). Current, NOT stale. configurationEid + screenGroupEid resolve to live entities.

**CONCLUSION:** Bilietai S/G situation is fully resolved — entity present, references intact across 78 screens, CDN re-published 2026-05-29 and consistent. No recovery action needed. The do-not-republish warning is LIFTED. Prior URGENT block obsolete.

---

## 2026-06-02 T777 KLAIPEDA STALE-AD BUG (Tomas) — root cause = device-side, NOT CDN/data

Symptom: ad still showing at BP_Rimi_T777_Klaipeda after campaign ended 31 May; NOT on other box offices.

Findings (read-only):
- Offending ad = `blt_lewis capaldi 05 31`, sw_media `69732f32d8f0733e82893753`, type Image. sw_media.valid_to = 2026-05-31T17:20:17Z (matches CDN exactly -> publisher reads sw_media, confirms prior finding). sw_playlist_media `69732f85...`.valid_to = 2026-05-31T18:21:42Z (ignored by publisher). Both = 31 May. Campaign genuinely ended.
- T777 screen = `5577dea44ecca5c17a599427`, screen_group `5541ec72...`, config `5541ec55...`. published 2026-05-29.
- T777 CDN config publishedAt = 2026-05-29T09:38:21Z. Last-Modified 29 May, max-age=60.
- CDN configs for T777 / T763 / T774 are BYTE-IDENTICAL except screenEid + _mid. The expired lewis-capaldi media (validTo 31 May) is present in ALL THREE, including the siblings that do NOT display it.
- Player validity logic is CORRECT and runtime: `utils/date.ts isWithinValidityWindow` returns false when validTo <= now; `usePlaylist.validMedias` re-filters reactively on getNow(). A correctly-running player on 2 Jun WOULD hide this media.

CONCLUSION — distinguishing (a)/(b)/(c):
- (a) stale CDN for this one screen: RULED OUT. All siblings share identical, current CDN config.
- (b) player ignores validTo without re-publish: RULED OUT by code — filtering is runtime by now, not publish-time. (Re-publishing would NOT remove it from JSON anyway; it's filtered live.)
- (c) device-side issue on the T777 player: MOST LIKELY. Identical config + correct filter + only-one-screen-affected => something specific to that device. Prime suspects: (i) device clock wrong / set before 31 May, so getNow() < validTo; (ii) tab/app suspended so getNow() ticker frozen at an old time; (iii) PWA offline/stale-app-shell so an OLD app build without correct filtering, or a frozen page, keeps rendering.

Recommended next checks (for whoever owns device): T777 device system clock & timezone; whether the player tab is live/foreground; force-reload / clear PWA cache on that device; check player build version on device vs current.

BLOCKED-PUBLISH CHECK (PO heuristic, fresh reads 2026-06-02 19:24): if sw_screen_group.published.datetime (requested) > CDN publishedAt (completed) => publish blocked by a data error. RESULT: NOT blocked.
- Screengroup 5541ec72... published.datetime = 2026-05-29T09:38:21.240Z (fresh).
- T777 CDN publishedAt = 2026-05-29T09:38:21.240Z. T763 CDN publishedAt = 2026-05-29T09:38:21.240Z. ALL EQUAL -> heuristic does not fire. Blocked-publish RULED OUT. No data-error hunt needed.
- ispublished.boolean = false (no publish pending/in-progress; last publish completed cleanly).
- TIMELINE NOTE: last + only recent publish = 29 May, which is BEFORE the 31 May campaign end. No publish attempt after 31 May until PO re-published 19:31 today.

RE-PUBLISH TEST (PO re-published S/G 5541ec72... at 2026-06-02 19:31; cache-busted re-check):
- Screengroup published.datetime advanced 2026-05-29 -> 2026-06-02T19:31:52.936Z. ispublished still false.
- T777 CDN publishedAt advanced to 2026-06-02T19:31:52.936Z (Last-Modified 19:32 today; fresh, not cached). Size 6608 -> 6112 bytes.
- "blt_lewis capaldi 05 31" (mediaEid 69732f32...) is NOW ABSENT from the JSON. Media count 12 -> 11.
- **CORRECTION to my earlier claim**: I previously asserted re-publish would NOT remove expired-but-windowed media. WRONG. The publisher DOES strip past-validTo media at publish time. New mental model: publisher omits media whose validTo < publish-time; player ALSO filters validTo at runtime (belt-and-suspenders). So expired media leaves the JSON on the next publish.
- IMPLICATION for the bug: the 29-May JSON legitimately still contained lewis-capaldi (validTo 31 May was still in the future at publish time). Working screens hid it via runtime filter; T777 did not -> still device-side (clock/frozen-tab/stale-shell). The re-publish is now a belt-and-suspenders fix: even a broken device that ignores runtime validTo will stop showing it once it fetches the new JSON (if it can fetch at all). If T777 STILL shows it after picking up the new config, that strongly confirms the device is offline/frozen/not-fetching.

Side note: useScheduler.ts:43 now uses `s.duration * 1_000` (seconds) — issue #2 duration-unit bug appears ALREADY FIXED since my 2026-04-08 note. Verify separately.

(*SW:Talbot*)

---

# Talbot Scratchpad — prior content (2026-04-08)

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

### Issue #2: schedule.duration unit (2026-04-08)

**RESOLVED:** Entu stores `sw_schedule.duration` in **seconds**. Evidence: values like 900 (15 min), 3600 (1 hour). Legacy player correctly uses `* 1e3`. New player incorrectly uses `* 60_000` (treats as minutes). Bug in `useScheduler.ts:43`, `types.ts:23` comment, `schedule.vue:33` label.

### Tomas Investigation: deleted content still showing (2026-04-08)

**KEY FINDING:** Publisher sources `validFrom`/`validTo` from `sw_media`, NOT `sw_playlist_media`.

Evidence: CDN JSON validity dates match `sw_media.valid_from/valid_to` exactly, differ from `sw_playlist_media.valid_from/valid_to`. Example: `sok edita` (ord 38) has playlist_media validTo=Apr 19 but CDN uses media validTo=May 12.

**Impact:** CMS users editing validity on `sw_playlist_media` have no effect on player display. Publisher ignores those dates.

**Status:** No deleted-but-present items detected in current snapshot (12 items match between Entu and CDN). CDN was re-published today. Need PO to clarify with Tomas what "deleted" means in his workflow.

**Note:** `bilietai` account returns 404 on Entu API — all Bilietai entities live under `piletilevi` account.

### URGENT: Bilietai screen group deleted (2026-04-08) — **OBSOLETE / RESOLVED as of 2026-06-02, see top of file**

**Entity `5541ec724ecca5c17a5992dc`** (Bilietai RIMI and other Live S/G) was accidentally deleted via `DELETE /api/piletilevi/entity/{id}`. Entu has NO undo.

**Current state:**
- Entity: 404 (gone)
- CDN JSON: still serving stale data (players unaffected for now)
- Screen `5562c337...` (BP_Rimi_T763_Vilnius): exists but `screen_group.reference` is orphaned
- Configuration `5541ec55...` (BP RIMI Live Conf): exists
- All downstream entities (schedules, layouts, playlists, media): exist

**Recovery requires:**
1. Recreate `sw_screen_group` entity in Entu CMS (PO task)
2. Set `configuration.reference` → `5541ec554ecca5c17a5992da`
3. Update screen(s) to reference new screen group ID
4. Re-publish

**DO NOT re-publish until screen group is recreated** — publisher will produce broken JSON.

**Lesson learned:** `DELETE /entity/{id}` deletes the whole entity. To remove individual properties, use `DELETE /property/{propertyId}`.

### Team Rules (2026-04-08)

1. No work without a GitHub issue
2. No issue without TDD role assignment (RED/GREEN)
3. Full workflow: Issue → Branch → TDD → PR → Merge
4. No direct commits to main

### Questions to Investigate

- Q1: What triggers `published.datetime` to update on `sw_screen_group`? Is it a manual CMS action or automatic?
- Q2: Does `file.filename` on `sw_media` return the CDN URL directly, or does it need to be constructed?
- Q3: How does `add_from` work in Entu entity definitions? Not seen in current code.
- Q4: Are there Entu properties on these entity types beyond what the dashboard fetches?
- Q5: Is `sw_playlist.valid_from/valid_to` intentionally excluded from ScreenConfig, or is it a gap?
- Q6: Should the new pipeline use `sw_playlist_media.validFrom/To` or `sw_media.validFrom/To` or the more restrictive of both?
- Q7: Are there other Bilietai screens besides `5562c337...` that referenced the deleted screen group?

(*SW:Talbot*)
