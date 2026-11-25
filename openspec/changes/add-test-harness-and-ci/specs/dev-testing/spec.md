## ADDED Requirements

### Requirement: CI runs on every change
The repository SHALL run its static checks and test suite in CI on every push to any branch, on every pull request, and on manual dispatch. A failing check SHALL mark the run as failed.

#### Scenario: Push to a branch
- **WHEN** a commit is pushed to any branch
- **THEN** CI runs the static checks and the test suite against that commit

#### Scenario: Pull request
- **WHEN** a pull request is opened or updated
- **THEN** CI runs the static checks and the test suite and reports their result on the pull request

#### Scenario: Manual re-run
- **WHEN** a maintainer dispatches the workflow by hand
- **THEN** CI runs again without needing a new commit

#### Scenario: A check fails
- **WHEN** lint, the TOC check, spec validation or any test fails
- **THEN** the CI run is marked failed

### Requirement: Lint against the game's Lua
CI SHALL lint every addon and test Lua file as Lua 5.1, the language version the game client runs. Any read or write of a global that is not a declared game API, a Lua 5.1 standard global, or one of the addon's own declared globals SHALL fail lint.

#### Scenario: Misspelled API name
- **WHEN** addon code reads an undeclared global such as a misspelled game API
- **THEN** lint fails and names the file and line

#### Scenario: Accidental global write
- **WHEN** addon code assigns to a global other than the saved variable and slash command globals
- **THEN** lint fails

#### Scenario: Newer Lua syntax
- **WHEN** addon code uses syntax not in Lua 5.1, such as `goto`
- **THEN** lint fails

### Requirement: TOC matches the addon files
CI SHALL fail when a file listed in the TOC does not exist, or when an addon `.lua` file in the repository root is not listed in the TOC.

#### Scenario: Listed file missing
- **WHEN** the TOC lists a file that is not in the repository
- **THEN** the TOC check fails and names the file

#### Scenario: Unlisted addon file
- **WHEN** a `.lua` file in the repository root is not listed in the TOC
- **THEN** the TOC check fails and names the file

#### Scenario: Test files are not addon files
- **WHEN** test or tooling Lua files exist outside the repository root
- **THEN** the TOC check ignores them

### Requirement: Specs stay valid
CI SHALL validate every spec and active change with OpenSpec and fail when validation reports an error. Validation warnings SHALL be shown in the CI log but SHALL NOT fail the run.

#### Scenario: Structural error
- **WHEN** a spec or active change has a validation error, such as a requirement with no scenario
- **THEN** spec validation fails

#### Scenario: Warning only
- **WHEN** validation reports only warnings, such as a requirement description over 500 characters
- **THEN** the warnings appear in the CI log and spec validation passes

### Requirement: Tests run the addon's own files under Lua 5.1
The test suite SHALL run on Lua 5.1 and load the addon's unmodified source files, the same way the game client does, inside a simulated game environment. Each test SHALL start from freshly loaded addon files, so no state carries over between tests.

#### Scenario: Module state does not leak
- **WHEN** one test triggers an alert throttle and the next test triggers the same alert
- **THEN** the second test's alert is not throttled

#### Scenario: Addon file uses a game API the simulation lacks
- **WHEN** addon code reads a global that the simulated environment neither provides nor declares as absent
- **THEN** the affected tests fail, rather than the addon's guarded calls quietly treating the API as unavailable

#### Scenario: API deliberately absent
- **WHEN** a test declares an optional API absent, such as the secret-value check
- **THEN** addon code sees it as missing, as on a client without it

### Requirement: Simulated game state is controllable per test
The simulated environment SHALL let each test set the units the game would report (attackability, combat state, threat status, target, group membership, role, class, name, GUID), the player's instance type, and the game clock. Any of these values SHALL be settable to a secret value that the addon cannot read.

#### Scenario: Mob on a co-tank
- **WHEN** a test sets a nameplate unit not tanked by the player and targeting a party member whose role is TANK
- **THEN** the addon classifies that unit as it would in game, GREY

#### Scenario: Secret role
- **WHEN** a test makes a unit's role a secret value
- **THEN** the addon sees that role as unreadable, as it would in game

#### Scenario: Advancing the clock
- **WHEN** a test advances the game clock past an alert throttle
- **THEN** the next qualifying event alerts again

### Requirement: Tests are named after spec scenarios
A test that covers a spec scenario SHALL be grouped under the scenario's capability and named with the exact scenario title, so tests can be matched to scenarios mechanically.

#### Scenario: Covering a scenario
- **WHEN** a test covers the threat-classification scenario "Mob is on a co-tank"
- **THEN** the test is grouped under `threat-classification` and named "Mob is on a co-tank"

### Requirement: Spec coverage report
CI SHALL report, for each capability, how many spec scenarios have a matching test, and list the scenarios that have none. The report SHALL appear in the CI run's summary and SHALL NOT fail the run.

#### Scenario: Scenario without a test
- **WHEN** a spec scenario has no test with its capability and title
- **THEN** the report lists it as uncovered, and the run still passes

#### Scenario: Test without a scenario
- **WHEN** a test is grouped under a capability but its name matches no scenario in that capability
- **THEN** the report lists it as unmatched, so renamed or removed scenarios are noticed

### Requirement: Line coverage report
CI SHALL measure line coverage of the addon's source files while the test suite runs, and show per-file totals in the CI run's summary. Coverage SHALL NOT fail the run.

#### Scenario: Coverage summary
- **WHEN** the test suite finishes in CI
- **THEN** the run summary shows the line coverage of each addon file
