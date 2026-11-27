# nameplate-lights Specification

## Purpose

Defines the traffic light widget attached to enemy nameplates: how it looks, where it sits, how it signals slipping aggro, and when it is refreshed.

## Requirements

### Requirement: Three-lamp traffic light
Each light SHALL be a dark housing with three round lamps ordered red, yellow, green. For RED, YELLOW and GREEN, the lamp matching the current state SHALL be lit at full brightness in the active palette's color and the other two SHALL be dimmed. When a unit has no state, its light SHALL be hidden.

#### Scenario: Unit is GREEN
- **WHEN** a unit is classified GREEN
- **THEN** its light is shown with the green lamp lit and the red and yellow lamps dimmed

#### Scenario: Unit has no light
- **WHEN** a unit's classification is "no light"
- **THEN** its traffic light is hidden

### Requirement: Grey light appearance
For GREY, all three lamps SHALL be dimmed and the whole light SHALL be drawn at the grey-opacity setting (0.1 to 1, default 0.45), so it is visibly present but quieter than a lit light. Changing the grey opacity SHALL repaint visible GREY lights immediately.

#### Scenario: Unit is GREY
- **WHEN** a unit is classified GREY
- **THEN** its light is shown at the grey-opacity setting with no lamp lit

#### Scenario: Grey opacity changed
- **WHEN** the player sets grey opacity to 0.2 while GREY lights are visible
- **THEN** those lights immediately redraw at 0.2 opacity

#### Scenario: Unit changes from GREY to RED
- **WHEN** a GREY unit becomes RED
- **THEN** the light returns to full opacity with the red lamp lit

### Requirement: Yellow pulses
While a light is YELLOW and the pulse setting is on, the whole light SHALL pulse (fade between full and reduced opacity). In any other state, or with pulse off, the light SHALL be fully opaque and still.

#### Scenario: Aggro starts slipping
- **WHEN** a light changes to YELLOW with pulse enabled
- **THEN** the light starts pulsing

#### Scenario: Aggro recovered
- **WHEN** a pulsing light changes to GREEN
- **THEN** pulsing stops and the light returns to full opacity

### Requirement: Placement
The light SHALL be anchored to the nameplate's health bar on the side set by the placement setting: left (default), right, top, or bottom. On the left or right the light SHALL stand vertically with red on top, vertically centred on the health bar. On the top or bottom the light SHALL lie horizontally with red on the left. For every placement, the space between the light and the health bar SHALL equal the gap setting. If no health bar is found, the light SHALL anchor to the nameplate itself.

#### Scenario: Top placement
- **WHEN** placement is "top", alignment is Middle, and the gap is 10
- **THEN** the light is horizontal, centred, and sits 10 units above the health bar

#### Scenario: Left placement
- **WHEN** placement is "left" and the gap is 4
- **THEN** the light is vertical and sits 4 units left of the health bar

#### Scenario: Right placement with a larger gap
- **WHEN** placement is "right" and the gap is 20
- **THEN** the light is vertical and sits 20 units right of the health bar

### Requirement: Alignment along the health bar
For top and bottom placement, the alignment setting SHALL place the light along the health bar: Left aligns the light's left edge with the bar's left edge, Middle centres it (default), and Right aligns the light's right edge with the bar's right edge. Alignment SHALL have no effect for left and right placement.

#### Scenario: Bottom placement aligned left
- **WHEN** placement is "bottom", alignment is Left, and the gap is 2
- **THEN** the light is horizontal, sits 2 units below the health bar, and its left edge lines up with the bar's left edge

#### Scenario: Top placement aligned right
- **WHEN** placement is "top" and alignment is Right
- **THEN** the light's right edge lines up with the health bar's right edge

#### Scenario: Alignment ignored on the sides
- **WHEN** placement is "left" and alignment changes from Middle to Right
- **THEN** the light does not move

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
While the player is in combat, every visible light SHALL be re-evaluated about four times per second, to catch changes no event reports. Outside combat, no periodic refresh of nameplate lights SHALL run.

#### Scenario: Player in combat
- **WHEN** the player is in combat
- **THEN** all visible lights are re-evaluated roughly every 0.25 seconds

#### Scenario: Player out of combat
- **WHEN** the player is not in combat
- **THEN** lights update only in response to events

### Requirement: Color palettes
The lit-lamp colors SHALL come from the palette setting. "Classic" SHALL use red, yellow and green. "Colorblind" SHALL use colors that stay distinguishable with red-green color blindness: vermilion for the RED lamp, yellow for the YELLOW lamp and blue for the GREEN lamp. Lamp positions SHALL be the same in every palette. Changing the palette SHALL repaint every visible light immediately.

#### Scenario: Colorblind palette, mob on the player
- **WHEN** the palette is Colorblind and a unit is GREEN
- **THEN** the bottom lamp (horizontal: the right lamp) is lit blue

#### Scenario: Palette changed mid-combat
- **WHEN** the player switches palette while lights are visible
- **THEN** every visible light is repainted in the new palette without waiting for a state change
