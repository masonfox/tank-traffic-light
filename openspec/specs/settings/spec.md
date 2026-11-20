# settings Specification

## Purpose

Defines how the player configures Tank Traffic Light: persisted settings and their defaults, the options window, the entry in the game's AddOns menu, and the slash commands.

## Requirements

### Requirement: Persisted settings with defaults
Settings SHALL persist per account in the `TankTrafficLightDB` saved variable. On load, any missing setting SHALL be filled with its default, and existing values SHALL be kept. Defaults: lights on, tank-only off, pulse on, placement left, scale 1, top offset 4, open world on, dungeons on, raids on, PvP off, trace-to-chat off, auto-probe off.

#### Scenario: First install
- **WHEN** the addon loads with no saved settings
- **THEN** every setting takes its default value

#### Scenario: New setting added in an update
- **WHEN** saved settings exist but lack a newly introduced setting
- **THEN** only that setting is filled with its default

### Requirement: Reset all settings
Resetting SHALL restore every setting to its default, refresh all lights, update the options window, and confirm in chat. The probe and trace logs SHALL NOT be cleared by a reset.

#### Scenario: Player resets
- **WHEN** the player clicks "Reset all settings"
- **THEN** all settings return to defaults, lights refresh, and chat shows "settings reset"

### Requirement: Options window
The addon SHALL provide a movable options window that stays on screen and closes with Escape. It SHALL contain:
- **Traffic lights**: show lights; only when tank (or no role); pulse yellow; placement button cycling Left, Right, Top; size field (0.5 to 3); top placement height field (0 to 60).
- **Show in**: open world; dungeons; raids; battlegrounds and arenas.
- **Diagnostics**: print every light change to chat; record an API probe 3 seconds into every pull.
- Buttons: demo toggle ("Demo: cycle colors" / "Stop demo") and "Reset all settings".

Every control SHALL apply immediately and refresh the lights.

#### Scenario: Toggle a checkbox
- **WHEN** the player clicks a checkbox or its label
- **THEN** the setting is saved and lights refresh immediately

#### Scenario: Cycle placement
- **WHEN** the placement button shows "Left" and is clicked
- **THEN** placement becomes Right and the button reads "Right"

### Requirement: Numeric fields validate input
Numeric settings SHALL be parsed and validated the same way whether entered in the options window or by slash command. Both a dot and a comma SHALL be accepted as the decimal separator. Size SHALL accept 0.5 to 3 and top placement height SHALL accept 0 to 60. Invalid or out-of-range input SHALL leave the setting unchanged and print one shared message naming the setting, its valid range, and its current value. In the window, fields SHALL apply on Enter or when focus is lost, Escape SHALL cancel the edit, and the field SHALL show the current value again after any rejected or cancelled edit.

#### Scenario: Comma decimal size
- **WHEN** the player enters `1,5` in the size field and presses Enter
- **THEN** the light scale becomes 1.5

#### Scenario: Comma decimal size by slash
- **WHEN** the player types `/ttl scale 1,5`
- **THEN** the light scale becomes 1.5

#### Scenario: Invalid height
- **WHEN** the player enters `80` in the top height field
- **THEN** chat shows that top placement height must be a number from 0 to 60, with the current value, and the field reverts

#### Scenario: Same message from both surfaces
- **WHEN** the player enters an invalid size in the window and then types the same value with `/ttl scale`
- **THEN** both print the same message

#### Scenario: Escape cancels
- **WHEN** the player edits a field and presses Escape
- **THEN** the value is not applied and the field reverts

### Requirement: AddOns menu entry
The addon SHALL register a "Tank Traffic Light" page in the game's AddOns options with a button that closes the game options and opens the options window. Registration failure SHALL NOT break the addon.

#### Scenario: Open from game options
- **WHEN** the player clicks "Open options" on the AddOns page
- **THEN** the game options close and the Tank Traffic Light window opens

### Requirement: Slash commands
`/ttl` and `/tanktrafficlight` SHALL accept these commands (case-insensitive), confirm each change in chat, and update the options window if it is open:
- no argument, `options`, `config`: toggle the options window
- Traffic lights:
  - `lights`: toggle showing traffic lights
  - `tankonly`: toggle tank-only
  - `pulse`: toggle pulsing the yellow light
  - `side [left|right|top]`: set placement; with no argument, cycle Left, Right, Top like the window's button
  - `scale <n>` or `size <n>`: set light size (0.5 to 3)
  - `height <n>`: set top placement height (0 to 60)
- Show in: `world`, `dungeon`, `raid`, `pvp`: toggle each zone filter
- Diagnostics: `trace`, `auto`, `why`, `probe`, `clear` (see diagnostics spec)
- Actions: `demo` toggles demo mode; `reset` restores all settings to defaults, like the window's button
- A numeric command with no argument SHALL print the setting's current value and valid range
- Anything else SHALL print the command list, grouped like the options window

#### Scenario: Open window
- **WHEN** the player types `/ttl`
- **THEN** the options window toggles

#### Scenario: Set placement directly
- **WHEN** the player types `/ttl side top`
- **THEN** placement becomes Top and the lights move above the health bar

#### Scenario: Cycle placement
- **WHEN** placement is Left and the player types `/ttl side`
- **THEN** placement becomes Right

#### Scenario: Invalid placement
- **WHEN** the player types `/ttl side bottom`
- **THEN** placement is unchanged and chat lists the valid choices

#### Scenario: Invalid scale
- **WHEN** the player types `/ttl scale 5`
- **THEN** chat shows the shared size message with the current value and nothing changes

#### Scenario: Query a numeric setting
- **WHEN** the player types `/ttl height`
- **THEN** chat shows the current top placement height and its 0 to 60 range

#### Scenario: Reset from chat
- **WHEN** the player types `/ttl reset`
- **THEN** all settings return to defaults, lights refresh, and chat shows "settings reset"

#### Scenario: Unknown command
- **WHEN** the player types `/ttl foo`
- **THEN** chat lists every available command

### Requirement: Options window and slash commands stay in parity
Every setting and action in the options window SHALL have a slash command that changes it the same way, and the slash command SHALL accept the same values the window accepts. Slash confirmations SHALL use the window's label text for the setting. A setting changed by either surface SHALL be shown immediately in the options window if it is open.

#### Scenario: Every window control is reachable from chat
- **WHEN** a control exists in the options window
- **THEN** there is a `/ttl` command that changes the same setting or performs the same action

#### Scenario: Same wording in chat and window
- **WHEN** the player types `/ttl pulse`
- **THEN** chat shows "Pulse the yellow light when aggro is slipping: OFF" (or ON), matching the checkbox label

#### Scenario: Window updates from chat
- **WHEN** the options window is open and the player types `/ttl raid`
- **THEN** the Raids checkbox updates immediately
