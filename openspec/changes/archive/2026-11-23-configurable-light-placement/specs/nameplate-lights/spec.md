## MODIFIED Requirements

### Requirement: Placement
The light SHALL be anchored to the nameplate's health bar on the side set by the placement setting: left (default), right, top, or bottom. On the left or right the light SHALL stand vertically with red on top, vertically centred on the health bar. On the top or bottom the light SHALL lie horizontally with red on the left, and the alignment setting SHALL place it along the health bar: Left aligns the light's left edge with the bar's left edge, Middle centres it (default), and Right aligns the light's right edge with the bar's right edge. Alignment SHALL have no effect for left and right placement. For every placement, the space between the light and the health bar SHALL equal the gap setting. If no health bar is found, the light SHALL anchor to the nameplate itself.

#### Scenario: Top placement
- **WHEN** placement is "top", alignment is Middle, and the gap is 10
- **THEN** the light is horizontal, centred, and sits 10 units above the health bar

#### Scenario: Bottom placement aligned left
- **WHEN** placement is "bottom", alignment is Left, and the gap is 2
- **THEN** the light is horizontal, sits 2 units below the health bar, and its left edge lines up with the bar's left edge

#### Scenario: Top placement aligned right
- **WHEN** placement is "top" and alignment is Right
- **THEN** the light's right edge lines up with the health bar's right edge

#### Scenario: Left placement
- **WHEN** placement is "left" and the gap is 4
- **THEN** the light is vertical and sits 4 units left of the health bar

#### Scenario: Right placement with a larger gap
- **WHEN** placement is "right" and the gap is 20
- **THEN** the light is vertical and sits 20 units right of the health bar

#### Scenario: Alignment ignored on the sides
- **WHEN** placement is "left" and alignment changes from Middle to Right
- **THEN** the light does not move

### Requirement: Periodic refresh in combat
While the player is in combat, every visible light SHALL be re-evaluated about four times per second, to catch changes no event reports. Outside combat, no periodic refresh of nameplate lights SHALL run.

#### Scenario: Player in combat
- **WHEN** the player is in combat
- **THEN** all visible lights are re-evaluated roughly every 0.25 seconds

#### Scenario: Player out of combat
- **WHEN** the player is not in combat
- **THEN** lights update only in response to events
