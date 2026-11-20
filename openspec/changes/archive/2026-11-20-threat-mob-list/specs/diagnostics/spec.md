## MODIFIED Requirements

### Requirement: Demo mode
Demo mode SHALL cycle every visible nameplate's light through red, yellow, green and grey, moving one step per second, until it is turned off from the options window or with `/ttl demo`. While the mob list is turned on, demo mode SHALL also show the list with a fixed set of sample rows covering red, yellow and green, with sample names and targets, regardless of gating and even with no nameplates visible. Demo mode SHALL NOT trigger alerts. Demo mode SHALL NOT be saved; it SHALL be off after a reload.

#### Scenario: Start demo
- **WHEN** the player starts demo mode
- **THEN** every visible nameplate shows a light that changes state each second, including the grey state

#### Scenario: Demo fills the list
- **WHEN** the mob list is on and the player starts demo mode with no nameplates visible
- **THEN** the list appears with sample red, yellow and green rows and matching header counts

#### Scenario: Stop demo clears the list
- **WHEN** the player stops demo mode out of combat with the list locked
- **THEN** the sample rows are removed and the list hides

#### Scenario: Demo shows yellow
- **WHEN** a demo light turns yellow
- **THEN** no alert sound plays

#### Scenario: Reload during demo
- **WHEN** the UI reloads while demo mode is on
- **THEN** demo mode is off afterwards
