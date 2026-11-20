## Purpose

Defines how the player configures Tank Traffic Light: persisted settings and their defaults, the options window, the entry in the game's AddOns menu, and the slash commands.

## ADDED Requirements

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
Size and top-height fields SHALL apply on Enter or when focus is lost, and Escape SHALL cancel the edit. Size SHALL accept a comma as the decimal separator. Out-of-range or non-numeric input SHALL be rejected with a chat message, and the field SHALL show the current value again.

#### Scenario: Comma decimal size
- **WHEN** the player enters `1,5` in the size field and presses Enter
- **THEN** the light scale becomes 1.5

#### Scenario: Invalid height
- **WHEN** the player enters `80` in the top height field
- **THEN** chat shows "height must be a number from 0 to 60" and the field reverts

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
- `lights`: toggle lights
- `tankonly`: toggle tank-only
- `scale <n>`: set light scale (0.5 to 3, dot decimal only), otherwise print usage with the current value
- `demo`: toggle demo mode
- `why`, `trace`, `probe`, `auto`, `clear`: diagnostics (see diagnostics spec)
- anything else: print the command list

#### Scenario: Open window
- **WHEN** the player types `/ttl`
- **THEN** the options window toggles

#### Scenario: Invalid scale
- **WHEN** the player types `/ttl scale 5`
- **THEN** chat shows usage with the current scale and nothing changes

#### Scenario: Unknown command
- **WHEN** the player types `/ttl foo`
- **THEN** chat lists the available commands
