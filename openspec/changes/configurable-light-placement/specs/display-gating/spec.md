## MODIFIED Requirements

### Requirement: Master toggle
When the lights setting is off, no traffic lights SHALL be shown on nameplates. The options window's sample light is not a nameplate light and is not affected.

#### Scenario: Lights turned off
- **WHEN** the lights setting is off
- **THEN** every traffic light on a nameplate is hidden

## REMOVED Requirements

### Requirement: Demo mode bypasses gating
**Reason**: Demo mode is removed. Previewing out of combat or in a disabled zone is now done with the options window's sample nameplate, which is not subject to gating.
**Migration**: Open the options window (`/ttl`) to preview lights anywhere.
