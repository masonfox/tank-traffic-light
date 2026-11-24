## Why

Placement is only half configurable. The light can go left, right or top, but only the top position can move away from the health bar, it is always centred, and there is no bottom option. Tanks whose nameplates show auras or cast bars can't keep the light clear of them. The only way to see a change is demo mode, which needs live nameplates on screen and gives no idea of what will sit around the light in a real pull.

## What Changes

- Add a **bottom** placement, so the light can go left, right, top or bottom of the health bar. Top and bottom lay the light out horizontally. Left and right stand it up vertically.
- Add an **alignment** setting (Left / Middle / Right) that controls where a top or bottom light sits along the health bar. It has no effect for left or right placement.
- Replace the top-only height with a **gap** setting (0 to 60) that sets the distance from the health bar for every placement. Saved top heights carry over to the gap.
- Add a **preview strip** across the top of the options window. It shows a sample nameplate with a name, level, raid marker, buffs and debuffs above the bar, and a cast bar below it. A sample light uses the current settings and cycles through its colours, so every placement, size, palette, pulse and opacity change is visible as it is made.
- Show numeric settings in the options window as **sliders**, which apply live while dragging. Slash commands keep their existing number parsing and validation.
- **BREAKING**: Remove demo mode. This removes the "Demo: cycle colors" button, `/ttl demo`, the demo light cycling on real nameplates, the mob list's sample rows, and demo's gating and alert exceptions. The preview replaces it.
- New slash commands: `side [left|right|top|bottom]`, `align [left|middle|right]`, `gap <n>`. `height <n>` stays as an alias for `gap`.

## Capabilities

### New Capabilities
- `light-preview`: the sample nameplate and sample light shown in the options window, and how they follow the settings.

### Modified Capabilities
- `nameplate-lights`: placement gains bottom, alignment and a gap that applies to every side. Demo is removed from the periodic-refresh requirement.
- `settings`: new defaults (alignment, gap) and migration from the top offset. The options window layout changes (preview strip, sliders, alignment control, no demo button). Slash commands change (`side` gains bottom, `align` and `gap` are added, `demo` is removed). Numeric controls in the window become sliders.
- `diagnostics`: demo mode is removed. Trace and `/ttl why` no longer mention demo.
- `display-gating`: the master toggle loses its demo exception, and "Demo mode bypasses gating" is removed.
- `alerts`: the demo-mode exception is removed from "Alerts follow light classification".
- `mob-list`: demo mode no longer shows the list or fills it with sample rows.

## Impact

- `Lights.lua`: placement and layout are pulled out of `Attach` so the live lights and the preview use the same code. Bottom and alignment are added. The demo state and cycling are removed.
- `Options.lua`: the window gets taller (about 700px, still within a 768px UI) with a preview strip on top, a slider widget, an alignment control that is disabled for left and right, and no demo button.
- `Settings.lua`: new `align` and `gap` entries, `side` gains bottom, and the `topOffset` entry is replaced.
- `Core.lua`: new defaults and a one-time `topOffset` to `gap` migration. `/ttl demo` and its help text are removed.
- `MobList.lua`: `DEMO_ROWS` and `SetDemo` are removed.
- `README.md`: placement docs are updated and the demo command is removed.
