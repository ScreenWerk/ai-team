# Lumiere Scratchpad — updated 2026-06-02

## Session 2026-06-02 (no tmux; in-harness teammates)

Spawned only **Talbot** (per PO). Others (daguerre, niepce, reynaud, plateau, melies) not spawned.
Cleared 6 stale tmux-pane registrations from config.json at startup (prior session's dead panes).

### Resolved this session

1. **Old Bilietai S/G "deleted" scare — CLOSED.** Talbot's April "404/deleted" finding for screen group `5541ec72…` was a HOST ARTIFACT. Correct Entu API host is `https://api.entu.app/{account}/...` (NOT `entu.app/api/{account}/...`, which serves SPA HTML and fakes 404s). Current state healthy: entity resolves, 78 screens reference it correctly, CDN re-published. "Do-not-republish" warning LIFTED.

2. **Tomas T777 Klaipeda stale-ad bug — HANDLED.** Ad "blt_lewis capaldi 05 31" (sw_media `69732f32…`, validTo 31 May) showing only at BP_Rimi_T777_Klaipeda (screen `5577dea44ecca5c17a599427`, group `5541ec72…`); siblings clean.
   - Root cause = **device-side on T777** (clock / frozen tab / stale PWA shell). Ruled out: stale-CDN-per-screen, player-ignores-validTo, blocked-publish-from-data-error (PO's heuristic — checked clean).
   - PO re-published → `publishedAt` advanced to 19:31 today, expired ad STRIPPED from JSON (12→11 media). Confirmed publisher excludes past-validTo media at publish time.
   - PO sent client reply (Gmail draft I created): reload T777 / open in browser, check device clock.

### Open / deferred follow-ups
- **If T777 doesn't clear after reload** → open player-side issue (runtime validTo filter / stale app-shell / polling) for Reynaud + Plateau, under issue→TDD→PR gate.
- **Issue #2 (duration unit, seconds vs minutes):** Talbot reports `useScheduler.ts:43` now uses `* 1_000` — appears ALREADY FIXED since April. Needs confirm/close (player pair).
- Possible publisher hardening: explicitly strip past-validTo media as a documented guarantee (it already does — worth a test to lock it in). Pipeline pair if pursued.

### Memory written (auto-memory)
- reference_entu_api.md — added api.entu.app host correction
- reference_publish_failure_symptom.md — PO's blocked-publish heuristic
- reference_stale_content_diagnosis.md — full "ad past end date" decision tree

(*SW:Lumiere*)
