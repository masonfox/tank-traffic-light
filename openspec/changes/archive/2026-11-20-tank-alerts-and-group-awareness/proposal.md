## Why

The lights are only useful while the tank is looking at them, and they can be wrong. In raids, every mob attacking the other tank lights RED, so lights in raids are mostly noise. In the open world, mobs fighting strangers get no light at all, which looks like the addon broke. And a tank can't watch every nameplate, so the most dangerous moments ("aggro is slipping", "a mob is on the healer") need to be heard and seen without looking for them.

## What Changes

- **Co-tank awareness**: a mob attacking another tank in the player's group (assigned TANK role, or raid main-tank assignment) is no longer RED. It gets the grey "not yours" light.
- **Grey "not yours" light**: a new fourth light state, GREY, drawn as the housing with all three lamps dark. It's used for mobs in combat with someone outside the group and for mobs on a co-tank. A new setting turns GREY off, which brings back the old behavior of showing no light for these mobs.
- **Colorblind palette**: a new color setting with "Classic" (red/yellow/green) and "Colorblind" (vermilion/yellow/blue, Okabe-Ito). Lamp position still shows the state in both palettes.
- **Sound alerts**: one sound when a light turns YELLOW, and a different, more urgent sound when a loose mob starts attacking a healer. Each can be turned on or off, and both are throttled so they never spam.
- **Mob-on-healer flash**: when a loose mob starts attacking a healer, a red screen-edge flash plus center-screen text ("Skeleton -> Priest" when names can be read, otherwise a generic warning).
- **Healer identification**: the assigned HEALER role first. With no role assigned, the class decides (Priest, Druid, Paladin, Shaman).
- **Alert test**: a "Test alerts" button and `/ttl testalert` play both sounds and show the flash.
- **Demo**: demo mode also cycles through GREY.

## Capabilities

### New Capabilities
- `alerts`: Sound alerts for slipping aggro and mobs on healers, the mob-on-healer flash, healer identification, throttling, and the alert test action.

### Modified Capabilities
- `threat-classification`: Adds the GREY state, replacing "no light" for mobs fighting strangers. Adds co-tank detection so mobs on another group tank are GREY, not RED. Adds the setting that turns GREY off.
- `nameplate-lights`: Adds the grey light's look and selectable color palettes for the lit lamps.
- `settings`: New settings, defaults, options window controls (a new "Alerts" section, a grey-light toggle, a palette choice, the test button), and the matching slash commands.
- `diagnostics`: Demo mode cycles through GREY as well and never triggers alerts. The probe also reports the target's class and main-tank assignment, so co-tank detection can be checked.

## Impact

- `Lights.lua`: classification (GREY, co-tank), painting (grey look, palettes), and a hook on state changes for alerts.
- New `Alerts.lua` (added to `TankTrafficLight.toc`): sounds, flash frame, healer detection, throttling.
- `Settings.lua`, `Core.lua` (defaults, `testalert` command), `Options.lua` (new controls; the window gets taller).
- Uses `PlaySound`/`SOUNDKIT`, `GetPartyAssignment`, `UnitGroupRolesAssigned`, and `UnitClass` on mob targets, all read through the existing safe-access layer. If any of these can't be read, the feature falls back to doing nothing; it never errors.
- No breaking changes. Existing saved settings keep their values, and new settings get their defaults.
