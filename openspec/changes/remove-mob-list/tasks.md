# Tasks

## 1. Lights stop feeding the list (Lights.lua)

- [x] 1.1 Remove `ListRemove` and its calls in `Detach` and `L.Update`, and the `TT.MobList.OnState` call; verify `grep -n MobList Lights.lua` returns nothing
- [x] 1.2 Make `ShouldClassify()` return `TankTrafficLightDB.lights and Allowed()` (design Decision 2), and fold the `classified`/`lightsOn` split in `L.Update` into one condition; verify by reading that with lights off the light hides, `state` stays nil, `alertHealerKey` clears and `Alerts.OnState` is not called, and with lights on behavior is unchanged
- [x] 1.3 Drop `list=` from the `L.Explain` status line; verify `grep -n mobList Lights.lua` returns nothing and the line still prints lights, tankOnly, allowed and classify

## 2. Settings, defaults and migration (Settings.lua, Core.lua)

- [x] 2.1 Remove "Mob list" from `Settings.Sections`, the `mobList`, `listMinimized`, `listLocked` and `listRows` entries, and the `TT.MobList.Refresh()` call in `Settings.Set`; verify `grep -n -i "list" Settings.lua` matches only the sound lists, and `/ttl help` no longer prints a Mob list line (specs/settings "Slash commands")
- [x] 2.2 Remove the four list defaults from `TT.DEFAULTS`, the `listPos` reset and `ApplyPosition()` from `TT.ResetAll`, `Refresh()` from `TT.ResetSettings`, and `ApplyPosition()`/`Refresh()` from the `ADDON_LOADED` handler; verify `grep -n MobList Core.lua` returns nothing
- [x] 2.3 In `MigrateSettings()`, set `mobList`, `listMinimized`, `listLocked`, `listRows` and `listPos` to nil (design Decision 3); verify by reading it against specs/settings scenario "Upgrading to the mob list", and that it still runs before `ApplyDefaults`

## 3. Options window (Options.lua)

- [x] 3.1 Remove the Mob list box, and the panel OnShow/OnHide hooks that only refresh the list; verify `grep -n -i "MobList\|Mob list\|listRows" Options.lua` returns nothing
- [x] 3.2 Reduce `PANEL_H` from 700 to 636 and update the layout comment (left column is Traffic lights only); verify by arithmetic that the Diagnostics box bottom (`BOXES_TOP - 302 - 72` = -586) still keeps the same 50px above the window bottom that the list box had, so the reset button doesn't overlap it

## 4. Delete the module, docs and version (MobList.lua, toc, README.md)

- [x] 4.1 Delete `MobList.lua` and remove its line from `TankTrafficLight.toc`; verify the toc lists only existing files
- [x] 4.2 Bump `## Version` in the toc from 0.3.0 to 0.4.0
- [x] 4.3 Remove the Mob list feature bullet and the `/ttl list` and `/ttl listlock` command rows from README.md, so the lights row reads `/ttl lights` only, and add a note that the mob list was removed in 0.4.0 and its commands now print the command list; verify `grep -n -i "mob list\|listlock" README.md` only matches that note

## 5. Integration check

- [x] 5.1 Cross-file check: `grep -rn "MobList\|mobList\|listMinimized\|listLocked\|listRows\|listPos" *.lua *.toc` returns only the `MigrateSettings` lines in Core.lua, and every `TT.*` function still called from Lights.lua, Settings.lua, Core.lua and Options.lua is defined
- [ ] 5.2 Manual in-game check (user): `/reload` with an old saved variables file that has list settings and loads with no Lua errors; `/ttl` opens the shorter window with no Mob list box and nothing overlapping; `/ttl list` prints the command list; pull a mob with lights on (light shows, alerts fire) and with `/ttl lights` off (no light, no alert); with the slipping sound on and no slipping sound in the last 2s, toggle `/ttl lights` off and on while one mob is YELLOW; hear exactly one slipping sound, and no repeat while it stays YELLOW; after logout, `TankTrafficLight.lua` in SavedVariables has no `mobList`/`list*` keys

## Workflow follow-up

- Archive the change after the in-game check passes, which retires the `mob-list` spec.
