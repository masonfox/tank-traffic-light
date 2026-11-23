# Proposal

## Why

The nameplate lights are the addon's real value: they put the answer right on the mob the tank is already watching. The mob list repeats the same information in a separate panel the tank has to look away to read, so in practice it doesn't help. It also costs a fifth of the options window, four settings, four slash commands, and a special case that keeps classification running with the lights turned off. Removing it makes the addon smaller and the settings easier to follow.

## What Changes

- **BREAKING**: Remove the mob list: the panel, its header counts, minimize button, drag and lock, and row cap.
- **BREAKING**: Remove the list's settings (`mobList`, `listMinimized`, `listLocked`, `listRows`) and its saved position, the "Mob list" box in the options window, and the `/ttl list`, `listmin`, `listlock` and `listrows` commands. Those commands fall through to the command list like any unknown command.
- On load, clear the list's settings and position from saved settings, so old installs don't keep stale keys.
- The lights setting goes back to switching off classification entirely. It no longer keeps running for the list. Alerts already follow the lights, so they behave the same as before.
- The options window loses the Mob list box and gets shorter.
- Lost on purpose: the list's "-> <target>" text, which named who a loose mob was attacking. The red light still shows that a mob is loose, and the healer alert still covers the most urgent case.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `mob-list`: every requirement is removed and the capability is retired.
- `settings`: the mob list is dropped from defaults, reset, the options window, slash commands and numeric-setting ranges. Loading clears the list's saved keys.
- `light-preview`: the sample light no longer mentions mob list rows.

## Impact

- `MobList.lua`: deleted, and removed from `TankTrafficLight.toc`.
- `Lights.lua`: drop the list's `OnState`/`Remove` calls, drop `mobList` from the classify check, and drop `list=` from `/ttl why`.
- `Settings.lua`: drop the "Mob list" section, its four entries, and the list refresh in `Set`.
- `Core.lua`: drop the list's defaults, position reset and load-time calls, and clear the old keys in the settings migration.
- `Options.lua`: drop the Mob list box and the show/hide list refresh hooks, and shrink the window.
- `README.md`: drop the mob list feature and command rows.
- Version bump for the breaking change.
