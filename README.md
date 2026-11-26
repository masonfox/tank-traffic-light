# Tank Traffic Light

A **WoW Forever** addon that puts a small traffic light on enemy nameplates, so a tank can see at a glance which mobs are on them, which are slipping, and which are loose.

| Light | Meaning |
|-------|---------|
| Green | You are securely tanking it |
| Yellow (pulsing) | You are tanking it, but about to lose aggro |
| Red | It is attacking someone else in your group |
| Grey (dimmed) | Not your problem: it is on a co-tank or on someone outside your group |

## Features

- **Nameplate lights** to the left, right, top or bottom of the health bar, with an adjustable gap. Top and bottom lights can be aligned to the left, middle or right of the bar. Works with Blizzard nameplates and Plater.
- **Live preview**: the options window shows a sample nameplate with buffs, debuffs and a cast bar, and a sample light that follows every placement, size, color and opacity change as you make it.
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
| `/ttl lights` | Toggle the nameplate lights |
| `/ttl side [left\|right\|top\|bottom]` | Move the lights; with no argument, cycle through the placements |
| `/ttl align [left\|middle\|right]` | Align top and bottom lights along the health bar (no effect on left or right placement) |
| `/ttl gap <0-60>` (or `height`) | Set the distance between the light and the health bar |
| `/ttl colors [classic\|colorblind]` | Switch palettes |
| `/ttl testalert` | Play both alerts |
| `/ttl reset` | Restore all defaults |

The mob list was removed in 0.4.0; `/ttl list`, `listmin`, `listlock` and `listrows` now print the command list.

The preview at the top of the options window replaces the old `/ttl demo` command. Settings are saved per account; a top height saved by an earlier version carries over as the gap.

## Troubleshooting

- `/ttl why` prints what every visible light decided and why.
- `/ttl trace` prints every light change to chat (changes are always saved to the trace log).
- `/ttl probe` records what the game APIs the addon relies on are returning; `/ttl auto` does this 3 seconds into every pull.
- `/ttl clear` empties the probe and trace logs.

Logs live in the `TankTrafficLightDB` saved variable (`WTF/Account/<account>/SavedVariables/TankTrafficLight.lua`).

## Development

Behavior is specified with [OpenSpec](https://github.com/Fission-AI/OpenSpec) in `openspec/specs/`, with past changes under `openspec/changes/archive/`.

CI (`.github/workflows/ci.yml`) runs on every push, on pull requests, and on demand. It has two jobs:

- **lint**: `luacheck .` (config in `.luacheckrc`), `lua scripts/check-toc.lua` (every root `.lua` file is listed in the TOC files and every listed file exists), and `openspec validate --all`.
- **test**: the [busted](https://lunarmodules.github.io/busted/) suite on Lua 5.1 with line coverage, then two reports in the job summary: line coverage per addon file, and spec coverage (which scenarios have a test).

### Tests

Test files live in `spec/` and end in `_spec.lua` (config in `.busted`). They run outside the game against a fake world in `spec/support/`:

- `spec/support/wow.lua` stands in for the game API. Units, threat, group roles, the clock, sounds and chat output are all plain tables a test sets up and reads back. `C_Timer.After` callbacks wait in `world.pending` until `world.advance(seconds)` moves the fake clock past their due time. A global the fake world doesn't provide is an error, so a misspelled API name fails the test. The read is also recorded in `world.missing`, and `spec/support/strict_globals.lua` (a busted helper set in `.busted`) fails any test that leaves an entry there, so a read the addon swallows with `pcall` still fails. A test that reads an unknown global on purpose empties `world.missing` itself. The helper clears its world list after each test, so a world built once in `setup()` and reused across tests is checked after the first test only and missed after that. Build every fake world per test (in `before_each` or inside the test), including one passed prebuilt to `addon.load`.
- `spec/support/addon.lua` loads the addon files in TOC order into a fresh environment per test and fires `ADDON_LOADED` with the saved variables the test passes in.

`spec/harness_spec.lua` shows how to use both. Load a fresh addon in `before_each` so no state leaks between tests.

Name tests after the spec scenario they cover: the outer `describe` is the capability's directory name under `openspec/specs/`, an optional middle `describe` is the requirement, and the `it` is the exact scenario title.

```lua
describe("threat-classification", function()
    describe("Readable threat status drives the light", function()
        it("Mob is on a co-tank", function() ... end)
    end)
end)
```

Tests that cover no scenario go under `describe("unit: ...")`. `scripts/spec-coverage.lua` matches tests to scenarios by capability and title (the requirement name is ignored) and reports, per capability, covered versus total scenarios, the scenarios with no test, and tests whose name matches no scenario, which usually means a scenario was renamed. Neither report fails the run.

To run everything locally with Lua 5.1, busted, luacov, luacheck and the OpenSpec CLI installed, from a Unix shell (Linux, macOS or WSL; the commands and scripts use `ls`, `find`, `test` and `/dev/null`, so they fail with native Windows Lua):

```sh
luacheck .
luac -p $(git ls-files '*.lua')   # Lua 5.1 parser; rejects goto and other 5.2+ syntax
lua scripts/check-toc.lua
openspec validate --all
busted                         # or: busted --coverage && luacov
lua scripts/spec-coverage.lua  # prints the spec coverage report
```

#### With Docker (any OS, including Windows)

`scripts/Dockerfile.test` builds a Lua 5.1 image with the same luacheck, busted and luacov versions as CI. From the repo root (in a POSIX shell such as Git Bash or WSL; on Windows Git Bash, prefix `docker run` with `MSYS_NO_PATHCONV=1` and mount `"$(pwd -W):/repo"`):

```sh
docker build -t ttl-test -f scripts/Dockerfile.test scripts
docker run --rm -v "$PWD:/repo" -w /repo ttl-test sh -c 'luacheck . && luac -p $(git ls-files "*.lua") && lua scripts/check-toc.lua && busted && lua scripts/spec-coverage.lua'
```

The image has no OpenSpec CLI, so run `openspec validate --all` on the host.
