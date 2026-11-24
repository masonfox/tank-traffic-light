# Design

## Context

`MobList.lua` is self-contained. Other files reach it in a few places:

- `Lights.lua`: `ListRemove(unit)` (from `Detach` and `L.Update`), `TT.MobList.OnState` (from `L.Update`), `ShouldClassify()` returning true when `lights OR mobList`, and `list=` in the `L.Explain` status line.
- `Settings.lua`: the "Mob list" entry in `Sections`, four entries (`mobList`, `listMinimized`, `listLocked`, `listRows`), and `TT.MobList.Refresh()` in `Settings.Set`.
- `Core.lua`: four entries in `TT.DEFAULTS`, `listPos = nil` plus `ApplyPosition()` in `TT.ResetAll`, `Refresh()` in `TT.ResetSettings`, and `ApplyPosition()`/`Refresh()` in the `ADDON_LOADED` handler. `MigrateSettings()` already clears the old `topOffset`.
- `Options.lua`: the Mob list box at `BOXES_TOP - 314` (124 tall), and the panel's OnShow/OnHide hooks that only refresh the list.
- `TankTrafficLight.toc`: loads `MobList.lua`.

Slash commands and help text come from the settings registry, so they drop out once the registry entries are gone.

## Goals / Non-Goals

**Goals:**
- No reference to the mob list is left in code, the toc or the README.
- Old saved variables lose the list's keys on the first load after upgrading.

**Non-Goals:**
- Adding the loose mob's target name to the light or any other surface.
- Reworking the options window beyond closing the gap the list leaves.
- Removing integer support from numeric settings parsing (`entry.integer`). It costs nothing and a future setting may use it.

## Decisions

### 1. Delete, don't hide
Delete `MobList.lua` and every call site instead of leaving the panel disabled behind a flag. Every remaining call site already guards with `if TT.MobList and ...` or calls it directly, so a stub would only keep dead code alive. Alternative considered: default `mobList` to off. Rejected because the point is less code and fewer settings, not a hidden feature.

### 2. Classification follows the lights only
`ShouldClassify()` becomes `TankTrafficLightDB.lights and Allowed()`. With the lights off, `L.Update` takes its existing not-classified path: it clears `alertHealerKey`, leaves `state` nil and hides the light. Alerts were already gated on the lights. But `state` is cleared while they are off, so turning them back on treats a mob that is still YELLOW as newly slipping, and the slipping sound can play once (throttled). This is accepted: it is the right moment to warn. The `classified` and `lightsOn` locals in `L.Update` collapse to one condition.

### 3. Clear the old keys in `MigrateSettings`
Set `mobList`, `listMinimized`, `listLocked`, `listRows` and `listPos` to nil in `MigrateSettings()`, the same pattern as `topOffset`. It runs on every load and is idempotent, so no version check is needed. Alternative considered: leave stale keys. Rejected because `/ttl reset` would never remove them, and the saved file would carry dead settings forever.

### 4. Shrink the options window, keep the columns
Today the left column is the tallest: the list box ends at y = -650 and the window is 700 tall. Without it, the right column ends lowest (Diagnostics at -586). Reduce `PANEL_H` by the same 64px (700 to 636) so the margin under the boxes and the reset button stays the same. Keep the two-column layout and the box positions as they are. Alternative considered: move Diagnostics under Traffic lights to balance the columns. Rejected because it saves no height (it would end near -598) and moves a box players already know.

### 5. Version bump
Bump the toc `## Version` from 0.3.0 to 0.4.0. Settings and commands are removed, which is breaking for players who used the list. The addon is still pre-1.0, so the minor version marks it.

## Risks / Trade-offs

- [A player relied on the "-> <target>" text to see who a loose mob was on] → Accepted. The red light still flags the mob, and the healer alert covers the worst case. Out of scope here (see Non-Goals).
- [Muscle memory for `/ttl list` and the other list commands] → They print the full command list, the same handling `/ttl demo` already gets, and the README drops them.
- [A leftover `TT.MobList` reference errors at load or on a setting change] → Task check: a grep for `MobList` and `mobList`/`list[A-Z]` across `*.lua` and the toc must return only the migration lines.

## Migration Plan

Nothing to do by hand. The first load after upgrading clears the list's keys. Rolling back to 0.3.x restores the list at its defaults (on, expanded, locked, 8 rows, default position), because `ApplyDefaults` refills missing keys.
