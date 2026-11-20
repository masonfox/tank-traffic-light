## Why

Tank Traffic Light has shipped (v0.1.0) without any specs. Before changing behavior, we need a baseline that records what the addon does today, so later changes can be written as precise deltas against it.

## What Changes

- No code or behavior changes. This change only records current behavior as specs.
- Records six capabilities that describe the addon as implemented in `Safe.lua`, `Probe.lua`, `Lights.lua`, `Options.lua`, and `Core.lua`.
- Lists known quirks and gaps (below) as **open questions** rather than requirements, so they are not locked in.

## Capabilities

### New Capabilities
- `safe-api-access`: How every game API read handles "secret" (restricted) values and errors without ever raising.
- `threat-classification`: Rules that turn a hostile unit's threat/target situation into GREEN, YELLOW, RED, or no light.
- `display-gating`: When lights are allowed to run at all: master toggle, tank-only role filter, zone filters.
- `nameplate-lights`: The traffic light widget on nameplates: look, placement, scale, pulse, lifecycle, and refresh cadence.
- `settings`: Saved variables, defaults, reset, the options window, the AddOns menu entry, and slash commands.
- `diagnostics`: Demo mode, the light-change trace log, `/ttl why`, the API probe, and auto-probe.

### Modified Capabilities
<!-- None: no specs exist yet. -->

## Known Quirks and Open Questions

These describe current behavior but are deliberately left out of the requirements so a follow-up change can decide on them:

1. **Refresh gap while the player is out of combat.** Periodic re-evaluation only runs while the player is in combat. If a mob enters combat with a group member while the player is not in combat, and the mob's target event fires before the mob counts as "in combat", its light stays hidden until a later event. Candidate fixes: also react to unit flag changes, or poll while any group member is in combat.
2. **Slash commands and the options window don't match** (agreed direction: the UI is the source of truth and slash commands should mirror it):
   - Scale accepts a comma decimal (`1,5`) in the window but not in `/ttl scale`.
   - Top offset, pulse, placement side, and the zone filters have no slash commands.
3. **Trace misses gating transitions.** When a light disappears because gating turned off (lights disabled, zone, role), no trace entry is recorded.
4. **`/ttl why` appends to the trace log without trimming it.** The 300-line cap is only enforced on the next light-change entry.
5. **`/ttl why` has side effects.** Besides explaining, it re-runs the light update for every visible nameplate.
6. **Fallback cast-target flicker.** When threat status is unreadable, the fallback uses the mob's current target. A mob that briefly switches target to cast at a group member can flash RED.

## Impact

- New files under `openspec/specs/` once synced. No changes to addon code, saved variables, or the `.toc`.
- Follow-up candidates: slash/UI parity (quirk 2), out-of-combat refresh (quirk 1).
