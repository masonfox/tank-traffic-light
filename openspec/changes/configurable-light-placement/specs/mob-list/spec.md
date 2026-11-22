## MODIFIED Requirements

### Requirement: When the list is shown
When the list setting is on, the list SHALL be shown while it has at least one row, while it is unlocked, or while the options window is open. Otherwise it SHALL be hidden. The list SHALL run only when the tank-only and "Show in" zone filters from the display-gating rules allow it. The lights setting SHALL NOT affect the list. When the list setting is off, the list SHALL be hidden in all cases. The list SHALL only ever show rows for real classified mobs; it SHALL NOT show sample rows.

#### Scenario: Out of combat
- **WHEN** the list is on and locked, no mob is classified, and the options window is closed
- **THEN** the list is hidden

#### Scenario: Options window open
- **WHEN** the list is on and locked, no mob is classified, and the options window is open
- **THEN** the list is shown with no rows, so list settings show their effect, and it hides again when the window closes

#### Scenario: Zone disabled
- **WHEN** the current zone type is turned off in "Show in", the list is locked, and the options window is closed
- **THEN** the list is hidden

#### Scenario: Player queued as healer
- **WHEN** tank-only is on and the player's role is healer
- **THEN** the list shows no rows

#### Scenario: List turned off
- **WHEN** the list setting is off
- **THEN** the list is hidden, even while the options window is open
