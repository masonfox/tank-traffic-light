## Why

The options window and `/ttl` have drifted apart. Only some window options have slash commands, the same setting is parsed differently in each place (`1,5` works in the window but not in `/ttl scale`), and the two use different wording for the same setting. We decided the options window is the source of truth and slash commands should mirror it exactly (baseline proposal, quirk 2).

## What Changes

- Every option in the options window gets a slash command, including the ones missing today: pulse, placement, top height, the four zone filters, and reset.
- Numeric input is parsed and validated once, the same way for both: comma or dot decimals, the same ranges, and the same error message.
- Slash confirmations use the window's label text, so a setting reads the same in chat as in the window.
- `/ttl` help lists every command, grouped like the window's sections.
- `/ttl size` is added as an alias of `/ttl scale`, matching the window's "Size" label.
- Existing command names keep working. Only the wording of their chat confirmations changes.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `settings`: The slash command list grows to cover every window option. Numeric validation and messages are shared by both surfaces. A new requirement states that the window and slash commands must stay in parity.

## Impact

- Code: `Core.lua` (slash handler), `Options.lua` (checkbox, placement, numeric fields), and a new shared settings definition used by both.
- No saved-variable changes; existing `TankTrafficLightDB` values keep working.
- Players who parse chat output from `/ttl` will see different confirmation wording.
