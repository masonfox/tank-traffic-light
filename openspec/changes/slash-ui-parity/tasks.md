## 1. Settings registry

- [x] 1.1 Create `Settings.lua` with registry entries for lights, tankOnly, pulse, side, lightScale, topOffset, showWorld, showDungeon, showRaid, showPvP, trace, autoProbe, each with key, kind, label, section, and slash names. Add it to `TankTrafficLight.toc` after `Safe.lua`; verify `/reload` shows no Lua errors
- [x] 1.2 Implement the shared number parser (dot or comma decimal, range check, shared error template) and `TT.Settings.Set(key, raw)`; verify on `/reload` that it loads cleanly (behavior is exercised through the window and slash commands in sections 2 and 3)
- [x] 1.3 Implement the choice cycle helper for placement (Left -> Right -> Top -> Left) and explicit-value setting; verify invalid values return the list of valid choices
- [x] 1.4 Add the load-time check that warns in chat if a registry key is missing from `TT.DEFAULTS`; verify by temporarily removing a default and reloading

## 2. Options window uses the registry

- [x] 2.1 Switch checkboxes in `Options.lua` to take label and key from the registry and to call `Set`; verify each checkbox still toggles its setting and refreshes the lights
- [x] 2.2 Switch the size and height edit boxes to `Set`; verify `1,5` applies, `80` in height prints the shared message and reverts, and Escape still cancels
- [x] 2.3 Switch the placement button to the shared cycle helper; verify it cycles Left, Right, Top and the lights move

## 3. Slash commands use the registry

- [x] 3.1 Rewrite the `Core.lua` slash handler to dispatch registry commands (toggle, number, choice) and print label-based confirmations; verify `/ttl pulse`, `/ttl world`, `/ttl dungeon`, `/ttl raid`, `/ttl pvp`, `/ttl tankonly`, `/ttl lights`, `/ttl trace`, `/ttl auto` each toggle and echo the window label
- [x] 3.2 Add `/ttl side [left|right|top]`, `/ttl scale|size <n>`, `/ttl height <n>`, including printing the current value and range when no argument is given; verify `/ttl side top`, `/ttl side`, `/ttl side bottom`, `/ttl scale 1,5`, `/ttl height`
- [x] 3.3 Add `/ttl reset` using the same reset path as the window button; verify settings return to defaults and chat shows "settings reset"
- [x] 3.4 Build help from the registry, grouped by section, plus action and diagnostic commands; verify `/ttl foo` lists every command

## 4. Parity verification

- [ ] 4.1 With the options window open, run every slash command and confirm the matching control updates immediately; walk every window control and confirm a slash command exists for it (spec: "Options window and slash commands stay in parity")
- [x] 4.2 Bump `## Version` in the `.toc` and verify the addon list shows the new version
