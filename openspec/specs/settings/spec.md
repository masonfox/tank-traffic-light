# settings Specification

## Purpose

Defines how the player configures Tank Traffic Light: persisted settings and their defaults, the options window, the entry in the game's AddOns menu, and the slash commands.

## Requirements

### Requirement: Persisted settings with defaults
Settings SHALL persist per account in the `TankTrafficLightDB` saved variable. On load, any missing setting SHALL be filled with its default (see "Default values"), and existing values SHALL be kept.

#### Scenario: New setting added in an update
- **WHEN** saved settings exist but lack a newly introduced setting
- **THEN** only that setting is filled with its default

#### Scenario: Upgrading to alerts
- **WHEN** a player with existing saved settings loads the version that adds alerts
- **THEN** their existing settings are unchanged and the grey light, Classic colors and all three alerts are on

### Requirement: Default values
The defaults SHALL be: lights on, tank-only off, pulse on, grey light on, grey opacity 0.45, colors Classic, placement left, alignment Middle, scale 1, gap 4, open world on, dungeons on, raids on, PvP off, slipping sound on, slipping sound choice Ping, healer sound on, healer sound choice Raid warning, healer flash on, trace-to-chat off, auto-probe off.

#### Scenario: First install
- **WHEN** the addon loads with no saved settings
- **THEN** every setting takes its default value

### Requirement: Settings from earlier versions are migrated
When saved settings have a top placement height from an earlier version and no gap, the gap SHALL take that height's value, and the old height SHALL no longer be stored. Mob list settings and the mob list position saved by an earlier version SHALL no longer be stored.

#### Scenario: Upgrading to the mob list
- **WHEN** a player whose saved settings include the mob list's show, minimize, lock and maximum rows settings and a dragged list position loads the version that removes the mob list
- **THEN** those settings and the position are no longer stored, and every other setting is unchanged

#### Scenario: Upgrading keeps the top height
- **WHEN** a player whose saved top placement height is 12 loads the version that adds the gap
- **THEN** the gap is 12, alignment is Middle, and their placement is unchanged

#### Scenario: Upgrading with the light on the side
- **WHEN** a player with placement Left and the default top height of 4 loads the version that adds the gap
- **THEN** the gap is 4 and the light sits where it did before

### Requirement: Reset all settings
Resetting SHALL restore every setting to its default, refresh all lights, update the options window, and confirm in chat. The probe and trace logs SHALL NOT be cleared by a reset.

#### Scenario: Player resets
- **WHEN** the player clicks "Reset all settings"
- **THEN** all settings return to defaults, lights refresh, and chat shows "settings reset"

#### Scenario: Reset moves the list back
- **WHEN** a player who had dragged the mob list in an earlier version resets
- **THEN** all settings return to defaults and no mob list panel appears

### Requirement: Options window
The addon SHALL provide a movable options window that stays on screen and closes with Escape, and that fits a UI 768 pixels tall at scale 1. Across its top it SHALL show the preview strip defined by the light-preview capability. Below the preview it SHALL contain, in order, the Traffic lights, Alerts, Show in and Diagnostics sections, then a "Reset all settings" button. Every control SHALL apply immediately and refresh the lights and the preview.

#### Scenario: Toggle a checkbox
- **WHEN** the player clicks a checkbox or its label
- **THEN** the setting is saved and lights refresh immediately

#### Scenario: No demo button
- **WHEN** the player opens the options window
- **THEN** there is no demo button; "Reset all settings" is the only button at the bottom

#### Scenario: Unlock the list from the window
- **WHEN** the player opens the options window
- **THEN** there is no "Mob list" section and no control to show, lock, minimize or size a mob list

#### Scenario: Lock the list from the window
- **WHEN** the options window is open out of combat
- **THEN** no mob list panel is shown on screen, and none appears when the window closes

#### Scenario: Minimize from the list updates the window
- **WHEN** the player clicks anywhere on screen while the options window is open
- **THEN** there is no mob list minimize button, and no window control changes except the one clicked

### Requirement: Traffic lights section of the options window
The options window's Traffic lights section SHALL contain: show lights; only when tank (or no role); pulse yellow; grey light on mobs that aren't yours; grey light opacity slider (0.1 to 1); colors button cycling Classic, Colorblind; placement button cycling Left, Right, Top, Bottom; alignment button cycling Left, Middle, Right; size slider (0.5 to 3); gap slider (0 to 60).

#### Scenario: Cycle placement
- **WHEN** the placement button shows "Top" and is clicked
- **THEN** placement becomes Bottom, the button reads "Bottom", and the preview light moves below the sample health bar

#### Scenario: Cycle placement wraps
- **WHEN** the placement button shows "Bottom" and is clicked
- **THEN** placement becomes Left and the button reads "Left"

#### Scenario: Cycle colors
- **WHEN** the colors button shows "Classic" and is clicked
- **THEN** the palette becomes Colorblind, the button reads "Colorblind", and visible lights and the preview light repaint

### Requirement: Alignment button follows placement
The options window's alignment button SHALL be disabled, while still showing the saved alignment, when placement is Left or Right, and enabled when placement is Top or Bottom.

#### Scenario: Alignment disabled on the sides
- **WHEN** placement changes from Top to Left
- **THEN** the alignment button is disabled and still shows the saved alignment

#### Scenario: Cycle alignment
- **WHEN** placement is Top and the alignment button shows "Middle" and is clicked
- **THEN** alignment becomes Right, the button reads "Right", and the lights move to the right end of their health bars

### Requirement: Alerts, Show in and Diagnostics sections of the options window
The options window SHALL contain these sections:
- **Alerts**: sound when aggro starts slipping, with a button cycling its sound; sound when a mob attacks a healer, with a button cycling its sound; flash the screen when a mob attacks a healer; a "Test alerts" button.
- **Show in**: open world; dungeons; raids; battlegrounds and arenas.
- **Diagnostics**: print every light change to chat; record an API probe 3 seconds into every pull.

#### Scenario: Test alerts from the window
- **WHEN** the player clicks "Test alerts"
- **THEN** both alert sounds play and the flash appears with sample text

### Requirement: AddOns menu entry
The addon SHALL register a "Tank Traffic Light" page in the game's AddOns options with a button that closes the game options and opens the options window. Registration failure SHALL NOT break the addon.

#### Scenario: Open from game options
- **WHEN** the player clicks "Open options" on the AddOns page
- **THEN** the game options close and the Tank Traffic Light window opens

### Requirement: Slash commands
`/ttl` and `/tanktrafficlight` SHALL accept the commands listed in this requirement and the slash command requirements that follow it (case-insensitive), confirm each change in chat, and update the options window if it is open. With no argument, or with `options` or `config`, they SHALL toggle the options window.

#### Scenario: Open window
- **WHEN** the player types `/ttl`
- **THEN** the options window toggles

### Requirement: Traffic light slash commands
These commands SHALL change the traffic light settings:
- `lights`: toggle showing traffic lights
- `tankonly`: toggle tank-only
- `pulse`: toggle pulsing the yellow light
- `grey` or `gray`: toggle the grey light on mobs that aren't yours
- `greyalpha <n>` or `grayalpha <n>`: set grey light opacity (0.1 to 1)
- `colors [classic|colorblind]`: set the palette; with no argument, cycle Classic, Colorblind like the window's button
- `scale <n>` or `size <n>`: set light size (0.5 to 3)

#### Scenario: Set colorblind palette
- **WHEN** the player types `/ttl colors colorblind`
- **THEN** the palette becomes Colorblind and visible lights repaint

#### Scenario: Invalid grey opacity
- **WHEN** the player types `/ttl greyalpha 2`
- **THEN** chat shows that grey light opacity must be a number from 0.1 to 1, with the current value, and nothing changes

#### Scenario: Invalid scale
- **WHEN** the player types `/ttl scale 5`
- **THEN** chat shows the shared size message with the current value and nothing changes

### Requirement: Placement slash commands
These commands SHALL change where the light sits:
- `side [left|right|top|bottom]`: set placement; with no argument, cycle Left, Right, Top, Bottom like the window's button
- `align [left|middle|right]`: set alignment for top and bottom placement; with no argument, cycle Left, Middle, Right like the window's button. It SHALL be accepted and saved whatever the placement.
- `gap <n>` or `height <n>`: set the gap between the light and the health bar (0 to 60)

#### Scenario: Set placement directly
- **WHEN** the player types `/ttl side top`
- **THEN** placement becomes Top and the lights move above the health bar

#### Scenario: Bottom placement by chat
- **WHEN** the player types `/ttl side bottom`
- **THEN** placement becomes Bottom and the lights move below the health bar

#### Scenario: Cycle placement by chat
- **WHEN** placement is Left and the player types `/ttl side`
- **THEN** placement becomes Right

#### Scenario: Invalid placement
- **WHEN** the player types `/ttl side middle`
- **THEN** placement is unchanged and chat lists the valid choices

#### Scenario: Set alignment
- **WHEN** the player types `/ttl align left`
- **THEN** alignment becomes Left and chat confirms with the window's label text

#### Scenario: Height alias
- **WHEN** the player types `/ttl height 10`
- **THEN** the gap becomes 10

### Requirement: Alert slash commands
`slipsound`, `healersound` and `flash` SHALL toggle each alert. `slipsoundname [ping|whisper|bell|alarm|readycheck|raidwarning]` and `healersoundname [...]` SHALL choose each alert's sound; with no argument they SHALL cycle like the window's button, and either way the new sound SHALL preview. `testalert` SHALL run the alert test.

#### Scenario: Toggle an alert
- **WHEN** the player types `/ttl flash`
- **THEN** the healer flash setting toggles and chat confirms with the window's label text

#### Scenario: Choose a sound by chat
- **WHEN** the player types `/ttl healersoundname bell`
- **THEN** the healer sound becomes Bell, Bell plays once, and chat confirms

### Requirement: Zone, diagnostics and reset slash commands
`world`, `dungeon`, `raid` and `pvp` SHALL toggle each zone filter. `trace`, `auto`, `why`, `probe` and `clear` SHALL run the diagnostics commands (see diagnostics spec). `reset` SHALL restore all settings to defaults, like the window's button.

#### Scenario: Reset from chat
- **WHEN** the player types `/ttl reset`
- **THEN** all settings return to defaults, lights refresh, and chat shows "settings reset"

### Requirement: Slash command help and queries
A numeric command with no argument SHALL print the setting's current value and valid range. Anything else, including `demo` and the former mob list commands `list`, `listmin`, `listlock` and `listrows`, SHALL print the command list, grouped like the options window.

#### Scenario: Query a numeric setting
- **WHEN** the player types `/ttl gap`
- **THEN** chat shows the current gap and its 0 to 60 range

#### Scenario: Minimize the list by chat
- **WHEN** the player types `/ttl listmin`
- **THEN** nothing changes and chat lists every available command

#### Scenario: Demo is gone
- **WHEN** the player types `/ttl demo`
- **THEN** nothing changes and chat lists every available command

#### Scenario: Mob list commands are gone
- **WHEN** the player types `/ttl list` or `/ttl listrows 5`
- **THEN** nothing changes and chat lists every available command

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

### Requirement: Numeric settings use sliders and shared validation
Numeric settings SHALL accept the same range from the options window and by slash command: grey light opacity 0.1 to 1, size 0.5 to 3, and gap 0 to 60.

By slash command, both a dot and a comma SHALL be accepted as the decimal separator. Invalid or out-of-range input SHALL leave the setting unchanged and print one shared message naming the setting, its valid range, and its current value.

#### Scenario: Comma decimal size by slash
- **WHEN** the player types `/ttl scale 1,5`
- **THEN** the light scale becomes 1.5

#### Scenario: Invalid gap
- **WHEN** the player types `/ttl gap 80`
- **THEN** chat shows that gap must be a number from 0 to 60, with the current value, and nothing changes

#### Scenario: Fractional row count
- **WHEN** the player types `/ttl listrows 4.5`
- **THEN** nothing changes and chat lists every available command, because maximum rows is no longer a setting

### Requirement: Numeric sliders in the options window
In the options window, each numeric setting SHALL be a slider limited to its range that shows the current value next to it. Sliders SHALL move in steps: grey light opacity 0.05, size 0.05, gap 1. A slider SHALL apply its value while being dragged, so the lights and preview follow it live. A value set by slash command that falls between steps SHALL be kept as entered and shown as entered next to the slider.

#### Scenario: Drag the gap slider
- **WHEN** placement is Top and the player drags the gap slider from 4 to 15
- **THEN** the light and the preview light move up as the slider moves, and the gap is 15 when the drag ends

#### Scenario: Slider shows the range limit
- **WHEN** the player drags the size slider past its right end
- **THEN** the size stops at 3

#### Scenario: Off-step value from chat
- **WHEN** the options window is open and the player types `/ttl scale 1.23`
- **THEN** the size is 1.23, and the size slider's value label shows 1.23
