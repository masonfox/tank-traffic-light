## Purpose

Defines the traffic light widget attached to enemy nameplates: how it looks, where it sits, how it signals slipping aggro, and when it is refreshed.

## ADDED Requirements

### Requirement: Three-lamp traffic light
Each light SHALL be a dark housing with three round lamps ordered red, yellow, green. The lamp matching the current state SHALL be lit at full brightness and the other two SHALL be dimmed. When a unit has no state, its light SHALL be hidden.

#### Scenario: Unit is GREEN
- **WHEN** a unit is classified GREEN
- **THEN** its light is shown with the green lamp lit and the red and yellow lamps dimmed

#### Scenario: Unit has no light
- **WHEN** a unit's classification is "no light"
- **THEN** its traffic light is hidden

### Requirement: Yellow pulses
While a light is YELLOW and the pulse setting is on, the whole light SHALL pulse (fade between full and reduced opacity). In any other state, or with pulse off, the light SHALL be fully opaque and still.

#### Scenario: Aggro starts slipping
- **WHEN** a light changes to YELLOW with pulse enabled
- **THEN** the light starts pulsing

#### Scenario: Aggro recovered
- **WHEN** a pulsing light changes to GREEN
- **THEN** pulsing stops and the light returns to full opacity

### Requirement: Placement
The light SHALL be anchored to the nameplate's health bar: to its left (default) or right, standing vertically with red on top, or above it laid out horizontally with red on the left. In the top position the gap above the health bar SHALL equal the top offset setting. If no health bar is found, the light SHALL anchor to the nameplate itself.

#### Scenario: Top placement
- **WHEN** placement is "top" and the top offset is 10
- **THEN** the light is horizontal and sits 10 units above the health bar

#### Scenario: Left placement
- **WHEN** placement is "left"
- **THEN** the light is vertical and sits just left of the health bar

### Requirement: Nameplate addon compatibility
The light SHALL attach to Plater nameplates and to default Blizzard nameplates.

#### Scenario: Plater installed
- **WHEN** nameplates are drawn by Plater
- **THEN** the light anchors to Plater's health bar

### Requirement: Scale
The light SHALL be drawn at the light scale setting (0.5 to 3).

#### Scenario: Scale changed
- **WHEN** the light scale setting changes to 2
- **THEN** every light is redrawn at double size

### Requirement: Recycled nameplates do not carry stale state
When the game reuses a nameplate frame for a different unit, the light SHALL forget its previous state and pulse before showing the new unit's state.

#### Scenario: Plate reused for a new mob
- **WHEN** a nameplate that showed a YELLOW mob is reassigned to a different mob
- **THEN** the light starts with no previous state and does not keep pulsing from the old mob

### Requirement: Light lifecycle
A light SHALL be evaluated when a nameplate appears, and hidden and cleared when its nameplate is removed.

#### Scenario: Nameplate removed
- **WHEN** a unit's nameplate is removed
- **THEN** its light is hidden and its state cleared

### Requirement: Refresh triggers
Lights SHALL be re-evaluated on threat changes, target changes, entering or leaving combat, role assignment, entering the world, and zone changes. Events about a specific nameplate SHALL refresh only that nameplate; other events SHALL refresh every visible nameplate. Changing a setting SHALL refresh every light immediately.

#### Scenario: Mob switches target
- **WHEN** a nameplate unit's target changes
- **THEN** that unit's light is re-evaluated

#### Scenario: Zone change
- **WHEN** the player changes zone
- **THEN** every visible light is re-evaluated

### Requirement: Periodic refresh in combat
While the player is in combat, every visible light SHALL be re-evaluated about four times per second, to catch changes no event reports. Outside combat, no periodic refresh SHALL run (except demo cycling).

#### Scenario: Player in combat
- **WHEN** the player is in combat
- **THEN** all visible lights are re-evaluated roughly every 0.25 seconds

#### Scenario: Player out of combat
- **WHEN** the player is not in combat and demo mode is off
- **THEN** lights update only in response to events
