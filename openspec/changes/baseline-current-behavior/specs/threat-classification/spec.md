## Purpose

Defines how the addon decides, for each hostile nameplate unit, whether it is securely on the player (GREEN), slipping off the player (YELLOW), loose on the player's group (RED), or not the player's concern (no light).

## ADDED Requirements

### Requirement: Only attackable units in combat are classified
A unit SHALL get no light unless the player can attack it and the unit is readably in combat.

#### Scenario: Unit is not attackable
- **WHEN** the player cannot attack the unit, or that cannot be read
- **THEN** the unit gets no light

#### Scenario: Unit is not in combat
- **WHEN** the unit is attackable but not in combat
- **THEN** the unit gets no light

#### Scenario: Unit combat state is secret
- **WHEN** the unit's combat state cannot be read
- **THEN** the unit gets no light

### Requirement: Readable threat status drives the light
When the player's threat status against the unit is readable, the addon SHALL classify from it: securely tanking is GREEN, tanking but about to lose aggro is YELLOW, and not tanking is RED unless the mob is attacking someone outside the player's group.

#### Scenario: Securely tanking
- **WHEN** the threat status reports the player is securely tanking the unit
- **THEN** the light is GREEN

#### Scenario: Aggro slipping
- **WHEN** the threat status reports the player is tanking but about to lose aggro
- **THEN** the light is YELLOW

#### Scenario: Mob is loose on the group
- **WHEN** the threat status reports the player is not tanking the unit
- **AND** the unit's target is a member of the player's group, or the unit has no target
- **THEN** the light is RED

#### Scenario: Mob is fighting a stranger
- **WHEN** the threat status reports the player is not tanking the unit
- **AND** the unit's target is readable and is not a member of the player's group
- **THEN** the unit gets no light

#### Scenario: Mob's target cannot be read
- **WHEN** the threat status reports the player is not tanking the unit
- **AND** whether the unit has a target cannot be read
- **THEN** the light is RED (fail toward "loose")

### Requirement: Target-based fallback
When the threat status is unreadable, or the player is not on the unit's threat list, the addon SHALL classify from the unit's current target. The fallback SHALL NOT produce YELLOW, because slipping cannot be detected without a threat status.

#### Scenario: Fallback, mob targeting the player
- **WHEN** the threat status is unreadable or absent
- **AND** the unit is targeting the player
- **THEN** the light is GREEN

#### Scenario: Fallback, mob targeting a group member
- **WHEN** the threat status is unreadable or absent
- **AND** the unit is targeting a member of the player's group other than the player
- **THEN** the light is RED

#### Scenario: Fallback, no usable target
- **WHEN** the threat status is unreadable or absent
- **AND** the unit has no target, its target cannot be read, or its target is outside the group
- **THEN** the unit gets no light

### Requirement: Group membership definition
A unit SHALL count as a member of the player's group if it is the player, the player's pet, a party member, or a raid member. Membership checks that cannot be read SHALL count as "not a member".

#### Scenario: Target is the player's pet
- **WHEN** a mob is targeting the player's pet
- **THEN** the pet counts as a group member for classification

#### Scenario: Target is a raid member
- **WHEN** a mob is targeting a player in the same raid
- **THEN** that player counts as a group member

### Requirement: Every classification has an explanation
Each classification SHALL produce a human-readable reason that includes the threat status (or `SECRET`) and the target's name, plus a note on which path decided it (for example: fallback, no target, target not in group).

#### Scenario: Explaining a fallback decision
- **WHEN** a unit is classified through the fallback path
- **THEN** its reason is marked as a fallback decision
