## Context

See proposal.md for motivation and specs/ for the required behavior.

Today `Lights.lua` builds a light per nameplate (`CreateLight`), sets its orientation (`Layout(f, horizontal)`), and anchors it inside `Attach` with three hard-coded branches (top uses `topOffset`; left and right use a fixed 4px). Demo state lives in `Lights.lua` (`demoMode`, `demoStep`, `DEMO_ORDER`, OnUpdate cycling) and `MobList.lua` (`DEMO_ROWS`, `SetDemo`), with entry points in `Options.lua` (button) and `Core.lua` (`/ttl demo`).

`Options.lua` is a hand-built two-column window, 532px tall, sized to fit a 768px UI. Every setting goes through `Settings.Set`, which saves the value and calls `TT.Lights.UpdateAll`, `TT.MobList.Refresh` and `TT.RefreshOptions`.

## Goals / Non-Goals

**Goals:**
- One placement code path shared by real nameplate lights and the preview light, so the two can't drift apart.
- A preview that shows what usually crowds a nameplate (auras above, cast bar below), so placement choices can be judged in the window.
- Live feedback while dragging sliders.

**Non-Goals:**
- Pixel-exact imitation of Plater or Blizzard nameplates. The preview is a generic, representative plate.
- Vertical alignment for left/right placement, or separate gaps per side.
- Sample rows in the mob list (dropped with demo).
- A sliders-everywhere settings framework. Only the four numeric settings get sliders.

## Decisions

### 1. Pull light construction and placement out of `Attach`
`Lights.lua` exposes:
- `L.NewLight(parent)`: the current `CreateLight` body (housing, masked lamps, pulse animation).
- `L.Place(f, bar)`: reads `side`, `align`, `gap`, `lightScale` from `TankTrafficLightDB`, runs `Layout`, and anchors `f` to `bar`.
- `L.Paint(f, state)`: the existing `Paint`. It already handles the palette, pulse and grey opacity.

`Attach` becomes `L.Place(f, AnchorTarget(plate))`. The preview calls the same three functions on its own frames.
*Alternative:* duplicating the anchor logic in the preview. Rejected because it would drift the first time placement changes.

### 2. Placement as a lookup table, not branches
```
side    light point          bar point            x       y
top     BOTTOM{A}            TOP{A}               0      +gap
bottom  TOP{A}               BOTTOM{A}            0      -gap
left    RIGHT                LEFT                -gap     0
right   LEFT                 RIGHT               +gap     0
        {A} = "LEFT" | "" | "RIGHT"  for align = left | middle | right
```
`Layout(f, side == "top" or side == "bottom")`. Flush alignment (`BOTTOMLEFT` to `TOPLEFT`) means a left-aligned light starts exactly at the bar's left edge.

### 3. Settings keys and migration
- `side`: values `left, right, top, bottom`, labels Left/Right/Top/Bottom. Cycle order follows the values list.
- `align`: new choice, values `left, middle, right`, default `middle`, slash `align`.
- `gap`: new number, 0 to 60, default 4, slash `{ "gap", "height" }`. It replaces the `topOffset` entry.
- Migration in `Core.lua` runs **before** `ApplyDefaults`. Otherwise `ApplyDefaults` fills `gap = 4` first and the old height is lost: `if db.gap == nil and db.topOffset ~= nil then db.gap = db.topOffset end; db.topOffset = nil`.
- Players on left or right placement have the default `topOffset` of 4, which equals the old fixed 4px side gap, so their lights don't move.

### 4. Preview lives in its own file
Add `Preview.lua`, loaded after `Lights.lua` and before `Options.lua` in the .toc. It exposes `TT.Preview.Create(parent)` and `TT.Preview.Refresh()`.
- Builds a fake plate from textures and font strings: a health bar of about 120x10 at roughly 70% fill, name and level text, a raid marker (skull) above the name, a row of 4 to 5 aura icons (buffs and debuffs, fixed icon paths with debuff-coloured borders) just above the bar, and a cast bar with a spell name just below the bar. The layout roughly matches a default Blizzard enemy plate, so the top and bottom overlaps are realistic.
- The whole sample plate sits in a container with a fixed zoom (about 1.5x), so it's readable while relative geometry stays true. The light's own `lightScale` still applies on top.
- One light from `L.NewLight(container)`, placed with `L.Place(light, sampleBar)`.
- Cycling runs from an OnUpdate on the preview frame. A hidden frame gets no OnUpdate, so closing the window stops it with no extra bookkeeping. The order is RED, YELLOW, GREEN, then GREY if `showGrey` is on.
- It never touches `lights[]`, the trace, alerts, or the mob list, because it doesn't go through `Evaluate`/`Apply`.
- `TT.RefreshOptions()` calls `TT.Preview.Refresh()`. That is enough, since `Settings.Set` already calls `RefreshOptions` after every change from either surface.

### 5. Window layout (option B: preview strip on top)
```
+------------------------------------------------------------+
|                    Tank Traffic Light                      |
|  +------------------------------------------------------+  |
|  |               PREVIEW (sample nameplate)             |  |  ~140px
|  +------------------------------------------------------+  |
|  +-- Traffic lights -------+   +-- Alerts --------------+  |
|  | 4 checkboxes            |   |                        |  |
|  | Grey opacity  [====o==] |   +------------------------+  |
|  | Colors        [Classic] |   +-- Show in -------------+  |
|  | Placement     [Top    ] |   |                        |  |
|  | Alignment     [Middle ] |   +------------------------+  |
|  | Size          [==o====] |   +-- Diagnostics ---------+  |
|  | Gap           [o======] |   +------------------------+  |
|  +-------------------------+                               |
|  +-- Mob list -------------+                               |
|  | 3 checkboxes, Rows [==o]|                               |
|  +-------------------------+                               |
|                  [ Reset all settings ]                    |
+------------------------------------------------------------+
```
Height budget: 532 now, +about 140 for the preview strip, +26 for the alignment row, and the demo button's slot goes to the single reset button. That gives about 700px, which still fits a 768px UI at scale 1. Sliders sit on the same row as their label (label left, slider and value at the right of the box), so slider rows keep the current 26 to 28px pitch.
*Alternatives:* a third column (about 1140px wide) or tabs (a rewrite of `Options.lua`). Option B was chosen by the user.

### 6. Slider widget
`NewSlider(parent, entry, step)` in `Options.lua`: `CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")` when that template exists, otherwise a bare `Slider` with a thumb texture. Template text regions (Low/High/Text) are hidden or reused. A font string to the right shows the value.
- `OnValueChanged(self, v, userInput)`: ignore it while `widgets.refreshing` is set. Otherwise round to the step's precision, so 0.45 doesn't become 0.45000001, then `SettingsRegistry.Set(key, v)`. The value goes through the same `ParseNumber` path as slash input, which keeps one validation path.
- `Refresh`: set `refreshing`, `SetValue(db[key])`, and set the value label from `db[key]` (not the snapped slider value), so an off-step slash value like 1.23 shows as entered. Then clear `refreshing`.
- This guard is needed because `Set` calls `RefreshOptions`, which calls `SetValue`. Without it, every drag tick would re-enter `Set`.
- Steps: grey opacity 0.05, size 0.05, gap 1, rows 1.

### 7. Alignment button enablement
In `RefreshOptions`: `widgets.align:SetEnabled(side == "top" or side == "bottom")`. The label stays the saved alignment.

### 8. Demo removal
Delete `demoMode`, `demoStep`, `DEMO_ORDER`, `L.SetDemo` and `L.IsDemo` from `Lights.lua`, and the demo branches in evaluation, `why` output and OnUpdate. Out-of-combat OnUpdate then does nothing. Delete `DEMO_ROWS`, `demo` and `M.SetDemo` from `MobList.lua`, and the `demo` term in its show condition. Delete `/ttl demo` and its help text from `Core.lua`, the demo button from `Options.lua`, and the README row. `/ttl demo` then falls through to the unknown-command help.

## Risks / Trade-offs

- [The preview differs from the player's real plates (Plater layouts, custom aura positions, nameplate scale)] → The preview is described as representative. The placement code is shared, so offsets relative to the bar are exact even if the surrounding decorations differ.
- [About 700px leaves little margin on 768px UIs, and the Blizzard header texture sits above the frame] → Confirm in-game at UI scale 1 on a 768-tall resolution. If it's tight, shrink the preview strip (about 110px) or the box padding before changing the layout.
- [`OptionsSliderTemplate` is missing or different on the WoW Forever client] → Fall back to a manually built slider. Test both paths by forcing the fallback once.
- [`UpdateAll` on every slider tick is costly with many plates] → `UpdateAll` already runs four times a second in combat. Drag ticks are similar or fewer. Add a per-frame coalesce only if it stutters in testing.
- [Removing demo breaks players' muscle memory for `/ttl demo`] → It prints the full command list, which includes `/ttl` to open the window, and the README notes the change.
- [Migration order bug: if `ApplyDefaults` runs first, the top height is lost] → Migration explicitly runs before `ApplyDefaults`. The spec scenario "Upgrading keeps the top height" covers it.

## Migration Plan

- Load-time migration as in Decision 3. It is idempotent: once `topOffset` is cleared, it does nothing.
- Rollback: an older version would see no `topOffset` and fall back to its default of 4. The worst case is a top light moving back to 4px, which is acceptable.

## Open Questions

- The exact aura icons, spell name, and sample mob name/level in the preview. These are cosmetic and can be chosen during implementation.
