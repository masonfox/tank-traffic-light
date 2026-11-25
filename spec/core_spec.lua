-- Core.lua's slash handler (SlashCmdList.TANKTRAFFICLIGHT), plus the settings and
-- diagnostics scenarios it drives.
--
-- Partly covered (the setting and chat output are checked; lights moving, repainting
-- or the window's slider label are frame details outside this change, see the
-- design's Non-Goals): "Set placement directly", "Bottom placement by chat",
-- "Set colorblind palette", "Off-step value from chat", "Window updates from chat"
-- (checked through the TT.RefreshOptions stub, since Options.lua is not loaded).
-- Settings scenarios for the options window itself are listed in spec/settings_spec.lua.

local addon = require("spec.support.addon")

local PREFIX = "|cff66ccffTank Traffic Light|r "

-- Copy of the saved settings without the logs, to compare "nothing changed".
local function Snapshot(db)
    local out = {}
    for k, v in pairs(db) do
        if k ~= "probeLog" and k ~= "traceLog" then out[k] = v end
    end
    return out
end

local function LastChat(world) return world.chat[#world.chat] end

local function ChatHas(world, text)
    for _, line in ipairs(world.chat) do
        if line:find(text, 1, true) then return true end
    end
    return false
end

-- True when the chat holds the full grouped command list.
local function PrintedHelp(world)
    return ChatHas(world, PREFIX .. "commands:")
        and ChatHas(world, PREFIX .. "Traffic lights: /ttl lights, tankonly, pulse, grey|gray")
        and ChatHas(world, PREFIX .. "Alerts: /ttl slipsound,")
        and ChatHas(world, PREFIX .. "Show in: /ttl world, dungeon, raid, pvp")
        and ChatHas(world, PREFIX .. "Diagnostics: /ttl trace, auto, why, probe, clear")
        and ChatHas(world, PREFIX .. "Actions: /ttl (or options|config) - toggle the options window, reset")
end

describe("settings", function()
    local ctx, world

    before_each(function()
        ctx = addon.load()
        world = ctx.world
    end)

    describe("Slash commands", function()
        it("Open window", function()
            ctx.slash("")
            assert.equal(1, world.optionsToggled)
            ctx.slash("   ")
            assert.equal(2, world.optionsToggled)
        end)

        it("Set placement directly", function()
            ctx.slash("side top")
            assert.equal("top", ctx.db().side)
            assert.equal(PREFIX .. "Placement on the nameplate: Top", LastChat(world))
        end)

        it("Bottom placement by chat", function()
            ctx.slash("side bottom")
            assert.equal("bottom", ctx.db().side)
        end)

        it("Cycle placement", function()
            assert.equal("left", ctx.db().side)
            ctx.slash("side")
            assert.equal("right", ctx.db().side)
            assert.equal(PREFIX .. "Placement on the nameplate: Right", LastChat(world))
        end)

        it("Invalid placement", function()
            local before = Snapshot(ctx.db())
            ctx.slash("side middle")
            assert.same(before, Snapshot(ctx.db()))
            assert.equal(PREFIX .. "Placement on the nameplate must be one of: left, right, top, bottom",
                LastChat(world))
        end)

        it("Set alignment", function()
            ctx.slash("align left")
            assert.equal("left", ctx.db().align)
            assert.equal(PREFIX .. "Alignment: Left", LastChat(world))
        end)

        it("Height alias", function()
            ctx.slash("height 10")
            assert.equal(10, ctx.db().gap)
            assert.equal(PREFIX .. "Gap: 10", LastChat(world))
        end)

        it("Set colorblind palette", function()
            ctx.slash("colors colorblind")
            assert.equal("colorblind", ctx.db().palette)
            assert.equal(PREFIX .. "Colors: Colorblind", LastChat(world))
        end)

        it("Toggle an alert", function()
            ctx.slash("flash")
            assert.is_false(ctx.db().healerFlash)
            assert.equal(PREFIX .. "Flash the screen when a mob attacks a healer: OFF", LastChat(world))
            ctx.slash("flash")
            assert.is_true(ctx.db().healerFlash)
            assert.equal(PREFIX .. "Flash the screen when a mob attacks a healer: ON", LastChat(world))
        end)

        it("Choose a sound by chat", function()
            ctx.slash("healersoundname bell")
            assert.equal("bell", ctx.db().healerSoundName)
            assert.same({ ctx.env.SOUNDKIT.ALARM_CLOCK_WARNING_2 }, world.played)
            assert.equal(PREFIX .. "Healer sound: Bell", LastChat(world))
        end)

        it("Invalid grey opacity", function()
            local before = Snapshot(ctx.db())
            ctx.slash("greyalpha 2")
            assert.same(before, Snapshot(ctx.db()))
            assert.equal(PREFIX .. "grey light opacity must be a number from 0.1 to 1 (now 0.45)", LastChat(world))
        end)

        it("Invalid scale", function()
            local before = Snapshot(ctx.db())
            ctx.slash("scale 5")
            assert.same(before, Snapshot(ctx.db()))
            assert.equal(PREFIX .. "size must be a number from 0.5 to 3 (now 1)", LastChat(world))
        end)

        it("Query a numeric setting", function()
            local before = Snapshot(ctx.db())
            ctx.slash("gap")
            assert.same(before, Snapshot(ctx.db()))
            assert.equal(PREFIX .. "gap must be a number from 0 to 60 (now 4)", LastChat(world))
        end)

        it("Minimize the list by chat", function()
            local before = Snapshot(ctx.db())
            ctx.slash("listmin")
            assert.same(before, Snapshot(ctx.db()))
            assert.is_true(PrintedHelp(world))
        end)

        it("Reset from chat", function()
            ctx.slash("side top")
            ctx.slash("gap 30")
            ctx.slash("pulse")
            ctx.db().probeLog[1] = "probe line"
            ctx.db().traceLog[1] = "trace line"
            local refreshed = world.optionsRefreshed
            ctx.slash("reset")
            for k, v in pairs(ctx.TT.DEFAULTS) do assert.equal(v, ctx.db()[k], k) end
            assert.equal(PREFIX .. "settings reset", LastChat(world))
            assert.equal(refreshed + 1, world.optionsRefreshed)
            -- A reset leaves the diagnostics logs alone.
            assert.same({ "probe line" }, ctx.db().probeLog)
            assert.same({ "trace line" }, ctx.db().traceLog)
        end)

        it("Demo is gone", function()
            local before = Snapshot(ctx.db())
            ctx.slash("demo")
            assert.same(before, Snapshot(ctx.db()))
            assert.is_true(PrintedHelp(world))
        end)

        it("Mob list commands are gone", function()
            local before = Snapshot(ctx.db())
            for _, msg in ipairs({ "list", "listrows 5", "listlock" }) do
                world.chat = {}
                ctx.slash(msg)
                assert.same(before, Snapshot(ctx.db()))
                assert.is_true(PrintedHelp(world), msg)
            end
            assert.is_nil(ctx.db().mobList)
            assert.is_nil(ctx.db().listRows)
        end)

        it("Unknown command", function()
            ctx.slash("foo")
            assert.is_true(PrintedHelp(world))
            assert.equal(0, world.optionsToggled)
        end)
    end)

    describe("Options window and slash commands stay in parity", function()
        it("Same wording in chat and window", function()
            ctx.slash("pulse")
            assert.equal(PREFIX .. "Pulse the yellow light when aggro is slipping: OFF", LastChat(world))
            ctx.slash("pulse")
            assert.equal(PREFIX .. "Pulse the yellow light when aggro is slipping: ON", LastChat(world))
        end)

        it("Window updates from chat", function()
            local refreshed = world.optionsRefreshed
            ctx.slash("raid")
            assert.is_false(ctx.db().showRaid)
            assert.equal(refreshed + 1, world.optionsRefreshed)
        end)
    end)

    describe("Numeric settings use sliders and shared validation", function()
        it("Off-step value from chat", function()
            ctx.slash("scale 1.23")
            assert.equal(1.23, ctx.db().lightScale)
            assert.equal(PREFIX .. "Size: 1.23", LastChat(world))
        end)

        it("Fractional row count", function()
            local before = Snapshot(ctx.db())
            ctx.slash("listrows 4.5")
            assert.same(before, Snapshot(ctx.db()))
            assert.is_true(PrintedHelp(world))
        end)
    end)
end)

describe("diagnostics", function()
    local ctx, world

    before_each(function()
        ctx = addon.load()
        world = ctx.world
    end)

    describe("Light-change trace", function()
        it("Light turns red", function()
            local mob = world.mob({ threat = 3, target = "player" })
            ctx.TT.Lights.Update(mob)
            world.units[mob].threat = 0
            world.units[mob].target = world.partyMember({ name = "Dps", role = "DAMAGER" })
            ctx.TT.Lights.Update(mob)
            local log = ctx.db().traceLog
            assert.equal(2, #log)
            assert.matches(mob .. " Skeleton%(%d+%) green %-> red | status=0 target=Dps", log[2])
        end)

        it("Trace to chat off", function()
            assert.is_false(ctx.db().trace)
            local mob = world.mob({ threat = 3, target = "player" })
            world.chat = {}
            ctx.TT.Lights.Update(mob)
            assert.equal(1, #ctx.db().traceLog)
            assert.same({}, world.chat)

            ctx.slash("trace")
            assert.is_true(ctx.db().trace)
            world.units[mob].threat = 2
            ctx.TT.Lights.Update(mob)
            assert.equal(2, #ctx.db().traceLog)
            assert.is_true(ChatHas(world, "green -> yellow"))
        end)
    end)

    describe("Explain visible lights", function()
        it("Ask why", function()
            world.mob({ name = "Skeleton", threat = 3, target = "player" })
            world.mob({ name = "Zombie", threat = 0, target = world.partyMember({ name = "Dps" }) })
            ctx.slash("why")
            assert.equal(PREFIX .. "lights=true tankOnly=false allowed=true classify=true", world.chat[1])
            assert.matches("^" .. PREFIX:gsub("%p", "%%%0") .. "nameplate1 Skeleton: green |", world.chat[2])
            assert.matches("^" .. PREFIX:gsub("%p", "%%%0") .. "nameplate2 Zombie: red |", world.chat[3])
            assert.equal(PREFIX .. "visible nameplates: 2", world.chat[4])
            assert.equal(4, #world.chat)
            local why = {}
            for _, line in ipairs(ctx.db().traceLog) do
                if line:sub(1, 4) == "WHY " then why[#why + 1] = line end
            end
            assert.equal(4, #why)
            assert.equal("WHY visible nameplates: 2", why[4])
        end)
    end)

    describe("API probe", function()
        it("Manual probe", function()
            world.mob({ threat = 3, target = "player" })
            ctx.slash("probe")
            local log = ctx.db().probeLog
            assert.matches("^=== Probe %(manual%) at %d%d:%d%d:%d%d, inCombat=false ===$", log[1])
            assert.equal("visible nameplates: 1", log[4])
            assert.equal(#log, #world.chat)
            assert.equal(PREFIX .. log[1], world.chat[1])
        end)

        it("Probe shows co-tank inputs", function()
            local tank = world.partyMember({ role = "TANK", class = "PALADIN", mainTank = true })
            world.mob({ threat = 0, target = tank })
            local other = world.partyMember({ role = world.SECRET, class = world.SECRET, mainTank = world.SECRET })
            world.mob({ threat = 0, target = other })
            ctx.slash("probe")
            local log = table.concat(ctx.db().probeLog, "\n")
            assert.is_truthy(log:find("target role=TANK | class=Paladin, PALADIN, 1 | mainTank=true", 1, true))
            assert.is_truthy(log:find("target role=SECRET | class=SECRET, SECRET, SECRET | mainTank=SECRET", 1, true))
            assert.is_truthy(log:find("coTank=true (co-tank: role TANK)", 1, true))
        end)
    end)

    describe("Auto-probe on pull", function()
        it("Pull with auto-probe", function()
            ctx.slash("auto")
            assert.is_true(ctx.db().autoProbe)
            world.combatLockdown = true
            world.fire("PLAYER_REGEN_DISABLED")
            assert.same({ 3 }, world.timers)
            assert.matches("^=== Probe %(auto, 3s into combat%)", ctx.db().probeLog[1])
        end)

        it("Short combat", function()
            ctx.slash("auto")
            -- C_Timer.After runs its callback at once; combat has already ended by then.
            world.combatLockdown = false
            world.fire("PLAYER_REGEN_DISABLED")
            assert.same({ 3 }, world.timers)
            assert.same({}, ctx.db().probeLog)
        end)
    end)

    describe("Clear logs", function()
        it("Clear", function()
            world.mob({ threat = 3, target = "player" })
            ctx.TT.Lights.Update("nameplate1")
            ctx.slash("probe")
            assert.is_true(#ctx.db().probeLog > 0)
            assert.is_true(#ctx.db().traceLog > 0)
            ctx.slash("clear")
            assert.same({}, ctx.db().probeLog)
            assert.same({}, ctx.db().traceLog)
            assert.equal(PREFIX .. "probe and trace logs cleared", LastChat(world))
        end)
    end)
end)

describe("unit: slash dispatch", function()
    local ctx, world

    before_each(function()
        ctx = addon.load()
        world = ctx.world
    end)

    -- Covers the settings registry and the window's two buttons, not the window's
    -- controls themselves (Options.lua is not loaded), so the "Every window control is
    -- reachable from chat" scenario stays uncovered.
    it("changes every registry setting through each of its slash commands", function()
        local S = ctx.TT.Settings
        for _, entry in ipairs(S.Entries) do
            assert.is_true(#entry.slash > 0, entry.key)
            for _, command in ipairs(entry.slash) do
                local before = ctx.db()[entry.key]
                local msg, want = command, nil
                if entry.kind == "toggle" then
                    want = not before
                elseif entry.kind == "choice" then
                    for _, value in ipairs(entry.values) do
                        if value ~= before then want = value break end
                    end
                    msg = command .. " " .. want
                else
                    want = before == entry.max and entry.min or entry.max
                    msg = command .. " " .. tostring(want)
                end
                ctx.slash(msg)
                assert.equal(want, ctx.db()[entry.key], msg)
            end
        end
        -- The window's two buttons: "Test alerts" and "Reset all settings".
        local played = #world.played   -- sound choices above play a preview
        ctx.slash("testalert")
        assert.equal(played + 2, #world.played)
        ctx.slash("reset")
        assert.equal(PREFIX .. "settings reset", LastChat(world))
    end)

    it("opens the window with options and config", function()
        ctx.slash("options")
        ctx.slash("config")
        assert.equal(2, world.optionsToggled)
    end)

    it("accepts commands in any case with extra spaces", function()
        ctx.slash("  SIDE   Top  ")
        assert.equal("top", ctx.db().side)
        ctx.slash("GaP 12")
        assert.equal(12, ctx.db().gap)
    end)

    it("treats gray and grayalpha as the grey commands", function()
        ctx.slash("gray")
        assert.is_false(ctx.db().showGrey)
        assert.equal(PREFIX .. "Grey light on mobs that aren't yours: OFF", LastChat(world))
        ctx.slash("grayalpha 0,6")
        assert.equal(0.6, ctx.db().greyAlpha)
    end)

    it("treats size as the scale command", function()
        ctx.slash("size 2")
        assert.equal(2, ctx.db().lightScale)
    end)

    it("rejects invalid values and keeps the setting", function()
        local before = Snapshot(ctx.db())
        ctx.slash("gap -1")
        assert.equal(PREFIX .. "gap must be a number from 0 to 60 (now 4)", LastChat(world))
        ctx.slash("height abc")
        assert.equal(PREFIX .. "gap must be a number from 0 to 60 (now 4)", LastChat(world))
        ctx.slash("align top")
        assert.equal(PREFIX .. "Alignment must be one of: left, middle, right", LastChat(world))
        ctx.slash("colors red")
        assert.equal(PREFIX .. "Colors must be one of: classic, colorblind", LastChat(world))
        assert.same(before, Snapshot(ctx.db()))
    end)

    it("toggles ignore any argument", function()
        ctx.slash("lights off")
        assert.is_false(ctx.db().lights)
        ctx.slash("lights off")
        assert.is_true(ctx.db().lights)
    end)

    it("cycles a sound with no argument and previews it", function()
        ctx.slash("slipsoundname")
        assert.equal("whisper", ctx.db().slipSoundName)
        assert.same({ ctx.env.SOUNDKIT.TELL_MESSAGE }, world.played)
    end)

    it("handles a nil message as the bare command", function()
        ctx.slash(nil)
        assert.equal(1, world.optionsToggled)
    end)

    it("announces the alert test", function()
        ctx.slash("testalert")
        assert.equal(PREFIX .. "testing alerts: slipping sound, then healer sound and flash", LastChat(world))
        assert.same({ ctx.env.SOUNDKIT.IG_PLAYER_INVITE, ctx.env.SOUNDKIT.RAID_WARNING }, world.played)
    end)
end)
