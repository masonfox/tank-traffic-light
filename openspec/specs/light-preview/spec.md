# light-preview Specification

## Purpose

Shows a sample nameplate with a sample traffic light in the options window, so the player can see how placement, size, colors, pulse and opacity look on a fully dressed nameplate while changing them, without needing mobs on screen.

## Requirements

### Requirement: Sample nameplate
The options window SHALL show, in a strip across its top, a sample enemy nameplate drawn by the addon. It SHALL include a health bar partly filled, a unit name, a level, a raid target marker, a row of buff and debuff icons directly above the health bar, and a cast bar with a spell name directly below the health bar. The sample nameplate SHALL NOT depend on any real unit, nameplate, or nameplate addon being present.

#### Scenario: Open the window with no mobs around
- **WHEN** the player opens the options window with no nameplates visible
- **THEN** the preview strip shows the sample nameplate with name, level, raid marker, auras above the bar, and a cast bar below it

### Requirement: Sample light follows the settings
The sample light SHALL be placed on the sample health bar using the same placement rules as real nameplate lights: placement, alignment, gap and size. It SHALL use the current palette. Any change to these settings, from the window or by slash command, SHALL update the sample light immediately while the window is open.

#### Scenario: Bottom placement under the cast bar
- **WHEN** the player sets placement to Bottom with a gap of 4
- **THEN** the sample light is horizontal, 4 units below the sample health bar, overlapping the sample cast bar

#### Scenario: Top placement clear of the auras
- **WHEN** placement is Top, alignment is Right, and the player drags the gap slider upward
- **THEN** the sample light moves up from the right end of the health bar as the slider moves, until it clears the aura row

#### Scenario: Change from chat with the window open
- **WHEN** the options window is open and the player types `/ttl side right`
- **THEN** the sample light moves to the right of the sample health bar

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
