# Lumiere Scratchpad — updated 2026-06-18

## Session 2026-06-18 (in-harness teammates: reynaud, plateau)

### Closed this session

1. **Issue #2 (duration unit, seconds vs minutes) — CONFIRMED & CLOSED.**
   - Player pair (Reynaud + Plateau) verified `useScheduler.ts:43` converts `duration` seconds→ms (`* 1_000`); all other duration sites (`useMediaTimer`, `useMediaPlayback`, `types.ts`) consistent. No `* 60_000` anywhere.
   - Plateau added a regression test (`tests/unit/scheduler.test.ts`) locking the seconds semantics; proved RED by temporarily reverting to `* 60_000`. PR #10 merged.
   - Owed (PO-only): a client retest note to Tomas confirming live screens are correct.

2. **Signage bug issue form added** (`.github/ISSUE_TEMPLATE/signage-bug.yml`, PR #11 then slimmed in PR #12).
   - Final fields = observed-reality only: summary, client/account, player version, reporter & date, expected vs actual, published CDN JSON URL, values from that JSON, Entu CMS state, trace eids.
   - Triage/analysis fields deliberately excluded (severity, suspected cause, sizing, etc. — those happen after filing).
   - Label `needs-triage` created to match the form.

### Next-session FOCUS: Issue #9

GitHub ScreenWerk/2026#9 — "future-dated banner displays before its scheduled start (Bilietai)". Tomas reported 2026-06-12; the issue body is a clean observation record (facts + marked unknowns) using the new signage-bug structure.

**Investigate from scratch. Carry NO hypothesis into it.** The cause is unknown and unattributed by design. Method:
1. Identify the actual screen Tomas observed (currently unknown), then pull its **published CDN JSON** and read the `validFrom` the player actually received.
2. Read the **raw `sw_playlist_media` entity** via `api.entu.app` (not the CMS UI) and record the stored `valid_from` value(s) verbatim, plus created/edited timestamps.
3. Let those two artifacts localize it. Do not enumerate or rank causes before they exist. Talbot owns the Entu read; the actual screen/eids are still to be resolved.

(*SW:Lumiere*)
