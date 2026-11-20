## Purpose

Defines the sound and on-screen alerts that let a tank notice slipping aggro and mobs attacking healers without watching every nameplate.

## ADDED Requirements

### Requirement: Alerts follow light classification
Alerts SHALL fire only from real light classification during normal operation: when lights are running under the display-gating rules and demo mode is off. Alerts SHALL never raise a Lua error; if a sound, name, role or class cannot be read, that part of the alert SHALL be skipped or replaced with a generic version.

#### Scenario: Lights gated off
- **WHEN** lights are not running in the current zone
- **THEN** no alert fires

#### Scenario: Demo mode
- **WHEN** demo mode is cycling lights
- **THEN** no alert fires

### Requirement: Slipping sound
When the slipping-sound setting is on and a mob's light changes to YELLOW from any other state, the addon SHALL play the slipping sound. The slipping sound SHALL play at most once every 2 seconds, no matter how many mobs turn YELLOW.

#### Scenario: Mob starts slipping
- **WHEN** a GREEN mob turns YELLOW
- **THEN** the slipping sound plays once

#### Scenario: Several mobs slip together
- **WHEN** three mobs turn YELLOW within one second
- **THEN** the slipping sound plays once

#### Scenario: Setting off
- **WHEN** the slipping-sound setting is off and a mob turns YELLOW
- **THEN** no sound plays

### Requirement: Healer identification
A group member SHALL count as a healer if it is not the player or the player's pet, and either its assigned role is HEALER, or it has no assigned role (or the role cannot be read) and its class is Priest, Druid, Paladin or Shaman. A member with the TANK or DAMAGER role SHALL NOT count as a healer. If neither role nor class can be read, the member SHALL NOT count as a healer.

#### Scenario: Assigned healer
- **WHEN** a party member has the HEALER role
- **THEN** they count as a healer

#### Scenario: Unassigned priest in a raid
- **WHEN** a raid member has no role and is a Priest
- **THEN** they count as a healer

#### Scenario: Shaman queued as damage
- **WHEN** a party member is a Shaman with the DAMAGER role
- **THEN** they do not count as a healer

### Requirement: Mob-on-healer detection
A mob SHALL be "on a healer" when its light is RED and its current target is readable and counts as a healer. A mob-on-healer alert SHALL fire when a mob becomes on a healer, either because it changed to RED or because it switched its target to a healer. The same mob SHALL NOT trigger another mob-on-healer alert within 5 seconds, and the alert SHALL fire at most once every 1.5 seconds overall.

#### Scenario: Mob peels to the healer
- **WHEN** a GREEN mob turns RED while targeting the healer
- **THEN** a mob-on-healer alert fires

#### Scenario: Loose mob switches to healer
- **WHEN** a RED mob attacking a mage switches its target to the healer
- **THEN** a mob-on-healer alert fires

#### Scenario: Flicker
- **WHEN** a mob alternates between the player and the healer several times within 5 seconds
- **THEN** only one mob-on-healer alert fires for that mob in that window

#### Scenario: Mob on co-tank
- **WHEN** a mob attacks a co-tank who is also a Paladin with no role
- **THEN** no mob-on-healer alert fires, because the light is GREY, not RED

### Requirement: Mob-on-healer sound
When the healer-sound setting is on, each mob-on-healer alert SHALL play the healer sound, which SHALL be different from the slipping sound and more urgent.

#### Scenario: Healer sound
- **WHEN** a mob-on-healer alert fires with the healer-sound setting on
- **THEN** the healer sound plays

### Requirement: Mob-on-healer flash
When the healer-flash setting is on, each mob-on-healer alert SHALL briefly flash a red glow around the edges of the screen and show large center-screen text, which then fade out within about 2 seconds. The text SHALL read "<mob name> -> <healer name>" when both names can be read, and "Mob on your healer!" otherwise. The flash SHALL NOT block mouse clicks.

#### Scenario: Names readable
- **WHEN** a Skeleton starts attacking the healer Priestly and both names are readable
- **THEN** the screen edges flash red and the text "Skeleton -> Priestly" appears and fades

#### Scenario: Names secret
- **WHEN** a mob-on-healer alert fires and either name is unreadable
- **THEN** the text reads "Mob on your healer!"

#### Scenario: Clicking during a flash
- **WHEN** the flash is visible and the player clicks a nameplate under it
- **THEN** the click reaches the nameplate

### Requirement: Alert test
The "Test alerts" action SHALL play the slipping sound, then the healer sound, and show the flash with sample text, ignoring the alert settings, throttles and gating, in or out of combat.

#### Scenario: Test from chat
- **WHEN** the player types `/ttl testalert` with all alert settings off
- **THEN** both sounds play and the flash appears with sample text
