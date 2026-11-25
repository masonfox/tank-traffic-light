# Proposal

## Why

The addon's behavior is described by about 140 spec scenarios, but nothing checks any of them automatically. Every change so far has been verified by hand in the game client, which can't reproduce most edge cases on demand: secret values, co-tanks, unreadable roles, throttle timing. Regressions in threat classification or alerts only surface mid-pull. The repo is on GitHub with no CI, so this is the cheapest point to add a test harness before the next behavior change.

## What Changes

- Add static checks: luacheck on Lua 5.1 with a declared list of WoW globals, a check that the TOC file list matches the `.lua` files on disk, and `openspec validate --all` (errors fail the run, warnings are logged; strict mode waits for a spec cleanup follow-up).
- Add a test suite run with busted on Lua 5.1, with a fake WoW environment ("fake world"). Tests load the addon's own files unchanged, the way the client does, and drive every `Unit*` API from one table of units, a secret-value sentinel and a fake clock.
- Add unit tests for `Safe`, settings parsing, setting and cycling, the settings migration and defaults, and slash command dispatch.
- Add spec-scenario tests for `threat-classification`, `display-gating`, `alerts` (healer identification, mob-on-healer detection, throttles) and `safe-api-access`. Each test is named after the scenario it covers.
- Add a spec-coverage report that matches `#### Scenario:` headings in `openspec/specs/` to test names and prints which scenarios have a test. It is report-only and never fails the build.
- Add a GitHub Actions workflow that runs the static checks and the tests on every push, pull request and manual dispatch, and writes the coverage reports to the job summary.
- Fix whatever the new lint flags in the existing code, so the lint job starts green without blanket ignores. These fixes do not change player-facing behavior.
- Out of scope: tests that check frame anchors and lifecycle, tests for the options window and preview, running tests locally, and automated in-game tests.

## Capabilities

### New Capabilities

- `dev-testing`: the project's automated quality checks: what is linted and validated, what the test suite runs on, how tests map to spec scenarios, and when CI runs it all.

### Modified Capabilities

None. Player-facing behavior does not change.

## Impact

- New files: `.github/workflows/ci.yml`, `.luacheckrc`, `.busted`, `spec/` (the fake world in `spec/support/`, test files, the coverage script) and a TOC check script. None of these are listed in the TOC, so the client never loads them.
- Addon `.lua` files: only lint fixes such as unused locals or shadowed names. No behavior changes.
- `README.md`: the Development section says tests run in CI and where they live.
- New CI dependencies: Lua 5.1, LuaRocks, busted, luacheck, luacov, and the OpenSpec CLI (via npm).
- Making the checks required on `main` is a manual GitHub branch-protection setting, not part of the repo.
