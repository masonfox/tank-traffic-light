-- settings: persisted defaults, migration, number/toggle/choice validation and Cycle,
-- tested through TT.Settings and ADDON_LOADED. Slash-command scenarios live in
-- spec/core_spec.lua.
--
-- Partly covered (the setting logic is checked, the window drawing is not, because
-- Options.lua and Preview.lua are not loaded; see the design's Non-Goals):
--   "Cycle placement wraps", "Cycle alignment", "Cycle colors": Settings.Cycle, which
--     the window's cycle buttons call; the button text and preview are not checked.
--   "Toggle a checkbox": Settings.Set with a boolean, as the checkbox does.
--   "Off-step value from chat" (core_spec): the slider's value label is not checked.
-- Left uncovered on purpose (options window, preview or frame placement only):
--   "Cycle placement" (window variant; the slash variant is "Cycle placement by chat",
--   which core_spec covers), "Alignment disabled on the sides", "No demo button",
--   "Test alerts from the window", "Unlock the list from the window",
--   "Lock the list from the window", "Minimize from the list updates the window",
--   "Open from game options", "Player resets" (window button; "Reset from chat" covers
--   the same reset), "Reset moves the list back" (no mob list panel to check),
--   "Drag the gap slider", "Slider shows the range limit".

local addon = require("spec.support.addon")

-- The defaults the spec lists, written out independently of TT.DEFAULTS.
local SPEC_DEFAULTS = {
    lights = true, tankOnly = false, pulse = true, showGrey = true, greyAlpha = 0.45,
    palette = "classic", side = "left", align = "middle", lightScale = 1, gap = 4,
    showWorld = true, showDungeon = true, showRaid = true, showPvP = false,
    slipSound = true, slipSoundName = "ping", healerSound = true, healerSoundName = "raidwarning",
    healerFlash = true, trace = false, autoProbe = false,
}

local function SettingsOnly(db)
    local out = {}
    for k, v in pairs(db) do
        if k ~= "probeLog" and k ~= "traceLog" then out[k] = v end
    end
    return out
end

describe("settings", function()
    describe("Persisted settings with defaults", function()
        it("First install", function()
            local ctx = addon.load()
            assert.same(SPEC_DEFAULTS, SettingsOnly(ctx.db()))
            assert.same({}, ctx.db().probeLog)
            assert.same({}, ctx.db().traceLog)
            -- Every setting entry has a default, so CheckDefaults prints nothing.
            assert.same({}, ctx.world.chat)
        end)

        it("New setting added in an update", function()
            local saved = {}
            for k, v in pairs(SPEC_DEFAULTS) do saved[k] = v end
            saved.gap, saved.side, saved.pulse = 9, "top", false
            saved.healerFlash = nil -- the "new" setting
            local ctx = addon.load({ db = saved })
            local expected = {}
            for k, v in pairs(SPEC_DEFAULTS) do expected[k] = v end
            expected.gap, expected.side, expected.pulse = 9, "top", false
            assert.same(expected, SettingsOnly(ctx.db()))
            assert.is_true(ctx.db().healerFlash)
        end)

        it("Upgrading to alerts", function()
            local ctx = addon.load({ db = {
                lights = true, tankOnly = true, pulse = false, side = "right", lightScale = 1.5,
                showWorld = false, showPvP = true, probeLog = { "old line" },
            } })
            local db = ctx.db()
            assert.is_true(db.tankOnly)
            assert.is_false(db.pulse)
            assert.equal("right", db.side)
            assert.equal(1.5, db.lightScale)
            assert.is_false(db.showWorld)
            assert.is_true(db.showPvP)
            assert.same({ "old line" }, db.probeLog)
            assert.is_true(db.showGrey)
            assert.equal("classic", db.palette)
            assert.is_true(db.slipSound)
            assert.is_true(db.healerSound)
            assert.is_true(db.healerFlash)
        end)

        it("Upgrading to the mob list", function()
            local saved = { mobList = true, listMinimized = true, listLocked = false, listRows = 6,
                listPos = { "CENTER", 10, -20 } }
            for k, v in pairs(SPEC_DEFAULTS) do saved[k] = v end
            saved.gap, saved.palette = 7, "colorblind"
            local ctx = addon.load({ db = saved })
            local db = ctx.db()
            assert.is_nil(db.mobList)
            assert.is_nil(db.listMinimized)
            assert.is_nil(db.listLocked)
            assert.is_nil(db.listRows)
            assert.is_nil(db.listPos)
            local expected = {}
            for k, v in pairs(SPEC_DEFAULTS) do expected[k] = v end
            expected.gap, expected.palette = 7, "colorblind"
            assert.same(expected, SettingsOnly(db))
        end)

        it("Upgrading keeps the top height", function()
            local ctx = addon.load({ db = { side = "top", topOffset = 12, lights = true } })
            local db = ctx.db()
            assert.equal(12, db.gap)
            assert.is_nil(db.topOffset)
            assert.equal("middle", db.align)
            assert.equal("top", db.side)
        end)

        it("Upgrading with the light on the side", function()
            local ctx = addon.load({ db = { side = "left", topOffset = 4 } })
            local db = ctx.db()
            assert.equal(4, db.gap)
            assert.is_nil(db.topOffset)
            assert.equal("left", db.side)
        end)
    end)

    describe("Options window", function()
        local ctx, S

        before_each(function()
            ctx = addon.load()
            S = ctx.TT.Settings
        end)

        it("Toggle a checkbox", function()
            local refreshed = ctx.world.optionsRefreshed
            local ok, msg = S.Set("pulse", false)
            assert.is_true(ok)
            assert.equal("Pulse the yellow light when aggro is slipping: OFF", msg)
            assert.is_false(ctx.db().pulse)
            assert.equal(refreshed + 1, ctx.world.optionsRefreshed)
        end)

        it("Cycle placement wraps", function()
            ctx.db().side = "bottom"
            local ok, msg = S.Cycle("side")
            assert.is_true(ok)
            assert.equal("left", ctx.db().side)
            assert.equal("Placement on the nameplate: Left", msg)
        end)

        it("Cycle alignment", function()
            ctx.db().side = "top"
            assert.equal("middle", ctx.db().align)
            local ok, msg = S.Cycle("align")
            assert.is_true(ok)
            assert.equal("right", ctx.db().align)
            assert.equal("Alignment: Right", msg)
        end)

        it("Cycle colors", function()
            local ok, msg = S.Cycle("palette")
            assert.is_true(ok)
            assert.equal("colorblind", ctx.db().palette)
            assert.equal("Colors: Colorblind", msg)
        end)
    end)

    describe("Numeric settings use sliders and shared validation", function()
        local ctx

        before_each(function() ctx = addon.load() end)

        it("Comma decimal size by slash", function()
            ctx.slash("scale 1,5")
            assert.equal(1.5, ctx.db().lightScale)
            assert.equal("|cff66ccffTank Traffic Light|r Size: 1.5", ctx.world.chat[#ctx.world.chat])
        end)

        it("Invalid gap", function()
            ctx.slash("gap 80")
            assert.equal(4, ctx.db().gap)
            assert.equal("|cff66ccffTank Traffic Light|r gap must be a number from 0 to 60 (now 4)",
                ctx.world.chat[#ctx.world.chat])
        end)
    end)
end)

describe("unit: Settings.Set number parsing", function()
    local ctx, S

    before_each(function()
        ctx = addon.load()
        S = ctx.TT.Settings
    end)

    it("accepts dot and comma decimals, numbers and the range ends", function()
        assert.is_true((S.Set("greyAlpha", "0,7")))
        assert.equal(0.7, ctx.db().greyAlpha)
        assert.is_true((S.Set("greyAlpha", "0.1")))
        assert.equal(0.1, ctx.db().greyAlpha)
        assert.is_true((S.Set("greyAlpha", 1)))
        assert.equal(1, ctx.db().greyAlpha)
        assert.is_true((S.Set("gap", "0")))
        assert.equal(0, ctx.db().gap)
        assert.is_true((S.Set("gap", "60")))
        assert.equal(60, ctx.db().gap)
    end)

    it("keeps an off-step value as entered", function()
        assert.same({ true, "Size: 1.23" }, { S.Set("lightScale", "1.23") })
        assert.equal(1.23, ctx.db().lightScale)
        assert.is_true((S.Set("gap", "7.5")))
        assert.equal(7.5, ctx.db().gap)
    end)

    it("rejects out-of-range, non-numeric and empty input and keeps the value", function()
        for _, raw in ipairs({ "0.05", "1.01", "-1", "abc", "", "1,2,3" }) do
            local ok, msg = S.Set("greyAlpha", raw)
            assert.is_false(ok, raw)
            assert.equal("grey light opacity must be a number from 0.1 to 1 (now 0.45)", msg)
        end
        assert.equal(0.45, ctx.db().greyAlpha)
        local ok, msg = S.Set("lightScale", nil)
        assert.is_false(ok)
        assert.equal("size must be a number from 0.5 to 3 (now 1)", msg)
    end)

    it("does not refresh lights or the window on a rejected value", function()
        local refreshed = ctx.world.optionsRefreshed
        S.Set("gap", "61")
        assert.equal(refreshed, ctx.world.optionsRefreshed)
    end)
end)

describe("unit: Settings.Set toggles and choices", function()
    local ctx, S

    before_each(function()
        ctx = addon.load()
        S = ctx.TT.Settings
    end)

    it("requires a boolean for a toggle", function()
        local ok, msg = S.Set("pulse", "off")
        assert.is_false(ok)
        assert.equal("Pulse the yellow light when aggro is slipping requires a boolean", msg)
        assert.is_true(ctx.db().pulse)
        assert.same({ true, "Pulse the yellow light when aggro is slipping: ON" }, { S.Set("pulse", true) })
    end)

    it("rejects a choice outside the list and keeps the value", function()
        local ok, msg = S.Set("side", "middle")
        assert.is_false(ok)
        assert.equal("Placement on the nameplate must be one of: left, right, top, bottom", msg)
        assert.equal("left", ctx.db().side)
        assert.is_false((S.Set("palette", "Classic")))
        assert.equal("classic", ctx.db().palette)
    end)

    it("rejects an unknown setting", function()
        assert.same({ false, "unknown setting: nope" }, { S.Set("nope", true) })
    end)

    it("previews a newly chosen alert sound once", function()
        assert.same({ true, "Slipping sound: Bell" }, { S.Set("slipSoundName", "bell") })
        assert.same({ ctx.env.SOUNDKIT.ALARM_CLOCK_WARNING_2 }, ctx.world.played)
    end)
end)

describe("unit: Settings.Cycle", function()
    local ctx, S

    before_each(function()
        ctx = addon.load()
        S = ctx.TT.Settings
    end)

    it("steps placement through Left, Right, Top, Bottom and back", function()
        local seen = {}
        for _ = 1, 4 do
            S.Cycle("side")
            seen[#seen + 1] = ctx.db().side
        end
        assert.same({ "right", "top", "bottom", "left" }, seen)
    end)

    it("wraps alignment and sound choices", function()
        ctx.db().align = "right"
        S.Cycle("align")
        assert.equal("left", ctx.db().align)
        ctx.db().healerSoundName = "raidwarning"
        S.Cycle("healerSoundName")
        assert.equal("ping", ctx.db().healerSoundName)
    end)

    it("starts from the first value when the saved value is not in the list", function()
        ctx.db().side = "middle"
        assert.same({ true, "Placement on the nameplate: Left" }, { S.Cycle("side") })
        assert.equal("left", ctx.db().side)
    end)
end)

describe("unit: migration and defaults", function()
    it("keeps a saved gap over an old top height and drops the height", function()
        local ctx = addon.load({ db = { gap = 20, topOffset = 12 } })
        assert.equal(20, ctx.db().gap)
        assert.is_nil(ctx.db().topOffset)
    end)

    it("keeps saved false values instead of defaulting them", function()
        local ctx = addon.load({ db = { lights = false, showGrey = false, slipSound = false } })
        assert.is_false(ctx.db().lights)
        assert.is_false(ctx.db().showGrey)
        assert.is_false(ctx.db().slipSound)
    end)

    it("has a default for every setting entry", function()
        local ctx = addon.load()
        for _, entry in ipairs(ctx.TT.Settings.Entries) do
            assert.is_not_nil(ctx.TT.DEFAULTS[entry.key], entry.key)
        end
    end)

    it("ResetAll restores defaults without touching the logs", function()
        local ctx = addon.load({ db = { gap = 30, probeLog = { "p" }, traceLog = { "t" } } })
        ctx.TT.ResetAll()
        assert.same(SPEC_DEFAULTS, SettingsOnly(ctx.db()))
        assert.same({ "p" }, ctx.db().probeLog)
        assert.same({ "t" }, ctx.db().traceLog)
    end)
end)
