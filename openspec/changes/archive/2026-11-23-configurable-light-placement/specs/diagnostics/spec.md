## MODIFIED Requirements

### Requirement: Light-change trace
Whenever a nameplate light's color changes, the addon SHALL save a trace entry with time, nameplate unit, unit name, a short GUID suffix, old and new state, and the classification reason. The options window's sample light SHALL NOT add trace entries. The trace log SHALL keep the most recent 300 entries. When trace-to-chat is on, each entry SHALL also be printed to chat. `/ttl trace` SHALL toggle trace-to-chat; entries are saved either way.

#### Scenario: Light turns red
- **WHEN** a light changes from GREEN to RED
- **THEN** a trace entry is saved with both states and the reason

#### Scenario: Trace to chat off
- **WHEN** trace-to-chat is off and a light changes color
- **THEN** the entry is saved but not printed

### Requirement: Explain visible lights
`/ttl why` SHALL print the current master-toggle, tank-only, and gating status, then one line per visible nameplate with its name, decided state, reason, and whether its plate and light exist and are shown, followed by the number of visible nameplates. Each printed line SHALL also be saved to the trace log, prefixed with `WHY`.

#### Scenario: Ask why
- **WHEN** the player types `/ttl why` with two hostile nameplates visible
- **THEN** chat shows a status line, one line for each nameplate, and "visible nameplates: 2"

## REMOVED Requirements

### Requirement: Demo mode
**Reason**: Replaced by the options window's preview (see `light-preview`), which shows placement and colors on a fully dressed sample nameplate without needing live mobs. Demo's sample mob list rows are dropped. The options window already keeps the list visible for positioning.
**Migration**: Open the options window (`/ttl`) to preview lights. `/ttl demo` is no longer a command and prints the command list like any unknown command.
