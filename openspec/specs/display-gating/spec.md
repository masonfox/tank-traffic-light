# display-gating Specification

## Purpose

Defines when traffic lights are allowed to run at all, based on the master toggle, the player's group role, and the type of zone the player is in.

## Requirements

### Requirement: Master toggle
When the lights setting is off, no traffic lights SHALL be shown on nameplates. The options window's sample light is not a nameplate light and is not affected.

#### Scenario: Lights turned off
- **WHEN** the lights setting is off
- **THEN** every traffic light on a nameplate is hidden

### Requirement: Tank-only filter
When the tank-only setting is on, lights SHALL run only if the player's assigned role is tank or no role is assigned. If the role cannot be read, lights SHALL run.

#### Scenario: Player queued as healer
- **WHEN** tank-only is on and the player's role is healer or damage
- **THEN** every traffic light is hidden

#### Scenario: Player has no role
- **WHEN** tank-only is on and the player has no assigned role
- **THEN** lights run normally

#### Scenario: Role cannot be read
- **WHEN** tank-only is on and the player's role cannot be read
- **THEN** lights run normally

### Requirement: Zone filters
Lights SHALL run only in zone types enabled in settings. Open world and scenarios use the open-world setting; dungeons use the dungeon setting; raids use the raid setting; battlegrounds and arenas use the PvP setting. Unknown instance types SHALL use the open-world setting. If the zone type cannot be read, lights SHALL run.

#### Scenario: PvP disabled by default
- **WHEN** the player enters a battleground or arena with default settings
- **THEN** every traffic light is hidden

#### Scenario: Scenario counts as open world
- **WHEN** the player is in a scenario and the open-world setting is on
- **THEN** lights run

#### Scenario: Zone type unreadable
- **WHEN** the instance type cannot be read
- **THEN** lights run
