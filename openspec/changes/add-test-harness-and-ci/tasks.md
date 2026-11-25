# Tasks

## 1. Static checks in CI

- [x] 1.1 Add `.luacheckrc` (Lua 5.1 std, WoW read globals, writable addon globals, busted std for `spec/` and `scripts/`, `max_line_length` from the current longest line) and verify the globals list covers every capitalized global grep finds in the addon files
- [x] 1.2 Fix the warnings luacheck reports on the existing addon files, using reasoned per-line ignores only for intentional cases, and verify in CI that `luacheck .` exits 0 with no player-facing changes in the diff
- [x] 1.3 Add `scripts/check-toc.lua` (TOC files exist; every root `.lua` file is listed; files outside the root are ignored) and verify it passes on the repo and fails when a TOC entry is temporarily renamed in a throwaway branch
- [x] 1.4 Add `.github/workflows/ci.yml` with the `lint` job (pinned `leafo/gh-actions-lua` 5.1, `leafo/gh-actions-luarocks`, LuaRocks cache, luacheck, TOC check, pinned OpenSpec CLI running `openspec validate --all` without `--strict`, so warnings are logged but don't fail), triggered on push, pull_request and workflow_dispatch, and verify a pushed branch shows a green `lint` run and a manual dispatch re-runs it

## 2. Fake game environment

- [x] 2.1 Add `spec/support/wow.lua`: world table, `SECRET` sentinel with `issecretvalue`, unit APIs resolved through `world.units` (including `<unit>target`), `IsInInstance`, `GetTime`, `InCombatLockdown`, `PlaySound`/`SOUNDKIT` recording, `print` recording, `C_Timer.After` run immediately, and a permissive `CreateFrame` that captures `OnEvent` handlers. Verify with a `describe("unit: fake world")` test that resolves `nameplate1target` and reports a secret role as secret
- [x] 2.2 Add strict globals: a sandbox env per loaded chunk whose lookups error unless the name is provided or listed in `world.absent`. Verify with tests that reading an unknown global fails, and that an absent `issecretvalue` reads as `nil`
- [x] 2.3 Add `spec/support/addon.lua`: read the TOC, load the addon files in order into a fresh `TT` (skipping `Options.lua` and `Preview.lua`, stubbing `TT.RefreshOptions`/`TT.ToggleOptions`), and fire `ADDON_LOADED` with a test-supplied `TankTrafficLightDB`. Verify with a test that all six files load and `TT.Lights.StateFor` exists
- [x] 2.4 Add builder helpers (`world.mob`, `world.partyMember`, `world.raidMember`, `world.stranger`) and `.busted` config, and verify a test written with them stays within a few lines
- [x] 2.5 Add the `test` job to `ci.yml` (busted with `--coverage`, luacov per-file totals in `$GITHUB_STEP_SUMMARY`) and verify CI shows a green `test` run and a coverage table in the summary

## 3. Unit tests

- [x] 3.1 Add `spec/safe_spec.lua` covering every `safe-api-access` scenario (secret value, no secret-value API, check that throws, missing API, API that errors, secret name in logs, probing a missing API), and verify all of them pass in CI
- [x] 3.2 Add `spec/settings_spec.lua` covering number parsing (comma decimal, range, off-step), toggle/choice validation, `Cycle` wrapping, the migration (`topOffset` to `gap`, mob-list keys dropped) and defaults on first install. Use `settings` scenario titles where one applies, such as "Comma decimal size by slash", "Invalid gap", "Cycle placement wraps" and "Upgrading keeps the top height", and verify they pass in CI
- [x] 3.3 Add `spec/core_spec.lua` driving `SlashCmdList.TANKTRAFFICLIGHT`: alias commands (`height`, `gray`), invalid values, removed mob-list commands and unknown commands printing help, `reset`, and `clear` emptying both logs. Verify the matching `settings`/`diagnostics` scenarios pass in CI

## 4. Spec-scenario tests

- [x] 4.1 Add `spec/threat_classification_spec.lua` covering every `threat-classification` scenario (attackable/combat gating, threat-status colors, stranger and co-tank GREY, unreadable target RED, every fallback case, pet and raid membership, explanation text, grey off) and verify all of them pass in CI
- [x] 4.2 Add `spec/display_gating_spec.lua` covering every `display-gating` scenario, using `L.Update` on a nameplate with `C_NamePlate.GetNamePlateForUnit` returning a stub plate and asserting whether classification ran. Verify they pass in CI
- [x] 4.3 Add `spec/alerts_spec.lua` covering the logic `alerts` scenarios (slipping sound and its throttle across mobs, setting off, healer identification by role and class, mob-on-healer detection including flicker and co-tank, per-mob throttle reset on `PLAYER_REGEN_ENABLED`, missing sound is silent, the test command plays both sounds, alerts gated with the lights) using the fake clock and recorded `PlaySound` calls. Verify they pass in CI
- [x] 4.4 Any scenario in these capabilities that the fake world can't express (purely visual flash details) is left uncovered on purpose, and the reason is noted in the test file header. Verify the coverage report lists only those as uncovered for these capabilities

## 5. Spec coverage report and docs

- [x] 5.1 Add `scripts/spec-coverage.lua` (parse `openspec/specs/*/spec.md` scenarios, read busted JSON output, match on capability + title, write covered/total per capability, uncovered scenarios and unmatched tests to `$GITHUB_STEP_SUMMARY`, always exit 0) and verify that renaming a test in a throwaway commit makes it show as unmatched without failing the run
- [x] 5.2 Run the coverage script in the `test` job even when earlier steps fail, and verify the summary appears on both a green run and a deliberately failing run
- [x] 5.3 Update the README Development section (tests run in CI on every push, test files in `spec/`, naming tests after scenarios, the coverage report in the job summary) and verify the described paths and names match the repo

## 6. Integration

- [ ] 6.1 Open a pull request from the change branch and verify both `lint` and `test` pass on it, with the coverage and spec-coverage tables in the summary
- [ ] 6.2 Load the addon in the WoW Forever client and verify `/ttl why` and a pull behave as before, since lint fixes touched addon files

## Workflow follow-up

- After the first green run on `main`, mark `lint` and `test` as required status checks in GitHub branch protection (manual repository setting).
- Archive this change once merged.
- Follow-up change: split the over-500-character requirements, archive `baseline-current-behavior`, fix the stale mob-list scenario titles in `settings`, then switch CI to `openspec validate --all --strict`.
