-- display-gating: when traffic lights run at all (master toggle, tank-only, zone filters).
--
-- Each test drives L.Update on a nameplate whose plate comes from the fake
-- C_NamePlate.GetNamePlateForUnit, and asserts whether classification ran by
-- counting calls to TT.Lights.StateFor (L.Update calls it through the table), plus
-- whether the light frame on the plate is shown.
--
-- Uncovered on purpose: none. The "Master toggle" requirement's note about the
-- options window's sample light is out of scope here (Options.lua and Preview.lua
-- are not loaded by the harness).

local addon = require("spec.support.addon")

describe("display-gating", function()
    local ctx, world, TT, classified

    -- Load a fresh addon with `db`, spy on classification, and return a mob that
    -- would show a GREEN light whenever lights run.
    local function setup(db)
        ctx = addon.load({ db = db })
        world, TT = ctx.world, ctx.TT
        classified = 0
        local real = TT.Lights.StateFor
        TT.Lights.StateFor = function(...)
            classified = classified + 1
            return real(...)
        end
        return world.mob({ threat = 3, target = "player" })
    end

    local function lightOf(mob)
        return world.plates[mob].TankTrafficLightFrame
    end

    -- Update the mob and report whether it ran classification and shows a light.
    local function update(mob)
        classified = 0
        TT.Lights.Update(mob)
        local f = lightOf(mob)
        return classified > 0, f ~= nil and f:IsShown()
    end

    describe("Master toggle", function()
        it("Lights turned off", function()
            local mob = setup({ lights = true })
            local ran, shown = update(mob)
            assert.is_true(ran)
            assert.is_true(shown)

            ctx.db().lights = false
            ran, shown = update(mob)
            assert.is_false(ran)
            assert.is_false(shown)
            assert.is_nil(lightOf(mob).state)
        end)
    end)

    describe("Tank-only filter", function()
        it("Player queued as healer", function()
            for _, role in ipairs({ "HEALER", "DAMAGER" }) do
                local mob = setup({ tankOnly = true })
                world.units.player.role = role
                local ran, shown = update(mob)
                assert.is_false(ran, role)
                assert.is_false(shown, role)
            end
        end)

        it("Player has no role", function()
            local mob = setup({ tankOnly = true })
            world.units.player.role = "NONE"
            local ran, shown = update(mob)
            assert.is_true(ran)
            assert.is_true(shown)
        end)

        it("Role cannot be read", function()
            local mob = setup({ tankOnly = true })
            world.units.player.role = world.SECRET
            local ran, shown = update(mob)
            assert.is_true(ran)
            assert.is_true(shown)
        end)
    end)

    describe("Zone filters", function()
        it("PvP disabled by default", function()
            for _, zone in ipairs({ "pvp", "arena" }) do
                local mob = setup(nil) -- first install: defaults
                world.instance = { true, zone }
                local ran, shown = update(mob)
                assert.is_false(ran, zone)
                assert.is_false(shown, zone)
            end
        end)

        it("Scenario counts as open world", function()
            local mob = setup({ showWorld = true, showDungeon = false, showRaid = false, showPvP = false })
            world.instance = { true, "scenario" }
            assert.is_true((update(mob)))

            ctx.db().showWorld = false
            assert.is_false((update(mob)))
        end)

        it("Zone type unreadable", function()
            local mob = setup({ showWorld = false, showDungeon = false, showRaid = false, showPvP = false })
            world.instance = { true, world.SECRET }
            local ran, shown = update(mob)
            assert.is_true(ran)
            assert.is_true(shown)
        end)
    end)
end)

describe("unit: display-gating zone mapping", function()
    local cases = {
        { { false, "none" }, "showWorld" },
        { { true, "party" }, "showDungeon" },
        { { true, "raid" }, "showRaid" },
        { { true, "pvp" }, "showPvP" },
        { { true, "arena" }, "showPvP" },
        { { true, "somethingnew" }, "showWorld" },
    }
    for _, case in ipairs(cases) do
        local instance, key = case[1], case[2]
        it(string.format("%s uses %s", instance[2], key), function()
            local off = { showWorld = true, showDungeon = true, showRaid = true, showPvP = true }
            off[key] = false
            local ctx = addon.load({ db = off })
            local mob = ctx.world.mob({ threat = 3, target = "player" })
            ctx.world.instance = instance
            ctx.TT.Lights.Update(mob)
            assert.is_false(ctx.world.plates[mob].TankTrafficLightFrame:IsShown())

            ctx.db()[key] = true
            ctx.TT.Lights.Update(mob)
            assert.is_true(ctx.world.plates[mob].TankTrafficLightFrame:IsShown())
        end)
    end

    it("an IsInInstance that errors lets lights run", function()
        local ctx = addon.load({ db = { showWorld = false } })
        local mob = ctx.world.mob({ threat = 3, target = "player" })
        ctx.world.globals.IsInInstance = function() error("boom") end
        ctx.TT.Lights.Update(mob)
        assert.is_true(ctx.world.plates[mob].TankTrafficLightFrame:IsShown())
    end)
end)
