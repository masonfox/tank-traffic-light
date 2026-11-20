## MODIFIED Requirements

### Requirement: Readable threat status drives the light
When the player's threat status against the unit is readable, the addon SHALL classify from it: securely tanking is GREEN, tanking but about to lose aggro is YELLOW, and not tanking is RED, unless the mob is attacking someone outside the player's group or a co-tank, in which case it is GREY.

#### Scenario: Securely tanking
- **WHEN** the threat status reports the player is securely tanking the unit
- **THEN** the light is GREEN

#### Scenario: Aggro slipping
- **WHEN** the threat status reports the player is tanking but about to lose aggro
- **THEN** the light is YELLOW

#### Scenario: Mob is loose on the group
- **WHEN** the threat status reports the player is not tanking the unit
- **AND** the unit's target is a member of the player's group who is not a co-tank, or the unit has no target
- **THEN** the light is RED

#### Scenario: Mob is fighting a stranger
- **WHEN** the threat status reports the player is not tanking the unit
- **AND** the unit's target is readable and is not a member of the player's group
- **THEN** the light is GREY

#### Scenario: Mob is on a co-tank
- **WHEN** the threat status reports the player is not tanking the unit
- **AND** the unit's target is a co-tank
- **THEN** the light is GREY

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
- **AND** the unit is targeting a member of the player's group other than the player who is not a co-tank
- **THEN** the light is RED

#### Scenario: Fallback, mob targeting a co-tank
- **WHEN** the threat status is unreadable or absent
- **AND** the unit is targeting a co-tank
- **THEN** the light is GREY

#### Scenario: Fallback, mob targeting a stranger
- **WHEN** the threat status is unreadable or absent
- **AND** the unit's target is readable and is not a member of the player's group
- **THEN** the light is GREY

#### Scenario: Fallback, no usable target
- **WHEN** the threat status is unreadable or absent
- **AND** the unit has no target, or whether it has a target cannot be read
- **THEN** the unit gets no light

## ADDED Requirements

### Requirement: Co-tank definition
A unit SHALL count as a co-tank if it is a member of the player's group, is not the player or the player's pet, and either has the TANK role assigned or holds the raid main-tank assignment. If neither can be read, the unit SHALL NOT count as a co-tank (fail toward "loose").

#### Scenario: Other tank in a dungeon group
- **WHEN** a mob targets a party member whose assigned role is TANK
- **THEN** that party member counts as a co-tank

#### Scenario: Raid main tank without a role
- **WHEN** a mob targets a raid member with no role but with the main-tank raid assignment
- **THEN** that raid member counts as a co-tank

#### Scenario: Role unreadable
- **WHEN** a mob targets a group member whose role and main-tank assignment cannot be read
- **THEN** that member does not count as a co-tank and the mob is treated as loose

### Requirement: Grey light can be turned off
When the grey-light setting is off, every unit that would be classified GREY SHALL get no light instead. Its explanation SHALL still say why it was not shown.

#### Scenario: Grey off, mob fighting a stranger
- **WHEN** the grey-light setting is off
- **AND** a mob is in combat with a player outside the group
- **THEN** the mob gets no light

#### Scenario: Grey off, mob on co-tank
- **WHEN** the grey-light setting is off
- **AND** a mob is attacking a co-tank
- **THEN** the mob gets no light (not RED)
