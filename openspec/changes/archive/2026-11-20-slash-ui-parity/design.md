## Context

Today each setting is described in up to three places: `TT.DEFAULTS` in `Core.lua`, a hand-built control in `Options.lua` (label, range check, error text), and a hand-written branch in the slash handler (its own wording and range check). Parity drifted because nothing ties these together. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- One definition per setting that both surfaces read, so a newly added setting can't be missed on one side.
- One parse and validate function per setting type.

**Non-Goals:**
- Generating the window layout automatically. Positions and section boxes stay hand-placed; only labels, validation, and change handling come from the shared definitions.
- Changing defaults, saved-variable keys, or diagnostics-only commands (`why`, `probe`, `clear`), which have no window control.

## Decisions

**1. A settings registry in a new `Settings.lua`, loaded before `Options.lua` and `Core.lua`.**
Each entry has: `key` (DB key), `kind` (`toggle` | `number` | `choice`), `label` (the window text), `slash` (command names, with aliases), and for numbers `min`/`max`/`name`, for choices `values`/`labels`. The registry also exposes `TT.Settings.Set(key, raw)`, which parses, validates, saves, refreshes the lights, refreshes the window, and returns `ok, message`.
- *Alternative:* keep separate code but add a parity checklist. Rejected because that is how the drift happened.
- *Alternative:* a full declarative UI generator. Rejected as too much for 13 controls, and the hand-tuned layout is fine.

**2. Defaults stay in `TT.DEFAULTS`.**
Diagnostics settings (`trace`, `autoProbe`) and others already live there, and `ApplyDefaults`/`ResetAll` work as they are. Registry entries refer to keys and don't copy defaults. At load, a check warns in chat (and only in chat) if a registry key is missing from `TT.DEFAULTS`.

**3. The window is the source of the wording.**
Slash confirmations print `label .. ": ON/OFF"` or `label .. ": <value>"`. Number errors use one template: `<name> must be a number from <min> to <max> (now <current>)`. The window's existing messages are replaced by this template.

**4. The slash handler is driven by the registry.**
The handler first checks a lookup from slash name to registry entry. Toggles flip, numbers go through `Set`, and choices take an explicit value or cycle. Commands that aren't settings (`options`, `demo`, `reset`, `why`, `probe`, `clear`) stay as explicit branches. Help is built from the registry, grouped by a `section` field (Traffic lights, Show in, Diagnostics), followed by the action commands.

**5. Window controls call the same `Set`.**
Checkboxes call `Set(key, checked)`, edit boxes call `Set(key, text)`, and the placement button calls the same cycle helper as `/ttl side`. On rejection, the window prints the returned message and refreshes, which reverts the field.

## Risks / Trade-offs

- [Confirmation wording changes for existing commands] → Mention it in the version notes. No one is known to parse this output.
- [`trace` toggle wording] The window label is "Print every light change to chat (/ttl trace)". Echoing it verbatim in chat is slightly redundant. → Accept; parity matters more than polish here.
- [Load order] `Settings.lua` must load before `Options.lua` and `Core.lua`. → Add it to the `.toc` right after `Safe.lua`, and verify on `/reload`.

## Migration Plan

No data migration: saved-variable keys are unchanged. Ship in the next version bump. To roll back, revert the commit.
