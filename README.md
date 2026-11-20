# Tank Traffic Light

A **WoW Forever** addon that puts a small traffic light on enemy nameplates, so a tank can see at a glance which mobs are on them, which are slipping, and which are loose.

| Light | Meaning |
|-------|---------|
| Green | You are securely tanking it |
| Yellow (pulsing) | You are tanking it, but about to lose aggro |
| Red | It is attacking someone else in your group |
| Grey (dimmed) | Not your problem: it is on a co-tank or on someone outside your group |

## Features

- **Nameplate lights** to the left, right or top of the health bar. Works with Blizzard nameplates and Plater.
- **Mob list**: a movable panel listing every classified mob, red first, with who each loose mob is attacking and red/yellow/green counts in the header. It can be minimized and shows only in combat.
- **Alerts**: a sound when aggro starts slipping, plus a sound and screen flash when a mob attacks a healer.
- **Filters**: tank role only, and per zone type (open world, dungeons, raids, PvP).
- **Colorblind palette** (Okabe-Ito vermilion, yellow and blue).

## Install

Built for the WoW Forever client only. Copy this folder into `World of Warcraft/_forever_/Interface/AddOns/` as `TankTrafficLight`, then restart the game or `/reload`.

## Usage

`/ttl` (or `/tanktrafficlight`) opens the options window. It is also under Options > AddOns > Tank Traffic Light. Every option has a matching slash command; `/ttl help` lists them all, grouped like the window.

Common commands:

| Command | Does |
|---------|------|
| `/ttl demo` | Cycle every light through all colors and fill the mob list with sample rows, to preview and position things out of combat |
| `/ttl lights` / `/ttl list` | Toggle the nameplate lights / the mob list |
| `/ttl listlock` | Unlock the mob list to drag it, then lock it again |
| `/ttl side [left\|right\|top]` | Move the lights |
| `/ttl colors [classic\|colorblind]` | Switch palettes |
| `/ttl testalert` | Play both alerts |
| `/ttl reset` | Restore all defaults |

Settings are saved per account.

## Troubleshooting

- `/ttl why` prints what every visible light decided and why.
- `/ttl trace` prints every light change to chat (changes are always saved to the trace log).
- `/ttl probe` records what the game APIs the addon relies on are returning; `/ttl auto` does this 3 seconds into every pull.
- `/ttl clear` empties the probe and trace logs.

Logs live in the `TankTrafficLightDB` saved variable (`WTF/Account/<account>/SavedVariables/TankTrafficLight.lua`).

## Development

Behavior is specified with [OpenSpec](https://github.com/Fission-AI/OpenSpec) in `openspec/specs/`, with past changes under `openspec/changes/archive/`.
