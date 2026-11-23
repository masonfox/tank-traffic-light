# Spec Delta

## MODIFIED Requirements

### Requirement: Sample light cycles its states
The sample light SHALL cycle through RED, YELLOW, GREEN and GREY, one step per second, for as long as the options window is open. GREY SHALL be skipped while the grey light setting is off. The sample light SHALL show YELLOW with the pulse when pulse is on, and GREY at the grey opacity setting. The sample light SHALL be shown regardless of the master toggle, tank-only filter, zone filters, and combat. It SHALL NOT trigger alerts or add trace entries.

#### Scenario: Grey light off
- **WHEN** the grey light setting is off and the window is open
- **THEN** the sample light cycles RED, YELLOW, GREEN only

#### Scenario: Pulse off
- **WHEN** pulse is off and the sample light reaches YELLOW
- **THEN** the sample light shows YELLOW at full opacity without pulsing

#### Scenario: Lights turned off
- **WHEN** the lights setting is off and the window is open
- **THEN** the sample light is still shown and cycling

#### Scenario: Sample yellow is silent
- **WHEN** the sample light turns YELLOW
- **THEN** no alert sound plays and no trace entry is saved

#### Scenario: Window closed
- **WHEN** the options window closes
- **THEN** the sample light stops cycling and no periodic work continues for it
