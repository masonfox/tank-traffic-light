# Design

## Context

See proposal.md for why. Constraints that shape the approach:

- The addon is eight Lua files loaded in TOC order. Each starts with `local _, TT = ...` and shares state only through the `TT` table and a few globals (`TankTrafficLightDB`, `SLASH_*`, `SlashCmdList`).
- The client runs Lua 5.1. CI must use Lua 5.1, not 5.3 or 5.4, or 5.2+ syntax would pass in tests and break in game.
- The logic that matters is reachable through public functions: `TT.Lights.StateFor`, `IsGroupMember`, `IsCoTank`, `TT.Alerts.IsHealer` and `OnState`, `TT.Settings.Set` and `Cycle`, `TT.Safe.*`, and the slash handler in `SlashCmdList.TANKTRAFFICLIGHT`. `Classify` is local, but `StateFor` wraps it.
- Several files create frames and register events while loading (`Lights.lua`, `Alerts.lua`, `Core.lua`), so even logic tests need a `CreateFrame` that accepts calls.
- Every API read goes through `TT.Safe.Call`, which turns a missing function into "unreadable" instead of an error. That is right in game, but in tests it would hide a gap in the simulation (see Decision 3).
- CI is the gate. An optional Docker image (`scripts/Dockerfile.test`, added in review) runs the same checks locally. Exploration originally chose CI-only.

## Goals / Non-Goals

**Goals:**
- A fake game environment that loads `Safe`, `Settings`, `Probe`, `Alerts`, `Lights` and `Core` unchanged.
- Spec-scenario tests for `threat-classification`, `display-gating`, `safe-api-access` and the logic parts of `alerts`, plus unit tests for `settings` parsing, migration and slash dispatch.
- One CI workflow with readable summaries.

**Non-Goals:**
- Loading `Options.lua` or `Preview.lua`. Tests stub `TT.RefreshOptions` and `TT.ToggleOptions` instead.
- Checking what frames are created or how they are anchored (`L.Place`, `L.Paint`, nameplate attach and detach). That is the follow-up change for frame-contract tests. The fake `CreateFrame` here only needs to accept calls.
- A coverage threshold that fails the build.

## Decisions

### 1. Layout

```
.github/workflows/ci.yml
.luacheckrc
.busted
scripts/check-toc.lua          -- TOC <-> root *.lua consistency
scripts/spec-coverage.lua      -- scenarios <-> test names report
spec/support/wow.lua           -- fake game environment ("fake world")
spec/support/addon.lua         -- loads addon files in TOC order into a fresh TT
spec/safe_spec.lua
spec/settings_spec.lua
spec/core_spec.lua
spec/threat_classification_spec.lua
spec/display_gating_spec.lua
spec/alerts_spec.lua
```

The test directory is busted's default `spec/`. It is unrelated to `openspec/specs/`, but the two names are close. **Alternative:** `tests/` with a `.busted` ROOT override. This is rejected because the default needs less config, and nothing in `spec/` can be mistaken for a spec file.

### 2. Loading the addon the way the client does

`addon.lua` reads `TankTrafficLight.toc`, takes the files in order, skips `Options.lua` and `Preview.lua` (and anything a test excludes), and runs each with `loadfile(path)("TankTrafficLight", TT)` against a fresh `TT`. It then fires the captured `ADDON_LOADED` handler so `Core.lua` applies migration and defaults to a `TankTrafficLightDB` the test controls.

Each `it` block builds a fresh world and reloads the files in `before_each`. Module-local state (`lastSlip`, `mobLastAlert`, the `lights` map) therefore never leaks between tests.

**Alternative:** `require` the modules once and add `_Reset()` hooks. This is rejected because it means changing addon code for tests, and a forgotten reset would leak state.

### 3. Strict globals in the fake world

The fake environment runs the addon in a sandbox environment (`setfenv` on each loaded chunk) whose `__index` errors on any global that is neither provided nor listed in `world.absent`. Absent names, such as `issecretvalue` when a test simulates an older client, resolve to `nil`.

This stops `Safe.Call(UnitFooTypo, ...)` from quietly returning "unavailable" and letting a test pass for the wrong reason. Lint catches typos statically. This catches APIs the simulation forgot.

Lua 5.1's `setfenv` makes this a per-chunk sandbox without touching busted's own globals.

### 4. One world table drives the unit APIs

```lua
world.units["nameplate1"] = { attackable = true, combat = true, threat = 0,
                              target = "party1", name = "Skeleton", guid = "Creature-...-0001" }
world.units["party1"]     = { inParty = true, role = "TANK", class = "WARRIOR", name = "Tanky" }
world.instance = { true, "party" }      -- IsInInstance()
world.time     = 100                    -- GetTime(); tests advance it
world.SECRET                            -- sentinel; any field may hold it
```

- `UnitX(unit)` looks up `world.units[unit]`. `"<unit>target"` resolves through the unit's `target` field, so `nameplate1target` is `party1`.
- `UnitIsUnit(a, b)` compares the resolved unit tokens.
- `issecretvalue(v)` returns `v == world.SECRET`. Making an API's result secret is just setting the field to `world.SECRET`.
- Calls are recorded where tests need them: `PlaySound` appends its sound id to `world.played`, and `print` appends to `world.chat`.
- `CreateFrame` returns a permissive stub that accepts any method call and captures `SetScript("OnEvent", fn)` handlers, so tests can fire events such as `PLAYER_REGEN_ENABLED`, which clears the per-mob healer throttle.

Builder helpers (`world.mob{...}`, `world.partyMember{...}`) keep scenario tests to a few lines each.

### 5. Scenario naming and the coverage script

Tests use `describe("<capability>", ...)`, then optionally `describe("<Requirement>")`, then `it("<exact Scenario title>")`. Unit tests that cover no scenario sit under a `describe("unit: ...")` block, which the coverage script ignores.

`scripts/spec-coverage.lua` (plain Lua 5.1, no extra rocks):

1. Parses `openspec/specs/*/spec.md` for `#### Scenario:` titles, keyed by capability directory.
2. Runs busted with the JSON output handler and reads each test's full name.
3. Matches on capability + title, ignoring requirement names, so a reworded requirement doesn't break the match.
4. Writes a markdown table per capability (covered / total), the uncovered scenarios, and the unmatched tests to `$GITHUB_STEP_SUMMARY`. It always exits 0.

**Alternative:** tag tests with `#scenario-id` instead. This is rejected because scenario titles are already unique within a capability, and readable titles make better test output.

### 6. CI workflow

```
on: push (all branches), pull_request, workflow_dispatch

job lint (ubuntu-latest)
  leafo/gh-actions-lua (5.1) + leafo/gh-actions-luarocks
  luarocks install luacheck
  luacheck .
  luac -p $(git ls-files '*.lua')
  lua scripts/check-toc.lua
  npm ci --ignore-scripts --prefix ci/openspec
  ci/openspec/node_modules/.bin/openspec validate --all --strict   (see Decision 8)

job test (ubuntu-latest)
  leafo/gh-actions-lua (5.1) + leafo/gh-actions-luarocks
  luarocks install busted luacov
  busted --coverage
  luacov && summarize per-file totals into $GITHUB_STEP_SUMMARY
  lua scripts/spec-coverage.lua   (always runs, even after a failure)
```

LuaRocks trees are cached per OS and rockspec list. Actions and the OpenSpec CLI are pinned to exact versions, and the CLI's whole npm dependency tree is locked by `ci/openspec/package-lock.json`, so a new release can't break CI overnight.

### 7. luacheck configuration

- `std = "lua51"`.
- `read_globals`: the WoW APIs and constants the addon reads (the `Unit*` APIs, `C_NamePlate`, `C_Timer`, `CreateFrame`, `UIParent`, `SOUNDKIT`, `GetTime`, `PlaySound`, `IsInInstance`, `InCombatLockdown`, `GetPartyAssignment`, `issecretvalue`, `CreateColor`, `STANDARD_TEXT_FONT`, `date`, and the rest of what grep finds), plus the Settings/InterfaceOptions APIs that `Options.lua` uses.
- `globals` (writable): `TankTrafficLightDB`, `SLASH_TANKTRAFFICLIGHT1`, `SLASH_TANKTRAFFICLIGHT2`, `SlashCmdList`.
- `spec/` and `scripts/` get busted globals and `std = "lua51"`.
- `max_line_length` is set to the codebase's current longest line rather than reflowing code.
- Existing warnings are fixed, not ignored. A per-line `-- luacheck: ignore` is allowed only with a reason, such as the intentional `UnitInRaid ~= nil` check.

### 8. Strict spec validation

CI runs `openspec validate --all --strict`, so warnings fail the run as well as errors.

The plan was to start non-strict and leave the spec cleanup to a follow-up change, because seven main-spec requirements (in `settings`, `nameplate-lights` and `diagnostics`) were over 500 characters. During review the follow-up was folded in instead. Each long requirement was split into smaller requirements, each stating one behavior, and edited directly in `openspec/specs/` (requirement text can't be split through a MODIFIED delta without restating it). Every scenario kept its exact title and text and moved under the requirement it describes, so test matching (Decision 5, which ignores requirement names) is unaffected. `baseline-current-behavior`, which carried the same warnings, was archived with `--skip-specs`, since its specs were already in `openspec/specs/`.

**Alternatives:** keeping non-strict validation was rejected once the cleanup was small enough to do here; it would have let new long requirements in until the follow-up landed. Running strict mode only on active changes was rejected because it adds per-item scripting.

## Risks / Trade-offs

- **The fake world can disagree with the real client.** It can return a type or shape the game never would. → Encode return shapes from the spec scenarios and the `/ttl probe` logs, not from guesses. The in-game check stays a manual step, and wrong assumptions found there become fixes to `wow.lua`.
- **Strict globals may break on addon code that legitimately tests for optional APIs** (`type(issecretvalue)`, `C_Timer and ...`). → Those names go in `world.absent` or get a stub. Each one is a known, listed exception.
- **`setfenv` sandboxing is Lua 5.1-specific.** → That's fine: 5.1 is required on purpose. A future move to 5.4 would need `load(..., env)` instead.
- **CI-only feedback is slower.** → `workflow_dispatch`, a LuaRocks cache, and failure output in the job summary keep each round under about a minute.
- **The coverage report can make spec wording look like a test problem.** Stale titles such as "Unlock the list from the window" will show up as uncovered or awkward. → They're `settings` scenarios about the options window, so they fall outside this change's test scope. They're noted for a later spec cleanup and not renamed here.
- **New dev-only files sit beside the addon in the AddOns folder.** The client ignores them because they're not in the TOC. → A packaging step that excludes them is left for whenever releases are zipped.

- **Strict validation fails on any new warning.** A future OpenSpec release could add a warning rule. → The CLI version is locked in `ci/openspec/package-lock.json`, so new rules only arrive with a deliberate upgrade.

## Migration Plan

No player-facing migration. Rollout:

1. Land the workflow with lint, the TOC check and spec validation, and get it green, including the lint fixes.
2. Add the fake world and the tests in the same change.
3. After the first green run on `main`, the maintainer marks the `lint` and `test` jobs as required checks in GitHub branch protection.

Rollback means deleting the workflow file. Addon code changes are limited to lint fixes.

## Open Questions

- The exact luacheck `max_line_length` value. It's picked from the current code during implementation.
