local addon = require("spec.support.addon")
local wow = require("spec.support.wow")

describe("unit: fake world", function()
    local ctx, world, env, TT

    before_each(function()
        ctx = addon.load()
        world, env, TT = ctx.world, ctx.env, ctx.TT
    end)

    it("resolves nameplate1target through the mob's target", function()
        world.units.nameplate1 = { attackable = true, combat = true, threat = 0, target = "party1" }
        world.units.party1 = { inParty = true, role = "TANK", class = "WARRIOR", name = "Tanky2" }
        assert.is_true(env.UnitIsUnit("nameplate1target", "party1"))
        assert.is_false(env.UnitIsUnit("nameplate1target", "player"))
        assert.equal("Tanky2", env.UnitName("nameplate1target"))
        assert.equal("TANK", env.UnitGroupRolesAssigned("nameplate1target"))
        assert.is_false(env.UnitExists("nameplate2target"))
    end)

    it("reports a secret role as secret through TT.Safe", function()
        local healer = world.partyMember({ role = world.SECRET })
        local ok, role = TT.Safe.Call(env.UnitGroupRolesAssigned, healer)
        assert.is_true(ok)
        assert.is_false(TT.Safe.Public(role))
        assert.equal("SECRET", TT.Safe.Describe(role))
    end)

    it("fails when addon code reads a global the world lacks", function()
        local chunk = assert(loadstring("return UnitFooTypo('player')"))
        setfenv(chunk, env)
        assert.error_matches(chunk, "fake world lacks global UnitFooTypo", 1, true)
        assert.same({ "UnitFooTypo" }, world.missing)
    end)

    it("reads an absent issecretvalue as nil", function()
        world.absent.issecretvalue = true
        local chunk = assert(loadstring("return issecretvalue"))
        setfenv(chunk, env)
        assert.is_nil(chunk())
        -- Like a client without the API: every value counts as readable.
        assert.is_true(TT.Safe.Public(world.SECRET))
    end)

    it("loads all six addon files in TOC order", function()
        assert.same({ "Safe.lua", "Settings.lua", "Probe.lua", "Alerts.lua", "Lights.lua", "Core.lua" }, ctx.files)
        assert.is_function(TT.Lights.StateFor)
        assert.same({}, world.missing)
    end)

    it("applies defaults to a first-install TankTrafficLightDB", function()
        assert.is_table(ctx.db())
        assert.equal(TT.DEFAULTS.gap, ctx.db().gap)
        assert.same({}, ctx.db().probeLog)
    end)

    it("migrates a test-supplied TankTrafficLightDB", function()
        ctx = addon.load({ db = { topOffset = 12 } })
        assert.equal(12, ctx.db().gap)
        assert.is_nil(ctx.db().topOffset)
    end)

    it("keeps addon globals in the sandbox, readable by tests", function()
        assert.equal("/ttl", env.SLASH_TANKTRAFFICLIGHT2)
        assert.is_function(env.SlashCmdList.TANKTRAFFICLIGHT)
        assert.is_nil(rawget(_G, "TankTrafficLightDB"))
    end)

    it("records prints and fires captured OnEvent handlers", function()
        ctx.slash("grey")
        assert.matches("Grey light", world.chat[#world.chat])
        assert.is_true(world.fire("PLAYER_REGEN_ENABLED") > 0)
    end)

    it("classifies a mob on a co-tank as GREY in a few lines", function()
        local mob = world.mob({ threat = 0, target = world.partyMember({ role = "TANK" }) })
        assert.equal("grey", (TT.Lights.StateFor(mob)))
    end)

    it("builds a fresh world for every load", function()
        assert.are_not.equal(wow.new().env, env)
        assert.is_nil(addon.load().world.units.nameplate1)
    end)
end)
