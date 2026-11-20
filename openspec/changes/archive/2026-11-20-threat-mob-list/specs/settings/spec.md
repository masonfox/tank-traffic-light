## MODIFIED Requirements

### Requirement: Persisted settings with defaults
Settings SHALL persist per account in the `TankTrafficLightDB` saved variable. On load, any missing setting SHALL be filled with its default, and existing values SHALL be kept. Defaults: lights on, tank-only off, pulse on, grey light on, grey opacity 0.45, colors Classic, placement left, scale 1, top offset 4, mob list on, mob list minimized off, mob list locked on, mob list maximum rows 8, open world on, dungeons on, raids on, PvP off, slipping sound on, slipping sound choice Ping, healer sound on, healer sound choice Raid warning, healer flash on, trace-to-chat off, auto-probe off. The mob list's position SHALL also persist; with no saved position, the list SHALL appear at its default position on the left side of the screen.

#### Scenario: First install
- **WHEN** the addon loads with no saved settings
- **THEN** every setting takes its default value

#### Scenario: New setting added in an update
- **WHEN** saved settings exist but lack a newly introduced setting
- **THEN** only that setting is filled with its default

#### Scenario: Upgrading to alerts
- **WHEN** a player with existing saved settings loads the version that adds alerts
- **THEN** their existing settings are unchanged and the grey light, Classic colors and all three alerts are on

#### Scenario: Upgrading to the mob list
- **WHEN** a player with existing saved settings loads the version that adds the mob list
- **THEN** their existing settings are unchanged, and the mob list is on, expanded, locked, capped at 8 rows, and at its default position

### Requirement: Reset all settings
Resetting SHALL restore every setting to its default, return the mob list to its default position, refresh all lights and the mob list, update the options window, and confirm in chat. The probe and trace logs SHALL NOT be cleared by a reset.

#### Scenario: Player resets
- **WHEN** the player clicks "Reset all settings"
- **THEN** all settings return to defaults, lights refresh, and chat shows "settings reset"

#### Scenario: Reset moves the list back
- **WHEN** the mob list has been dragged elsewhere and the player resets
- **THEN** the mob list returns to its default position, expanded and locked

### Requirement: Options window
The addon SHALL provide a movable options window that stays on screen and closes with Escape, and that fits a UI 768 pixels tall at scale 1. It SHALL contain:
- **Traffic lights**: show lights; only when tank (or no role); pulse yellow; grey light on mobs that aren't yours; grey light opacity field (0.1 to 1); colors button cycling Classic, Colorblind; placement button cycling Left, Right, Top; size field (0.5 to 3); top placement height field (0 to 60).
- **Mob list**: show the mob list; minimize the mob list; lock the mob list; maximum rows field (3 to 20).
- **Alerts**: sound when aggro starts slipping, with a button cycling its sound; sound when a mob attacks a healer, with a button cycling its sound; flash the screen when a mob attacks a healer; a "Test alerts" button.
- **Show in**: open world; dungeons; raids; battlegrounds and arenas.
- **Diagnostics**: print every light change to chat; record an API probe 3 seconds into every pull.
- Buttons: demo toggle ("Demo: cycle colors" / "Stop demo") and "Reset all settings".

Every control SHALL apply immediately and refresh the lights and the mob list.

#### Scenario: Toggle a checkbox
- **WHEN** the player clicks a checkbox or its label
- **THEN** the setting is saved and lights refresh immediately

#### Scenario: Cycle placement
- **WHEN** the placement button shows "Left" and is clicked
- **THEN** placement becomes Right and the button reads "Right"

#### Scenario: Cycle colors
- **WHEN** the colors button shows "Classic" and is clicked
- **THEN** the palette becomes Colorblind, the button reads "Colorblind", and visible lights repaint

#### Scenario: Test alerts from the window
- **WHEN** the player clicks "Test alerts"
- **THEN** both alert sounds play and the flash appears with sample text

#### Scenario: Unlock the list from the window
- **WHEN** the player unchecks "Lock the mob list"
- **THEN** the mob list appears, even out of combat, and can be dragged

#### Scenario: Lock the list from the window
- **WHEN** the player checks "Lock the mob list" out of combat
- **THEN** the mob list stays visible in place, can no longer be dragged, and hides when the options window closes

#### Scenario: Minimize from the list updates the window
- **WHEN** the options window is open and the player clicks the mob list's minimize button
- **THEN** the "Minimize the mob list" checkbox becomes checked

### Requirement: Numeric fields validate input
Numeric settings SHALL be parsed and validated the same way whether entered in the options window or by slash command. Both a dot and a comma SHALL be accepted as the decimal separator. Size SHALL accept 0.5 to 3, top placement height SHALL accept 0 to 60, and mob list maximum rows SHALL accept whole numbers from 3 to 20. Invalid or out-of-range input SHALL leave the setting unchanged and print one shared message naming the setting, its valid range, and its current value. In the window, fields SHALL apply on Enter or when focus is lost, Escape SHALL cancel the edit, and the field SHALL show the current value again after any rejected or cancelled edit.

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

#### Scenario: Fractional row count
- **WHEN** the player types `/ttl listrows 4.5`
- **THEN** chat shows that maximum rows must be a whole number from 3 to 20, with the current value, and nothing changes

### Requirement: Slash commands
`/ttl` and `/tanktrafficlight` SHALL accept these commands (case-insensitive), confirm each change in chat, and update the options window if it is open:
- no argument, `options`, `config`: toggle the options window
- Traffic lights:
  - `lights`: toggle showing traffic lights
  - `tankonly`: toggle tank-only
  - `pulse`: toggle pulsing the yellow light
  - `grey` or `gray`: toggle the grey light on mobs that aren't yours
  - `greyalpha <n>` or `grayalpha <n>`: set grey light opacity (0.1 to 1)
  - `colors [classic|colorblind]`: set the palette; with no argument, cycle Classic, Colorblind like the window's button
  - `side [left|right|top]`: set placement; with no argument, cycle Left, Right, Top like the window's button
  - `scale <n>` or `size <n>`: set light size (0.5 to 3)
  - `height <n>`: set top placement height (0 to 60)
- Mob list: `list`: toggle showing the mob list; `listmin`: toggle minimizing it; `listlock`: toggle locking it; `listrows <n>`: set the maximum rows (3 to 20)
- Alerts: `slipsound`, `healersound`, `flash`: toggle each alert; `slipsoundname [ping|whisper|bell|alarm|readycheck|raidwarning]` and `healersoundname [...]`: choose each alert's sound (with no argument, cycle like the window's button; either way the new sound previews); `testalert`: run the alert test
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

#### Scenario: Set colorblind palette
- **WHEN** the player types `/ttl colors colorblind`
- **THEN** the palette becomes Colorblind and visible lights repaint

#### Scenario: Toggle an alert
- **WHEN** the player types `/ttl flash`
- **THEN** the healer flash setting toggles and chat confirms with the window's label text

#### Scenario: Choose a sound by chat
- **WHEN** the player types `/ttl healersoundname bell`
- **THEN** the healer sound becomes Bell, Bell plays once, and chat confirms

#### Scenario: Invalid grey opacity
- **WHEN** the player types `/ttl greyalpha 2`
- **THEN** chat shows that grey light opacity must be a number from 0.1 to 1, with the current value, and nothing changes

#### Scenario: Invalid scale
- **WHEN** the player types `/ttl scale 5`
- **THEN** chat shows the shared size message with the current value and nothing changes

#### Scenario: Query a numeric setting
- **WHEN** the player types `/ttl height`
- **THEN** chat shows the current top placement height and its 0 to 60 range

#### Scenario: Minimize the list by chat
- **WHEN** the mob list is expanded and the player types `/ttl listmin`
- **THEN** the list collapses to its header and chat confirms with the window's label text

#### Scenario: Reset from chat
- **WHEN** the player types `/ttl reset`
- **THEN** all settings return to defaults, lights refresh, and chat shows "settings reset"

#### Scenario: Unknown command
- **WHEN** the player types `/ttl foo`
- **THEN** chat lists every available command
