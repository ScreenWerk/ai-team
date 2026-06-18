# Lumiere Scratchpad — updated 2026-06-18 (session 2)

## Session 2026-06-18 #2 (in-harness teammates: talbot, melies)

### Issue #9 — future-dated banner displayed early (Bilietai) — INVESTIGATED, PARKED

Investigated from scratch (no carried hypothesis). Conclusion: **no pipeline/player defect demonstrated.**

- Banner `sw_media` [`6a2bfaad…`] has CORRECT future start: `valid_from 2026-06-15 10:00 EEST`.
- Banner is **orphaned** — no `sw_playlist_media` references it as of 06-18 (all 158 re-scanned). CMS screenshot proves a playlist-media existed at 06-12 15:48; removed since.
- Banner **absent from published config on BOTH endpoints** — `.ee` (files.screenwerk.ee) and `.eu` (swpublisher.entu.eu) are **byte-identical** (same md5/etag), publishedAt 06-12 12:56. Only laukine antis (ord 410) + delfi (ord 412) present; gap at ord 411 (weak inference: removed banner).
- Entity chain: media → playlist `64f7f303…` (LT Jaunimo teatras) → … → screen `BLT_Jaunimo_teatras` `64f7f3f04ecca5c17a5980d6`.
- GitHub #9: body updated with eids (Entu-linked) + conclusion **comment** posted.
- **Gated on:** Tomas (OOO until 2026-06-23 — question sent via PO Gmail) for exact screen/time/live-vs-preview; and/or Anydesk look at the box (device clock + cached `local/` config). Most likely origin if real = device-side cache on the 2016 box.

### Player version determination — DONE

- **Box-office players = Screenwerk-2016** (Electron, git-pull self-update on launch, local-FS media cache). FACT via client install guide (`github.com/ScreenWerk/Screenwerk-2016#readme`) + legacy code + repo analysis. HW: Linux Mint NUCs (EE), Windows (LV/LT).
- **Web beta = Screenwerk-2025** (`screenwerk.entu.ee`, `?screen_id=` then `/player/#`).
- **Target = 2026 Nuxt**. Migration is **2016 → 2026** (design-spec's "2018" baseline was wrong).
- Recorded to auto-memory + Brilliant KB `Projects/screenwerk-2026` (corrected the "random intermediate rewrite" line; added version-lineage section). v3.

### Duration unit (Issue #2) — re-verified, NO regression
Melies' closing [WARNING] claimed `useScheduler.ts:39 *60_000` (minutes). FALSE — current `useScheduler.ts:43` = `s.duration * 1_000` (seconds→ms). PR #10 fix intact. Melies read a stale view.

### Infra: Brilliant KB MCP wired this session
- Cortex API: `http://100.114.187.12:8010` (p2rtela6 on tailnet), Bearer = CORTEX_API_KEY. REST: `/entries` (GET/POST), `/entries/{id}` (GET/PUT/DELETE).
- MCP server copied to `~/projects/xireactor-brilliant/mcp` (from `michelek@ai-mvox-eu`), venv built, wired into `~/.claude.json` mcpServers.brilliant + `mcp__brilliant__*` allowlisted. Activates on restart; verified live.
- This host = `ai-screenwerk-ee` (tailnet). srv1559865 / ai.screenwerk.ee, Hostinger KVM 2 Vilnius.

### Carryover for next session
- Issue #9: chase Tomas reply (post 06-23) / Anydesk.
- Melies [DEFERRED]: migration checklist (`docs/migration/`) still unwritten — needs a GitHub issue + task first (per workflow gate).

(*SW:Lumiere*)
