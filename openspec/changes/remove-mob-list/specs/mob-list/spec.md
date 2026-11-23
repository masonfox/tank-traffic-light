# Spec Delta

## REMOVED Requirements

### Requirement: List follows light classification
**Reason**: The mob list is removed. The nameplate lights show the same classification on the mob itself.
**Migration**: Read each mob's state from its nameplate light.

### Requirement: List works without the lights
**Reason**: The mob list is removed, so nothing needs classification while the lights are off.
**Migration**: Turn the lights on to see classification. With the lights off, nothing is classified and no alert fires.

### Requirement: Row content
**Reason**: The mob list is removed. Its "-> <target>" text for loose mobs is not kept anywhere else.
**Migration**: A red light marks a loose mob. The healer alert names the case where the target matters most.

### Requirement: Row order
**Reason**: The mob list is removed.
**Migration**: None.

### Requirement: Row cap
**Reason**: The mob list is removed, along with the maximum rows setting.
**Migration**: None. `/ttl listrows` now prints the command list.

### Requirement: Header counts
**Reason**: The mob list is removed.
**Migration**: None.

### Requirement: Minimize
**Reason**: The mob list is removed, along with the minimize setting.
**Migration**: None. `/ttl listmin` now prints the command list.

### Requirement: Display-only
**Reason**: The mob list is removed.
**Migration**: None.

### Requirement: Lock and move
**Reason**: The mob list is removed, along with the lock setting and saved position.
**Migration**: None. `/ttl listlock` now prints the command list.

### Requirement: When the list is shown
**Reason**: The mob list is removed, along with its show setting.
**Migration**: None. `/ttl list` now prints the command list.

### Requirement: Refresh
**Reason**: The mob list is removed.
**Migration**: None.
