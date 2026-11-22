## 1. Shared light placement (Lights.lua)

- [x] 1.1 Rename `CreateLight` to `L.NewLight(parent)` and expose the existing `Paint` as `L.Paint(f, state)`; verify by grep that no caller still uses the old local names and that `NewLight` builds housing, lamps and pulse exactly as before
- [x] 1.2 Add `L.Place(f, bar)` driven by the Decision 2 lookup table (side top/bottom/left/right, align left/middle/right, `gap`, `lightScale`), calling `Layout(f, side == "top" or side == "bottom")`; verify by reading the table against every Placement scenario in specs/nameplate-lights (top/middle/10, bottom/left/2, top/right, left/4, right/20, align ignored on sides)
- [x] 1.3 Make `Attach` call `L.Place(f, AnchorTarget(plate))` and remove the hard-coded side branches and `topOffset` read; verify `grep -n topOffset Lights.lua` returns nothing

## 2. Demo removal (Lights.lua, MobList.lua)

- [x] 2.1 Remove `demoMode`, `demoStep`, `DEMO_ORDER`, `L.SetDemo`, `L.IsDemo`, the demo branches in evaluation, the `demo=` part of the `why` status line, and demo cycling in OnUpdate, so out-of-combat OnUpdate does nothing; verify `grep -in demo Lights.lua` returns nothing
- [x] 2.2 Remove `demo`, `DEMO_ROWS`, `M.SetDemo` and the `demo` term in the list's show condition from MobList.lua; verify `grep -in demo MobList.lua` returns nothing and the show condition matches specs/mob-list "When the list is shown"

## 3. Settings, defaults and slash commands (Settings.lua, Core.lua)

- [x] 3.1 Extend the `side` entry to values `left, right, top, bottom` (labels Left/Right/Top/Bottom) and add an `align` choice entry (`left, middle, right`, default `middle`, slash `align`); verify by reading that `/ttl side` cycles Left→Right→Top→Bottom→Left and `/ttl side middle` lists the valid choices
- [x] 3.2 Replace the `topOffset` entry with a `gap` number entry (0 to 60, slash `{ "gap", "height" }`, label "Gap"); verify `grep -n topOffset Settings.lua` returns nothing and the range message matches the "Invalid gap" scenario
- [x] 3.3 In Core.lua add defaults `align = "middle"`, `gap = 4`, drop `topOffset`, and add the `topOffset`→`gap` migration that runs before `ApplyDefaults`; verify by reading the load order against the "Upgrading keeps the top height" and "Upgrading with the light on the side" scenarios
- [x] 3.4 Remove `/ttl demo` and `demo` from the help text in Core.lua, and make sure help lists `side`, `align` and `gap`; verify `grep -in demo Core.lua` returns nothing and `/ttl demo` falls through to the command list

## 4. Preview (Preview.lua, .toc)

- [x] 4.1 Create Preview.lua with `TT.Preview.Create(parent)` building a sample plate in a ~1.5x zoomed container: health bar ~120x10 at ~70% fill, name, level, skull raid marker above the name, 4–5 buff/debuff icons just above the bar, and a cast bar with spell name just below it; verify it uses no unit/nameplate APIs (grep for `UnitGUID`, `C_NamePlate`, `GetNamePlate` returns nothing)
- [x] 4.2 Add one sample light from `TT.Lights.NewLight(container)` placed with `TT.Lights.Place(light, sampleBar)`, and `TT.Preview.Refresh()` that re-places and repaints it; verify it never calls `Evaluate`, `Apply`, trace, alerts or MobList
- [x] 4.3 Add an OnUpdate on the preview frame cycling RED, YELLOW, GREEN, then GREY only when `showGrey` is on, one step per second, painted via `TT.Lights.Paint`; verify by reading that it ignores the master toggle and gating and that it stops when the frame is hidden
- [x] 4.4 Add Preview.lua to TankTrafficLight.toc after Lights.lua and before Options.lua; verify by reading the .toc

## 5. Options window (Options.lua)

- [x] 5.1 Add `NewSlider(parent, entry, step)` using `OptionsSliderTemplate` when present with a manual fallback, value label to the right, `widgets.refreshing` guard, step rounding, and `SettingsRegistry.Set` on change; verify by reading against design Decision 6
- [x] 5.2 Replace the numeric edit boxes with sliders for grey opacity (0.05), size (0.05), gap (1) and max rows (1), and show `db[key]` in the value label on refresh; verify `grep -n NewEditBox Options.lua` shows no remaining numeric edit box use
- [x] 5.3 Add the alignment cycle button under placement and enable it only for top/bottom in `RefreshOptions`; verify by reading against the "Alignment disabled on the sides" scenario
- [x] 5.4 Add the preview strip across the top (~140px) via `TT.Preview.Create`, grow the window to ~700px, remove the demo button so "Reset all settings" is the only bottom button, and call `TT.Preview.Refresh()` from `TT.RefreshOptions()`; verify `grep -in demo Options.lua` returns nothing and the window height is ≤ 768

## 6. Docs and integration

- [x] 6.1 Update README.md placement docs (bottom, align, gap, `height` alias) and remove the `/ttl demo` row, noting the preview replaces it; verify `grep -in demo README.md` only mentions its removal
- [x] 6.2 Cross-file check: `grep -rn "SetDemo\|IsDemo\|topOffset\|CreateLight" *.lua` returns only the Core.lua migration, and every `TT.Lights.*`, `TT.Preview.*` and settings key used by Options.lua/Preview.lua exists in its owner file
- [ ] 6.3 Manual in-game check (user): open `/ttl` at UI scale 1 on a 768-tall resolution, cycle placement and alignment, drag every slider, run `/ttl side right` and `/ttl scale 1.23` with the window open, and confirm the preview and real plates follow
