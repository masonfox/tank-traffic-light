# diagnostics Specification

## Purpose

Defines the tools for previewing the lights and for diagnosing unexpected colors or restricted APIs: demo mode, the light-change trace, per-light explanations, and the API probe.

## Requirements

### Requirement: Demo mode
Demo mode SHALL cycle every visible nameplate's light through red, yellow, and green, moving one step per second, until it is turned off from the options window or with `/ttl demo`. Demo mode SHALL NOT be saved; it SHALL be off after a reload.

#### Scenario: Start demo
- **WHEN** the player starts demo mode
- **THEN** every visible nameplate shows a light that changes color each second

#### Scenario: Reload during demo
- **WHEN** the UI reloads while demo mode is on
- **THEN** demo mode is off afterwards

### Requirement: Light-change trace
Whenever a light's color changes during normal (non-demo) operation, the addon SHALL save a trace entry with time, nameplate unit, unit name, a short GUID suffix, old and new state, and the classification reason. The trace log SHALL keep the most recent 300 entries. When trace-to-chat is on, each entry SHALL also be printed to chat. `/ttl trace` SHALL toggle trace-to-chat; entries are saved either way.

#### Scenario: Light turns red
- **WHEN** a light changes from GREEN to RED
- **THEN** a trace entry is saved with both states and the reason

#### Scenario: Trace to chat off
- **WHEN** trace-to-chat is off and a light changes color
- **THEN** the entry is saved but not printed

### Requirement: Explain visible lights
`/ttl why` SHALL print the current master-toggle, tank-only, gating, and demo status, then one line per visible nameplate with its name, decided state, reason, and whether its plate and light exist and are shown, followed by the number of visible nameplates. Each printed line SHALL also be saved to the trace log, prefixed with `WHY`.

#### Scenario: Ask why
- **WHEN** the player types `/ttl why` with two hostile nameplates visible
- **THEN** chat shows a status line, one line for each nameplate, and "visible nameplates: 2"

### Requirement: API probe
`/ttl probe` SHALL record, for every visible nameplate, what each API the addon relies on returns (readable value, `SECRET`, error, or missing): attackability, combat state, GUID, threat status, detailed threat, target existence, name, and role, and whether the nameplate frame is Blizzard or Plater. It SHALL also record whether key APIs exist, the player's role, and whether the player is in combat. Output SHALL be printed to chat and saved to a probe log that keeps the most recent 400 lines.

#### Scenario: Manual probe
- **WHEN** the player types `/ttl probe`
- **THEN** a timestamped probe report is printed and saved

### Requirement: Auto-probe on pull
When auto-probe is on, a probe SHALL run 3 seconds after the player enters combat, if the player is still in combat. `/ttl auto` and the options checkbox SHALL toggle it.

#### Scenario: Pull with auto-probe
- **WHEN** auto-probe is on and the player enters combat and stays in combat for 3 seconds
- **THEN** a probe report labelled as automatic is recorded

#### Scenario: Short combat
- **WHEN** auto-probe is on and combat ends within 3 seconds
- **THEN** no probe runs

### Requirement: Clear logs
`/ttl clear` SHALL empty both the probe log and the trace log and confirm in chat.

#### Scenario: Clear
- **WHEN** the player types `/ttl clear`
- **THEN** both logs are empty and chat confirms
