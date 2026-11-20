## 1. Settings registry and defaults

- [x] 1.1 Add registry entries `showGrey` (slash `grey`/`gray`), `palette` (choice `classic`/`colorblind`, labels Classic/Colorblind, slash `colors`), `slipSound`, `healerSound`, `healerFlash` (slash `slipsound`/`healersound`/`flash`), and an "Alerts" section between "Traffic lights" and "Show in" in `Settings.lua`. Verify: `/ttl foo` lists the new commands in the right groups.
- [x] 1.2 Add defaults to `TT.DEFAULTS` in `Core.lua` (grey on, palette classic, all three alerts on). Verify: `/reload` prints no "setting has no default" warning, and existing values are kept.

## 2. Classification: GREY and co-tank

- [x] 2.1 Add the `GREY` state and expose the state constants as `TT.States` in `Lights.lua`. Verify: the addon loads with no Lua errors.
- [x] 2.2 Add `IsCoTank(target)` (group member, not player or pet, role TANK or `GetPartyAssignment("MAINTANK")`, all via `Read`), and expose `IsGroupMember` as `L.IsGroupMember`. Verify: `/ttl why` on a mob targeting a party tank shows a co-tank reason.
- [x] 2.3 Update `StateFor` per the threat-classification delta: stranger targets → GREY on both paths, co-tank targets → GREY on both paths, fallback with no or unreadable target → no light. Verify: walk through each scenario in the delta spec with `/ttl why` (open-world stranger fight; party tank holding a mob).
- [x] 2.4 Apply the grey-light setting after classification (GREY → nil with "(grey off)" in the reason). Verify: `/ttl grey` makes stranger-fight lights disappear and come back.

## 3. Light visuals

- [x] 3.1 Replace `COLORS` with `PALETTES.classic`/`PALETTES.colorblind` (Okabe-Ito) and pick by `TankTrafficLightDB.palette` in `Paint`. Verify: `/ttl colors colorblind` during `/ttl demo` repaints immediately, with a blue bottom lamp for green.
- [ ] 3.2 Paint GREY as all lamps dimmed at frame alpha about 0.45, never pulsing, and restore alpha to 1 for other states and on recycle or detach. Verify: in demo, the grey step looks quieter, and the following red step is fully opaque.
- [x] 3.3 Make demo cycle red, yellow, green, grey. Verify: `/ttl demo` shows four steps.

## 4. Alerts module

- [x] 4.1 Create `Alerts.lua` (`TT.Alerts`) and add it to `TankTrafficLight.toc` after `Probe.lua` and before `Lights.lua`. Verify: the addon loads with no Lua errors.
- [x] 4.2 Implement healer identification (role HEALER; TANK/DAMAGER rule it out; NONE or unreadable falls back to class Priest/Druid/Paladin/Shaman; player and pet excluded). Verify: a temporary `/ttl why` line or the probe output shows the healer verdict for a party healer.
- [ ] 4.3 Implement the flash frame: edge glow plus center text, mouse disabled, hold then fade in about 2s, restarted by the next alert. Use the "<mob> -> <healer>" text only when both names are readable, otherwise "Mob on your healer!". Verify via `/ttl testalert` (task 5.2): the flash appears and fades, and clicks pass through to nameplates.
- [ ] 4.4 Implement sounds through `S.Call(PlaySound, SOUNDKIT.X, "Master")`, staying silent if the SOUNDKIT entry is missing. Pick two clearly different sounds by ear. Verify: both play from `/ttl testalert`.
- [ ] 4.5 Implement `OnState(unit, frame, old, new)`: the slipping trigger with a 2s global throttle; on-healer detection keyed by the target GUID, stored on the frame, with a per-mob 5s throttle (table keyed by mob GUID, wiped on `PLAYER_REGEN_ENABLED`) and a 1.5s global throttle; and the per-setting toggles. Verify: in a dungeon, letting a mob slip plays one ping, and a mob on the healer plays the urgent sound plus flash once, not on every tick.
- [x] 4.6 Call `TT.Alerts.OnState` from `L.Update` only when lights are running and demo is off, wrapped in `pcall` so an alert bug can't break the lights. Verify: `/ttl demo` produces no sounds, and a zone with lights disabled produces no alerts.

## 5. Options window and slash commands

- [ ] 5.1 In `Options.lua`, add the grey checkbox and colors cycle button to the Traffic lights box, and a new Alerts box with three checkboxes and a "Test alerts" button. Grow the panel, refresh the colors button text in `TT.RefreshOptions`. Verify: the window shows every control without overlap, and each control applies immediately.
- [x] 5.2 Add the `testalert` action to the `Core.lua` slash handler and list it under Alerts in `PrintHelp`. It runs both sounds and the flash with sample text, ignoring settings and throttles. Verify: `/ttl testalert` works out of combat with all alerts turned off.

## 6. Diagnostics

- [x] 6.1 Add target class (already present) and `GetPartyAssignment("MAINTANK", target)` to the probe output in `Probe.lua`. Verify: the `/ttl probe` report shows a main-tank line per nameplate.

## 7. Integration check

- [ ] 7.1 Run through it in game: a solo open-world pull (green/yellow/red as before, and stranger fights grey), a dungeon pull with an assigned healer (slip ping, healer alert plus flash), and with the colorblind palette on. Verify: no Lua errors (`/console scriptErrors 1`), and the trace log shows the expected GREY and co-tank reasons.
- [x] 7.2 Run `openspec validate tank-alerts-and-group-awareness --strict` and fix any reported issues.
