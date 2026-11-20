## 1. Settings registry and defaults

- [x] 1.1 Add the "Mob list" section (between "Traffic lights" and "Alerts") and the registry entries `mobList` (slash `list`), `listMinimized` (slash `listmin`), `listLocked` (slash `listlock`) and `listRows` (number 3 to 20, `integer = true`, slash `listrows`) to `Settings.lua`. Verify: `/ttl foo` lists the four commands under "Mob list".
- [x] 1.2 Add the `integer` check to `ParseNumber` and the "whole number" wording to the shared message. Verify: `/ttl listrows 4.5` and `/ttl listrows 25` are rejected with the current value, and `/ttl listrows 4` is accepted.
- [x] 1.3 Add the defaults to `TT.DEFAULTS` (list on, not minimized, locked, 8 rows). Make `TT.ResetAll()` clear `listPos` and re-apply the list position. Verify: `/reload` prints no "setting has no default" warning, and existing settings are kept.

## 2. Separate classification from painting

- [x] 2.1 Split `ShouldRun()` into `Allowed()` (zone and tank-only) plus the per-feature checks in `Lights.lua`. Classify when allowed and (lights or list). Paint only when the lights are on or in demo mode. Call the alerts hook only when the lights are on. Verify: with `/ttl lights` off and the list on, `/ttl why` still shows real states, no lights are drawn, and `/ttl testalert` aside, no alert fires in a pull.
- [x] 2.2 Expose the palette lookup as `TT.Lights.Colors()`. Verify: lights still repaint on `/ttl colors`.

## 3. Mob list core

- [x] 3.1 Create `MobList.lua` with `OnState(unit, guid, state)`, `Remove(unit)`, the `rows` table with an entry counter, and the dirty flag. Add it to the `.toc` after `Alerts.lua` and before `Lights.lua`. Verify: the addon loads with no Lua errors.
- [x] 3.2 Hook `L.Update` (via `pcall`) and `Detach` into `OnState`/`Remove`, including `Remove` when classification is skipped. Verify: in a pull, a mob's row appears and is removed when its plate goes away or it leaves combat.
- [x] 3.3 Build the frame: header with title, palette-colored `R/Y/G` counts and minimize button, a pooled set of rows (marker plus text), the "+N more" line, and truncation. Verify: a pull with mixed states shows rows sorted RED, YELLOW, GREEN, with RED rows showing `-> <target>` and YELLOW rows showing "(slipping)".
- [x] 3.4 Implement the coalesced redraw: sort by state rank, then entry order, apply the `listRows` cap, and read names with `Read()`, using `?` when unreadable. Verify: two RED mobs keep their order across ticks, and `/ttl listrows 3` in a 5-mob pull shows 3 rows and "+2 more".

## 4. Minimize, lock, move, visibility

- [x] 4.1 Minimize: the header button calls `Settings.Set("listMinimized", ...)`, and the rows hide or show. Verify: clicking it in combat collapses the list to the header with counts, and the options checkbox updates if the window is open.
- [x] 4.2 Lock and drag: the header drags only when unlocked, it is clamped to the screen, and `listPos` is saved on drag stop and applied on load. Verify: unlock, drag, `/reload`, and the list is in the same spot. When locked, dragging does nothing and rows never take clicks.
- [x] 4.3 Visibility rule: show when `mobList` and (rows, unlocked or demo). When unlocked with no rows, show a drag hint. Verify: hidden out of combat when locked, visible with the hint when unlocked, and hidden in a zone turned off in "Show in".

## 5. Options window

- [x] 5.1 Add the "Mob list" box (three checkboxes and a maximum rows field) under "Traffic lights" in the left column, and move the demo and reset buttons down. Verify: every new control works, and the window fits a 768px-tall UI at scale 1 (UI scale 1, 1366x768 or `/console uiscale`).
- [x] 5.2 Make `TT.RefreshOptions()` update the new controls. Verify: `/ttl listmin` and `/ttl listlock` update the open window immediately.

## 6. Demo and finish

- [x] 6.1 Add `TT.MobList.SetDemo(on)`, called from `L.SetDemo`, which draws the fixed sample rows. Verify: `/ttl demo` with no nameplates shows the sample rows and counts; stopping the demo out of combat hides the list; with the list off, demo shows no list.
- [ ] 6.2 Reset check: drag and minimize the list, then click "Reset all settings". Verify: the list returns to its default position, expanded and locked.
- [x] 6.3 Bump `## Version` in the `.toc` to 0.3.0. Verify: the addon list shows the new version.
- [ ] 6.4 Play check: a dungeon pull with the list on (lights on, then lights off), plus the off-screen check (turn away from a fighting mob and run `/ttl why`). Note the results in the change before archiving.
