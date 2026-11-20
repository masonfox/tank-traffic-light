## Context

All per-mob logic lives in `Lights.lua`. `L.StateFor(unit)` classifies a nameplate unit, and `L.Update(unit)` paints it and calls `Trace()` when the state changes. Updates run on threat and target events plus a 0.25s combat tick, so `L.Update` sees every state change within about 250ms. Every game read goes through `Safe.lua` (`S.Call`/`S.Public`), because this client can return secret values. Settings are a declarative registry in `Settings.lua`, which drives both the options window and `/ttl`, so new settings mostly mean new registry entries, defaults and window rows.

## Goals / Non-Goals

**Goals:**
- Keep classification in one place: GREY and co-tank logic go into `StateFor`, not into the painting or alert code.
- Alerts listen to state changes; they never classify mobs themselves.
- Every new read has an unreadable path that leads to "no alert" or a generic alert, never an error.

**Non-Goals:**
- No custom sound files and no sound picker: built-in game sounds only.
- No mob list, count badge, or taunt features (see the explore notes; those are later changes).
- No per-character profiles.
- No guessing about mobs without nameplates.

## Decisions

### GREY is a real fourth state, filtered at the end
`StateFor` returns `GREY` (with its reason) wherever it used to return `nil` for "on someone outside your group", and wherever it would have returned RED for a co-tank target. A wrapper applies the grey-light setting: if it's off, `GREY` becomes `nil` and the reason gains "(grey off)". Classification and the trace keep the real decision, and only the display changes.
*Alternative*: check the setting inside each branch. Rejected: four call sites for one rule.

### Co-tank check is a separate helper next to `IsGroupMember`
`IsCoTank(target)` = `IsGroupMember(target)`, not the player, not the pet, and either `UnitGroupRolesAssigned(target) == "TANK"` or `GetPartyAssignment("MAINTANK", target)`. Both are read with `Read()`. It runs only after the group-member check passes.
*Alternative*: role only. Rejected: classic raids often set main tanks through raid assignment rather than roles.

### Grey look: dimmed lamps and lower alpha
A GREY light paints all three lamps at `DIM` and sets the frame alpha to about 0.45. Leaving GREY (or painting any other state) restores alpha to 1. The pulse never runs for GREY. This needs no new textures and reads clearly as "a light, but switched off".

### Palettes are a table of color tables
`PALETTES = { classic = {...}, colorblind = {...} }`, chosen by `TankTrafficLightDB.palette` in `Paint()`. Colorblind uses Okabe-Ito: vermilion (0.84, 0.37, 0.00), yellow (0.94, 0.89, 0.26), blue (0.00, 0.45, 0.70), slightly brightened if needed for contrast against the dark housing. The setting already triggers `UpdateAll()` when changed. `Paint` must repaint even when the state hasn't changed, which it already does, because `Update` always calls `Paint`.

### Alerts live in a new `Alerts.lua`, fed by one hook
`L.Update` already compares the old and new state. After classification, outside demo mode, it calls `TT.Alerts.OnState(unit, frame, oldState, newState)`. `Alerts.lua` owns:
- **Slipping**: `newState == YELLOW and oldState ~= YELLOW`, then the 2s global throttle, then play.
- **On-healer**: if `newState == RED`, read `unit.."target"`. If it's a healer, build a key from the target's GUID (or `"?"` if unreadable). If the frame's last on-healer key differs from this one, that's a new event: apply the per-mob 5s throttle (stored on the frame, keyed by mob GUID) and the 1.5s global throttle, then play the sound and show the flash. Store the key on the frame. Clear it when the state isn't RED or the target isn't a healer.
- The per-mob throttle is keyed by mob GUID in a small table, wiped on `PLAYER_REGEN_ENABLED`. This avoids losing the throttle when a nameplate frame is recycled.

Load order in the `.toc`: `Alerts.lua` comes before `Lights.lua`, so the hook target exists. `Lights.lua` shares the state constants with it through `TT.States`.
*Alternative*: hook `Trace()`. Rejected: `Trace` only fires on light-state changes, but a RED mob switching from a mage to the healer doesn't change the light.

### Healer identification in `Alerts.lua`
Use `IsGroupMember` (exposed as `L.IsGroupMember`), excluding the player and pet. Role `HEALER` means a healer. Role `TANK` or `DAMAGER` means not a healer. `NONE` or unreadable falls back to `UnitClass` (the second return, the class token) being in `{PRIEST, DRUID, PALADIN, SHAMAN}`.

### Sounds
`PlaySound(SOUNDKIT.<NAME>, "Master")` through `S.Call`, so they play even when the player has turned SFX down. If a SOUNDKIT name is missing on this client, the alert is silent. Candidates: slipping = a short, mild ping such as `SOUNDKIT.IG_PLAYER_INVITE`; healer = `SOUNDKIT.RAID_WARNING`. The final choice is made in game during implementation, and is an open question below.

### Flash frame
A `Frame` on `UIParent` at `FULLSCREEN_DIALOG` strata with `EnableMouse(false)`. It holds four edge gradient textures (red to transparent, about 80px deep) and a large outlined `FontString` at about 30% from the top. An `AnimationGroup` holds at full alpha for 0.6s, then fades to 0 over 1.2s, and the next alert restarts it. Names come from `UnitName` via `Read()`, and if either is unreadable the generic text is used. Strings are never built from secret values. The frame is non-secure, so showing it in combat is allowed.

### Settings
New registry entries: `showGrey` (toggle, slash `grey`/`gray`), `palette` (choice `classic`/`colorblind`, slash `colors`), `slipSound`, `healerSound`, `healerFlash` (toggles, slash `slipsound`/`healersound`/`flash`). A new section "Alerts" goes between "Traffic lights" and "Show in". `testalert` is an action in `Core.lua`'s slash handler, like `demo`, and the help output lists it under Alerts. Choice entries already work through `Settings.Cycle`, so the colors button reuses the placement button's pattern. The panel grows by about 150px (the Traffic lights box gains two rows, plus the new Alerts box).

### Configurable grey opacity and alert sounds (added after first implementation)
- `greyAlpha`: a number entry (0.1 to 1, default 0.45, slash `greyalpha`/`grayalpha`). It replaces the `GREY_ALPHA` constant in `Paint`, and the existing `Settings.Set` → `UpdateAll` repaints it.
- `slipSoundName` / `healerSoundName`: choice entries over one shared list `SOUNDS = { ping = IG_PLAYER_INVITE, whisper = TELL_MESSAGE, bell = ALARM_CLOCK_WARNING_2, alarm = ALARM_CLOCK_WARNING_3, readycheck = READY_CHECK, raidwarning = RAID_WARNING }`, with labels Ping, Whisper, Bell, Alarm, Ready check, Raid warning. The ids are looked up by SOUNDKIT name at play time, and a missing one means silence. This replaces the hard-coded fallback lists (a choice entry has no "fallback" concept). The cycle button and `Settings.Cycle` already exist for choices.
- **Preview**: choice entries get an optional `onChange` hook in the registry, called from `Settings.Set` after a successful change. The two sound entries use it to play the new sound. This keeps the window and slash commands in parity without special cases.
- *Alternative*: LibSharedMedia sounds. Rejected for now (the user chose the built-in list), but the `SOUNDS` table is where it would plug in.

## Risks / Trade-offs

- [Class guess flags DPS priests, shadow priests, ret paladins and others as healers in role-less groups] → This was an accepted trade-off. Players can turn off the healer alerts, and an assigned role always overrides the class.
- [Main-tank assignment or role may be secret in combat on this client] → Fails toward RED, which is today's behavior, so nothing gets worse. `/ttl probe` should also report `GetPartyAssignment` for the target so this can be checked.
- [Target switch between ticks: a mob briefly targets the healer for less than 250ms] → It may be missed. That's acceptable, since such brief swaps are usually spell targets, not aggro.
- [Open world gets busier: every mob anyone is fighting shows GREY] → The reduced alpha keeps them quiet, and the setting turns them off.
- [Sound spam during big pulls] → Global throttles (2s slipping, 1.5s healer) plus the per-mob 5s throttle.

## Migration Plan

New settings get their defaults through the existing `ApplyDefaults()`, so no migration code is needed. Rollback means reinstalling the previous version. Unknown saved keys are harmless.

## Open Questions

- Exact SOUNDKIT ids for the two sounds: pick by ear in game, and make sure the two are clearly different.
- The exact grey alpha (0.4 to 0.5) and colorblind lamp brightness: tune visually with `/ttl demo`.
