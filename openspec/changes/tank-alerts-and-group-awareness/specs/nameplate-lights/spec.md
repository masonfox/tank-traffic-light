## MODIFIED Requirements

### Requirement: Three-lamp traffic light
Each light SHALL be a dark housing with three round lamps ordered red, yellow, green. For RED, YELLOW and GREEN, the lamp matching the current state SHALL be lit at full brightness in the active palette's color and the other two SHALL be dimmed. For GREY, all three lamps SHALL be dimmed and the whole light SHALL be drawn at reduced opacity, so it is visibly present but clearly quieter than a lit light. When a unit has no state, its light SHALL be hidden.

#### Scenario: Unit is GREEN
- **WHEN** a unit is classified GREEN
- **THEN** its light is shown with the green lamp lit and the red and yellow lamps dimmed

#### Scenario: Unit is GREY
- **WHEN** a unit is classified GREY
- **THEN** its light is shown at reduced opacity with no lamp lit

#### Scenario: Unit changes from GREY to RED
- **WHEN** a GREY unit becomes RED
- **THEN** the light returns to full opacity with the red lamp lit

#### Scenario: Unit has no light
- **WHEN** a unit's classification is "no light"
- **THEN** its traffic light is hidden

## ADDED Requirements

### Requirement: Color palettes
The lit-lamp colors SHALL come from the palette setting. "Classic" SHALL use red, yellow and green. "Colorblind" SHALL use colors that stay distinguishable with red-green color blindness: vermilion for the RED lamp, yellow for the YELLOW lamp and blue for the GREEN lamp. Lamp positions SHALL be the same in every palette. Changing the palette SHALL repaint every visible light immediately.

#### Scenario: Colorblind palette, mob on the player
- **WHEN** the palette is Colorblind and a unit is GREEN
- **THEN** the bottom lamp (horizontal: the right lamp) is lit blue

#### Scenario: Palette changed mid-combat
- **WHEN** the player switches palette while lights are visible
- **THEN** every visible light is repainted in the new palette without waiting for a state change
