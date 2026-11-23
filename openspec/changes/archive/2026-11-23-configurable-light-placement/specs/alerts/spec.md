## ADDED Requirements

### Requirement: Alerts follow nameplate classification
Alerts SHALL fire only from real light classification of nameplate units: when lights are running under the display-gating rules. The options window's sample light SHALL NOT fire alerts. Alerts SHALL never raise a Lua error; if a sound, name, role or class cannot be read, that part of the alert SHALL be skipped or replaced with a generic version.

#### Scenario: Lights gated off
- **WHEN** lights are not running in the current zone
- **THEN** no alert fires

#### Scenario: Preview cycling
- **WHEN** the options window is open and its sample light cycles to YELLOW
- **THEN** no alert fires

## REMOVED Requirements

### Requirement: Alerts follow light classification
**Reason**: Its demo-mode exception no longer applies because demo mode is removed. Replaced by "Alerts follow nameplate classification", which keeps the same rules and adds that the options window preview never fires alerts.
**Migration**: None needed. Alert behavior during real play is unchanged.
