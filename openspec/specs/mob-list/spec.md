# mob-list Specification

## Purpose

Defines the mob list: a fixed on-screen panel that lists every mob the traffic lights have classified, so the tank can see loose, slipping and held mobs in one place instead of scanning nameplates.

## Requirements

### Requirement: List follows light classification
The mob list SHALL show exactly the mobs that have a nameplate and are classified RED, YELLOW or GREEN by the threat-classification rules, using the same state the light would show. GREY mobs SHALL NOT be listed, whether or not the grey light is turned on. Mobs without a nameplate SHALL NOT be listed. When a mob's nameplate is removed, or the mob stops being classified, its row SHALL be removed at the next list refresh.

#### Scenario: Loose mob is listed
- **WHEN** a nameplate mob is classified RED
- **THEN** the list shows a RED row for it

#### Scenario: Grey mob is not listed
- **WHEN** a nameplate mob is classified GREY
- **THEN** the list shows no row for it

#### Scenario: Nameplate goes away
- **WHEN** a listed mob's nameplate is removed
- **THEN** its row disappears

#### Scenario: Combat ends
- **WHEN** a listed mob leaves combat
- **THEN** its row disappears

### Requirement: List works without the lights
Mobs SHALL be classified for the list whenever the list is turned on and allowed to run, even when the traffic lights are turned off. Turning the lights off SHALL hide the lights only. Alerts SHALL keep following the lights' gating, so they do not fire when the lights are off.

#### Scenario: Lights off, list on
- **WHEN** the lights setting is off, the list setting is on, and a mob is loose on a group member
- **THEN** no light is shown, the list shows a RED row for the mob, and no alert fires

### Requirement: Row content
Each row SHALL show a marker in the current palette's color for its state, and the mob's name. A RED row SHALL also show `-> ` followed by the name of the unit the mob is targeting. A YELLOW row SHALL also show "(slipping)". A GREEN row SHALL show only the marker and name. A name that cannot be read SHALL be shown as `?`, and the list SHALL NOT raise an error for any unreadable value. Text too long for the row SHALL be truncated.

#### Scenario: Loose mob on a healer
- **WHEN** a Defias Trapper targeting Heidi is classified RED
- **THEN** its row reads "Defias Trapper -> Heidi" with a red marker

#### Scenario: Slipping mob
- **WHEN** a Goretusk is classified YELLOW
- **THEN** its row reads "Goretusk (slipping)" with a yellow marker

#### Scenario: Unreadable target name
- **WHEN** a RED mob's target name cannot be read
- **THEN** its row reads "<mob name> -> ?" and no error occurs

#### Scenario: Colorblind palette
- **WHEN** the palette is Colorblind
- **THEN** row markers and header counts use the Colorblind colors

### Requirement: Row order
Rows SHALL be sorted RED first, then YELLOW, then GREEN. Within a state, mobs SHALL keep the order in which they entered that state, so rows do not reshuffle on every refresh.

#### Scenario: Mixed states
- **WHEN** one mob is GREEN, one RED and one YELLOW
- **THEN** the rows show the RED mob, then the YELLOW mob, then the GREEN mob

#### Scenario: Stable order
- **WHEN** two mobs are RED and neither changes state
- **THEN** their rows keep the same order across refreshes

### Requirement: Row cap
The list SHALL show at most the configured maximum number of rows (3 to 20, default 8). When more mobs are classified, the last line SHALL read "+N more", where N is the number of mobs not shown. The rows that are dropped SHALL be the lowest in sort order.

#### Scenario: Too many mobs
- **WHEN** the maximum is 8 and 11 mobs are classified, 2 of them RED
- **THEN** both RED rows are shown among 8 rows, followed by "+3 more"

### Requirement: Header counts
The list SHALL have a header that shows the number of listed mobs in each state as `R<n> Y<n> G<n>`, each count in its state's palette color. The counts SHALL include mobs beyond the row cap.

#### Scenario: Counts
- **WHEN** 2 mobs are RED, 1 YELLOW and 3 GREEN
- **THEN** the header shows "R2 Y1 G3"

### Requirement: Minimize
The header SHALL have a button that minimizes the list to just the header with counts, and expands it again. The minimized state SHALL be saved, and SHALL be the same setting the options window and slash command change. The button SHALL work in combat.

#### Scenario: Minimize in combat
- **WHEN** the player clicks the header's minimize button during combat
- **THEN** the rows are hidden, the header with counts stays, and the button changes to expand

#### Scenario: Minimized state survives reload
- **WHEN** the list is minimized and the UI reloads
- **THEN** the list is still minimized

### Requirement: Display-only
Rows SHALL NOT respond to clicks, SHALL NOT target, focus or act on any unit, and SHALL NOT block clicks to the game world when the list is locked, apart from the header's minimize button.

#### Scenario: Click a row
- **WHEN** the player clicks a row
- **THEN** nothing is targeted and nothing changes

### Requirement: Lock and move
When the list is unlocked, the player SHALL be able to drag it by its header, and its position SHALL be saved and restored after a reload. When it is locked, it SHALL NOT move. The list SHALL be locked by default. While unlocked, the list SHALL stay visible even with no rows, showing a hint that it can be dragged. The list SHALL be kept on screen.

#### Scenario: Move the list
- **WHEN** the list is unlocked and the player drags its header to a new spot
- **THEN** the list stays there and is in the same spot after a reload

#### Scenario: Locked list
- **WHEN** the list is locked and the player drags its header
- **THEN** the list does not move

#### Scenario: Unlocked out of combat
- **WHEN** the list is unlocked and no mobs are classified
- **THEN** the list is visible with a drag hint, so it can be placed

### Requirement: When the list is shown
When the list setting is on, the list SHALL be shown while it has at least one row, while it is unlocked, while demo mode is on, or while the options window is open. Otherwise it SHALL be hidden. The list SHALL run only when the tank-only and "Show in" zone filters from the display-gating rules allow it. The lights setting SHALL NOT affect the list. When the list setting is off, the list SHALL be hidden in all cases, including demo mode.

#### Scenario: Out of combat
- **WHEN** the list is on and locked, no mob is classified, and the options window is closed
- **THEN** the list is hidden

#### Scenario: Options window open
- **WHEN** the list is on and locked, no mob is classified, and the options window is open
- **THEN** the list is shown, so list settings show their effect, and it hides again when the window closes

#### Scenario: Zone disabled
- **WHEN** the current zone type is turned off in "Show in", the list is locked, and the options window is closed
- **THEN** the list is hidden

#### Scenario: Player queued as healer
- **WHEN** tank-only is on and the player's role is healer
- **THEN** the list shows no rows

#### Scenario: List turned off
- **WHEN** the list setting is off
- **THEN** the list is hidden, even in demo mode

### Requirement: Refresh
The list SHALL reflect classification changes within about 0.25 seconds while the player is in combat. A setting change that affects the list SHALL apply immediately. Redrawing the list SHALL happen at most once per refresh, not once per mob.

#### Scenario: Mob turns loose
- **WHEN** a listed GREEN mob switches to a group member and is classified RED
- **THEN** within about 0.25 seconds its row moves to the RED group with the target's name

#### Scenario: Change the row cap
- **WHEN** the player changes the maximum rows from 8 to 4
- **THEN** the list shows at most 4 rows immediately
