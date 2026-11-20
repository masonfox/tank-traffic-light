## MODIFIED Requirements

### Requirement: Persisted settings with defaults
Settings SHALL persist per account in the `TankTrafficLightDB` saved variable. On load, any missing setting SHALL be filled with its default, and existing values SHALL be kept. Defaults: lights on, tank-only off, pulse on, grey light on, colors Classic, placement left, scale 1, top offset 4, open world on, dungeons on, raids on, PvP off, slipping sound on, healer sound on, healer flash on, trace-to-chat off, auto-probe off.

#### Scenario: First install
- **WHEN** the addon loads with no saved settings
- **THEN** every setting takes its default value

#### Scenario: New setting added in an update
- **WHEN** saved settings exist but lack a newly introduced setting
- **THEN** only that setting is filled with its default

#### Scenario: Upgrading to alerts
- **WHEN** a player with existing saved settings loads the version that adds alerts
- **THEN** their existing settings are unchanged and the grey light, Classic colors and all three alerts are on

### Requirement: Options window
The addon SHALL provide a movable options window that stays on screen and closes with Escape. It SHALL contain:
- **Traffic lights**: show lights; only when tank (or no role); pulse yellow; grey light on mobs that aren't yours; colors button cycling Classic, Colorblind; placement button cycling Left, Right, Top; size field (0.5 to 3); top placement height field (0 to 60).
- **Alerts**: sound when aggro starts slipping; sound when a mob attacks a healer; flash the screen when a mob attacks a healer; a "Test alerts" button.
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

#### Scenario: Cycle colors
- **WHEN** the colors button shows "Classic" and is clicked
- **THEN** the palette becomes Colorblind, the button reads "Colorblind", and visible lights repaint

#### Scenario: Test alerts from the window
- **WHEN** the player clicks "Test alerts"
- **THEN** both alert sounds play and the flash appears with sample text

### Requirement: Slash commands
`/ttl` and `/tanktrafficlight` SHALL accept these commands (case-insensitive), confirm each change in chat, and update the options window if it is open:
- no argument, `options`, `config`: toggle the options window
- Traffic lights:
  - `lights`: toggle showing traffic lights
  - `tankonly`: toggle tank-only
  - `pulse`: toggle pulsing the yellow light
  - `grey` or `gray`: toggle the grey light on mobs that aren't yours
  - `colors [classic|colorblind]`: set the palette; with no argument, cycle Classic, Colorblind like the window's button
  - `side [left|right|top]`: set placement; with no argument, cycle Left, Right, Top like the window's button
  - `scale <n>` or `size <n>`: set light size (0.5 to 3)
  - `height <n>`: set top placement height (0 to 60)
- Alerts: `slipsound`, `healersound`, `flash`: toggle each alert; `testalert`: run the alert test
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
