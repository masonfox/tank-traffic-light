## MODIFIED Requirements

### Requirement: Demo mode
Demo mode SHALL cycle every visible nameplate's light through red, yellow, green and grey, moving one step per second, until it is turned off from the options window or with `/ttl demo`. Demo mode SHALL NOT trigger alerts. Demo mode SHALL NOT be saved; it SHALL be off after a reload.

#### Scenario: Start demo
- **WHEN** the player starts demo mode
- **THEN** every visible nameplate shows a light that changes state each second, including the grey state

#### Scenario: Demo shows yellow
- **WHEN** a demo light turns yellow
- **THEN** no alert sound plays

#### Scenario: Reload during demo
- **WHEN** the UI reloads while demo mode is on
- **THEN** demo mode is off afterwards

### Requirement: API probe
`/ttl probe` SHALL record, for every visible nameplate, what each API the addon relies on returns (readable value, `SECRET`, error, or missing): attackability, combat state, GUID, threat status, detailed threat, target existence, name, role, class, and main-tank assignment, and whether the nameplate frame is Blizzard or Plater. It SHALL also record whether key APIs exist, the player's role, and whether the player is in combat. Output SHALL be printed to chat and saved to a probe log that keeps the most recent 400 lines.

#### Scenario: Manual probe
- **WHEN** the player types `/ttl probe`
- **THEN** a timestamped probe report is printed and saved

#### Scenario: Probe shows co-tank inputs
- **WHEN** the player types `/ttl probe` while a mob targets a group member
- **THEN** the report shows that target's role, class, and main-tank assignment (or `SECRET`)
