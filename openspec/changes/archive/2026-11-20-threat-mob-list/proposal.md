## Why

Traffic lights sit on nameplates, so they are only as visible as the plates themselves. In a big pull the plates overlap and a single red lamp is easy to lose, and while the tank watches their own mob, a light on a plate at the edge of the screen goes unseen. The alerts cover only the most urgent case (a mob on a healer). A single, fixed panel listing every mob the lights have classified gives the tank one place to glance at to see what is loose, what is slipping, and what is held.

## What Changes

- **Mob list panel**: a new on-screen panel that lists every mob currently classified RED, YELLOW or GREEN, sorted RED first, then YELLOW, then GREEN. Each row shows a colored state marker and the mob's name. RED rows add who the mob is attacking (`-> Priest`), and YELLOW rows add "(slipping)". GREY mobs are not listed. The number of rows is capped (default 8), with a "+N more" line for the rest.
- **Header with counts**: the panel's header shows the count of mobs in each state (`R2 Y1 G3`) in the palette's colors.
- **Minimize**: a button on the header collapses the panel to just the header with counts, and expands it again. The minimized state is saved.
- **Toggle**: the list can be turned on or off on its own, independently of the traffic lights.
- **Display-only**: rows are not clickable and never target anything. When the panel is unlocked it can be dragged, and its position is saved. While unlocked it stays visible out of combat so it can be placed.
- **Same data as the lights**: the list reads the same classification as the lights, from nameplates only. It never guesses about mobs without a nameplate. A row disappears when its nameplate goes away.
- **Gating**: the list follows the tank-only and "Show in" zone filters. It shows only while it has rows (or while unlocked or in demo mode), so it is hidden out of combat.
- **Lights and classification are separated**: mobs are classified when either the lights or the list is on, so the list works with the lights turned off. Alerts still fire only when the lights are running, as today.
- **Settings**: a new "Mob list" section in the options window and matching slash commands: show the list, minimize it, lock it, and the maximum number of rows.
- **Demo mode**: also fills the list with sample rows covering every state, so it can be previewed and positioned anywhere.

## Capabilities

### New Capabilities
- `mob-list`: The mob list panel: which mobs it lists and how, sorting, header counts, minimize, lock and drag, row cap, when it is shown, and its gating.

### Modified Capabilities
- `settings`: New defaults, a new "Mob list" section in the options window, and new slash commands for showing, minimizing, locking and sizing the list. Reset also returns the list to its default position.
- `diagnostics`: Demo mode also fills the mob list with sample rows.

## Impact

- New `MobList.lua`, loaded before `Lights.lua` in the `.toc`. Version bump.
- `Lights.lua`: classification runs when the lights or the list is enabled. Painting a light requires the lights setting. Each state change is passed to the list through a hook like the one alerts use.
- `Settings.lua` and `Core.lua`: new registry entries, defaults and a new section. Reset clears the saved list position.
- `Options.lua`: a new "Mob list" box. The window must still fit a 768px-tall UI.
- New saved variables: `mobList`, `listMinimized`, `listLocked`, `listRows`, and the list position. Existing saved settings are unaffected.
