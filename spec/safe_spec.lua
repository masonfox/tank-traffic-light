-- safe-api-access: every scenario in openspec/specs/safe-api-access/spec.md.
-- Covered here: all seven scenarios. Nothing is left uncovered on purpose.

local addon = require("spec.support.addon")

describe("safe-api-access", function()
    local ctx, world, env, TT, S

    before_each(function()
        ctx = addon.load()
        world, env, TT = ctx.world, ctx.env, ctx.TT
        S = TT.Safe
    end)

    describe("Secret values are treated as unreadable", function()
        it("Client reports a secret value", function()
            assert.is_false(S.Public(world.SECRET))
            assert.is_true(S.Public("Skeleton"))
            assert.is_true(S.Public(nil))

            -- A read that returns a secret succeeds as a call, but the value is unreadable.
            local healer = world.partyMember({ role = world.SECRET, class = "WARRIOR" })
            local ok, role = S.Call(env.UnitGroupRolesAssigned, healer)
            assert.is_true(ok)
            assert.is_false(S.Public(role))

            -- A decision falls through to its unreadable-value path (the class fallback).
            local isHealer, why = TT.Alerts.IsHealer(healer)
            assert.is_false(isHealer)
            assert.equal("no role, class WARRIOR", why)

            -- A secret function reference is never called.
            local ok2, err = S.Call(world.SECRET)
            assert.is_false(ok2)
            assert.equal("function unavailable", err)
        end)

        it("Client has no secret-value API", function()
            world.absent.issecretvalue = true
            assert.is_true(S.Public(world.SECRET))
            assert.is_true(S.Public("Skeleton"))
            assert.is_true(S.Public(nil))
            assert.equal("Skeleton", S.Describe("Skeleton"))
        end)

        it("The secret-value check itself fails", function()
            world.globals.issecretvalue = function() error("check broke") end
            assert.is_false(S.Public("Skeleton"))
            assert.equal("SECRET", S.Describe("Skeleton"))

            world.globals.issecretvalue = function() return "no" end
            assert.is_false(S.Public("Skeleton"))

            world.globals.issecretvalue = function() return nil end
            assert.is_false(S.Public("Skeleton"))
        end)
    end)

    describe("API calls never raise errors", function()
        it("API function is missing", function()
            local ok, err = S.Call(nil, "player")
            assert.is_false(ok)
            assert.equal("function unavailable", err)

            -- A real decision on a client without the role API: no error, class fallback.
            world.absent.UnitGroupRolesAssigned = true
            local priest = world.partyMember({ class = "PRIEST" })
            local isHealer, why = TT.Alerts.IsHealer(priest)
            assert.is_true(isHealer)
            assert.equal("no role, class PRIEST", why)
        end)

        it("API call errors", function()
            local ok, err = S.Call(function() error("boom") end)
            assert.is_false(ok)
            assert.matches("boom", err)

            world.globals.UnitGroupRolesAssigned = function() error("role API broke") end
            local druid = world.partyMember({ class = "DRUID" })
            local isHealer, why
            assert.has_no.errors(function() isHealer, why = TT.Alerts.IsHealer(druid) end)
            assert.is_true(isHealer)
            assert.equal("no role, class DRUID", why)
        end)
    end)

    describe("Diagnostic output never exposes secret values", function()
        it("Logging a secret unit name", function()
            local mob = world.mob({ name = world.SECRET })
            assert.matches("^SECRET", S.Probe(env.UnitName, mob))
            assert.equal("SECRET", S.Describe(world.SECRET))

            ctx.slash("probe")
            local found
            for _, line in ipairs(ctx.db().probeLog) do
                if line:find("-- " .. mob .. " name=SECRET", 1, true) then found = true end
            end
            assert.is_true(found)
            for _, line in ipairs(world.chat) do
                assert.is_nil(line:find("table: ", 1, true))
            end
        end)

        it("Probing a missing API", function()
            assert.equal("MISSING API", S.Probe(nil))

            world.absent.UnitDetailedThreatSituation = true
            world.mob({ threat = 3, target = "player" })
            ctx.slash("probe")
            local found
            for _, line in ipairs(ctx.db().probeLog) do
                if line:find("detailedThreat(isTanking,status,scaled%,raw%,value)=MISSING API", 1, true) then
                    found = true
                end
            end
            assert.is_true(found)
        end)
    end)
end)

describe("unit: Safe", function()
    local S, world

    before_each(function()
        local ctx = addon.load()
        S, world = ctx.TT.Safe, ctx.world
    end)

    it("Call passes arguments and every return through", function()
        assert.same({ true, 1, "b", 3 }, { S.Call(function(a, b) return a, b, 3 end, 1, "b") })
    end)

    it("Call refuses non-functions", function()
        assert.same({ false, "function unavailable" }, { S.Call("UnitName") })
        assert.same({ false, "function unavailable" }, { S.Call({}) })
    end)

    it("Describe shows nil, values and unprintable values", function()
        assert.equal("nil", S.Describe(nil))
        assert.equal("false", S.Describe(false))
        assert.equal("42", S.Describe(42))
        local bad = setmetatable({}, { __tostring = function() error("no text") end })
        assert.equal("UNPRINTABLE", S.Describe(bad))
    end)

    it("Probe reports errors, no returns and every return value", function()
        assert.equal("ERROR: nope", S.Probe(function() error("nope", 0) end))
        assert.equal("ERROR: SECRET", S.Probe(function() error(world.SECRET) end))
        assert.equal("(no returns)", S.Probe(function() end))
        assert.equal("true, SECRET, 3", S.Probe(function() return true, world.SECRET, 3 end))
    end)
end)
