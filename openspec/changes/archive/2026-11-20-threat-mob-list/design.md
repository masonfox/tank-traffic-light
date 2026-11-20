## Context

Classification and painting both live in `L.Update(unit)` in `Lights.lua`. It attaches a light frame to the plate, and if `ShouldRun()` passes (lights toggle, zone filter, tank-only), it calls `L.StateFor`, traces changes, calls the `TT.Alerts.OnState` hook, and paints. The last state is stored on the light frame (`f.state`). `Detach(unit)` runs on `NAME_PLATE_UNIT_REMOVED` and clears it. Updates run on threat and target events plus a 0.25s combat tick. Every game read goes through `Safe.lua`. Settings are a declarative registry in `Settings.lua` that drives both the options window (`Options.lua`, two columns to fit a 768px UI) and `/ttl`.

The saved trace log shows that mob names and their targets' names are readable in combat on this client, so rows can carry names.

## Goals / Non-Goals

**Goals:**
- One classification feeds lights, alerts and the list. The list never classifies mobs itself.
- The list can run with the lights off without changing when alerts fire.
- A bug in the list can never break the lights (same `pcall` protection as the alerts hook).

**Non-Goals:**
- No secure or clickable rows, and no click-to-target.
- No mob sources other than nameplates (group members' targets, boss units). That can be a later change.
- No health bars, cast bars or threat percentages in rows.
- No per-character list position.

## Decisions

### Split "classify" from "paint" in `L.Update`
`ShouldRun()` becomes two checks that share the zone and tank-only logic:
- `Allowed()`: zone filter and tank-only (today's `ShouldRun` without the lights toggle).
- Classify when `Allowed()` and (`lights` or `mobList`).
- Paint the light only when `lights` is on (or demo). Otherwise the light frame stays hidden.
- Call the alerts hook only when `lights` is on and the mob is classified, as today, so the alerts spec is unchanged.
- Trace still records every state change while classifying, so lights-off/list-on play still leaves a trace.

`f.state` stays on the light frame, which is created whether or not it is shown. Lifecycle and recycling handling don't change.
*Alternative*: a separate classification loop in `MobList.lua`. Rejected: it would run classification twice per tick and could disagree with the lights.

### List hook mirrors the alerts hook
After classification, `L.Update` calls `pcall(TT.MobList.OnState, unit, guid, state)`. `Detach(unit)` calls `TT.MobList.Remove(unit)`. When classification is skipped (gated off or both features off), `L.Update` calls `Remove(unit)` too, so a gated-off zone empties the list.

`MobList.lua` keeps `rows[unit] = { guid, state, since }`. `since` is a counter that increases each time a mob enters a state, so sorting by (state rank, since) keeps the order stable within a state. A GUID change for the same unit token counts as a new mob. Names are not cached: they are read with `Read(UnitName, ...)` at redraw time, because a RED mob's target changes.

### Coalesced redraw
`OnState` and `Remove` only set a `dirty` flag. A small `OnUpdate` on the list frame redraws when the flag is set, so there is at most one redraw per frame however many plates update. Redraw: collect rows, drop GREY and nil, sort, count per state, then fill a pool of reused row widgets (`FontString`s plus a marker texture) up to `listRows`, and show "+N more" if there are more. The palette comes from the same `PALETTES` table, exposed as `TT.Lights.Colors()`.

### Frame
A plain `Frame` on `UIParent`, `MEDIUM` strata, about 200px wide, made of:
- Header (about 18px): title "Threat", the counts `R2 Y1 G3` built from palette-colored escape codes, and a small `[-]`/`[+]` button. The button calls `Settings.Set("listMinimized", ...)`, so the window and chat stay in parity.
- Rows (about 14px each) under the header, hidden when minimized.

Mouse: the row area never takes the mouse. The header takes the mouse for dragging only when unlocked. The minimize button always takes it. `SetMovable`, `SetClampedToScreen(true)` and `RegisterForDrag("LeftButton")` on the header. On drag stop, save `TankTrafficLightDB.listPos = { point, relPoint, x, y }`. These are plain non-secure frames, so showing, hiding, resizing and minimizing in combat are all allowed.

### Visibility
`shown = mobList and (rowCount > 0 or not listLocked or demo or optionsOpen)`. When unlocked with no rows, show the header and a "Drag to move" hint row. Recomputed on every redraw, on settings changes, and when the options window opens or closes. Keeping the list up while the options window is open means checking "Lock the mob list" out of combat doesn't make the list vanish mid-edit.

### Position is not a registry setting
`listPos` is not in `TT.DEFAULTS`, because it has no window control and no slash command. `TT.ResetAll()` sets it to `nil` and calls `TT.MobList.ApplyPosition()`, which anchors to the default (`LEFT`, `UIParent`, `LEFT`, 40, 120) when there is no saved position.

### Settings
New registry entries in a new "Mob list" section, between "Traffic lights" and "Alerts":
- `mobList`: toggle, "Show the mob list", slash `list`
- `listMinimized`: toggle, "Minimize the mob list", slash `listmin`
- `listLocked`: toggle, "Lock the mob list", slash `listlock`
- `listRows`: number, "Maximum rows", slash `listrows`, 3 to 20, `integer = true`

`ParseNumber` gains an `integer` check (`value % 1 == 0`), and the shared message says "a whole number" for integer entries. `Settings.Set` already calls `TT.Lights.UpdateAll()`, which reclassifies and marks the list dirty. It also calls `TT.MobList.Refresh()` for the lock, minimize and row settings, which don't change classification.

### Options window layout
The left column ends near y = -328 after "Traffic lights". A "Mob list" box of about 124px (three checkboxes and one field row) fits under it, ending near -462. That collides with the demo and reset buttons at -462, so those buttons move down about 30px. The panel then needs about 30px more height (still under 768). The exact offsets will be tuned in game.

### Demo
`TT.MobList.SetDemo(on)` is called from `L.SetDemo`. In demo mode the list ignores `rows` and draws a fixed sample set, for example "Defias Trapper -> Heidi" (RED), "Defias Smuggler -> Loki" (RED), "Goretusk (slipping)" (YELLOW), and three GREEN rows. Nameplate lights keep their own cycling.

### Load order
`MobList.lua` loads after `Alerts.lua` and before `Lights.lua`, so the hook target exists when `Lights.lua` runs. It reads `TT.States`, which `Lights.lua` defines, only at call time, never at load time.

## Risks / Trade-offs

- [The list adds no coverage for mobs whose nameplate is gone, such as behind the camera, if the client culls those plates] → This is accepted for this change. A quick in-game check (turn away from a fighting mob, run `/ttl why`) shows how much coverage the list gains. Other unit sources are a separate change.
- [Turning the lights off no longer stops classification if the list is on] → This is intended. Turning both off restores today's "nothing runs" behavior.
- [A large pull makes the list long] → The row cap and "+N more" limit it, and RED rows always sort into view.
- [Panel overlaps other UI at the default position] → It is movable, and Reset puts it back.
- [Names may become secret in some content] → Unreadable names show `?`. The list still gives states and counts.

## Migration Plan

New settings get their defaults through the existing `ApplyDefaults()`. With no `listPos`, the list uses the default anchor. Rollback means reinstalling the previous version. Unknown saved keys are harmless.

## Open Questions

- Exact default position, width and row height: tune in game against default and common UI layouts.
- Header title wording ("Threat" vs "Mobs"): cosmetic, decide in game.
