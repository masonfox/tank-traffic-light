-- Scenario tests for openspec/specs/threat-classification/spec.md.
--
-- Covers every scenario in that spec through TT.Lights.StateFor, TT.Lights.IsGroupMember,
-- TT.Lights.IsCoTank and the `/ttl why` explanation path (TT.Lights.Explain via the slash
-- command). Intentionally uncovered (task 4.4): none. Every threat-classification
-- scenario is pure logic the fake world can express.

local addon = require("spec.support.addon")

describe("threat-classification", function()
    local ctx, world, TT, L, SECRET

    local function load(db)
        ctx = addon.load({ db = db })
        world, TT = ctx.world, ctx.TT
        L = TT.Lights
        SECRET = world.SECRET
    end

    -- State and reason for a mob built from spec.
    local function classify(spec)
        local mob = world.mob(spec)
        return L.StateFor(mob)
    end

    before_each(function() load() end)

    describe("Only attackable units in combat are classified", function()
        it("Unit is not attackable", function()
            local state, why = classify({ attackable = false, threat = 3, target = "player" })
            assert.is_nil(state)
            assert.equal("not attackable", why)

            state, why = classify({ attackable = SECRET, threat = 3, target = "player" })
            assert.is_nil(state)
            assert.equal("not attackable", why)
        end)

        it("Unit is not in combat", function()
            local state, why = classify({ combat = false, threat = 3, target = "player" })
            assert.is_nil(state)
            assert.equal("not in combat", why)
        end)

        it("Unit combat state is secret", function()
            local state, why = classify({ combat = SECRET, threat = 3, target = "player" })
            assert.is_nil(state)
            assert.equal("combat SECRET", why)
        end)
    end)

    describe("Readable threat status drives the light", function()
        it("Securely tanking", function()
            assert.equal("green", (classify({ threat = 3, target = "player" })))
        end)

        it("Aggro slipping", function()
            assert.equal("yellow", (classify({ threat = 2, target = "player" })))
        end)

        it("Mob is loose on the group", function()
            local dps = world.partyMember({ role = "DAMAGER" })
            assert.equal("red", (classify({ threat = 0, target = dps })))
            assert.equal("red", (classify({ threat = 1, target = dps })))
            -- No target at all is also loose.
            assert.equal("red", (classify({ threat = 0 })))
        end)

        it("Mob is fighting a stranger", function()
            local stranger = world.stranger()
            local state, why = classify({ threat = 0, target = stranger })
            assert.equal("grey", state)
            assert.matches("(on someone outside your group)", why, 1, true)
        end)

        it("Mob is on a co-tank", function()
            local tank = world.partyMember({ role = "TANK" })
            local state, why = classify({ threat = 1, target = tank })
            assert.equal("grey", state)
            assert.matches("co-tank: role TANK", why, 1, true)
        end)

        it("Mob's target cannot be read", function()
            -- The link to the target is secret: UnitExists on it is secret.
            assert.equal("red", (classify({ threat = 0, target = SECRET })))
            -- The target exists flag itself is secret.
            local hidden = world.stranger({ exists = SECRET })
            assert.equal("red", (classify({ threat = 0, target = hidden })))
        end)
    end)

    describe("Target-based fallback", function()
        -- Both fallback triggers: threat status unreadable (SECRET) and absent (nil).
        local STATUSES = { { "unreadable", "SECRET" }, { "absent", nil } }

        local function each(fn)
            for _, s in ipairs(STATUSES) do
                local threat = s[2] == "SECRET" and SECRET or nil
                fn(threat, s[1])
            end
        end

        it("Fallback, mob targeting the player", function()
            each(function(threat, label)
                local state, why = classify({ threat = threat, target = "player" })
                assert.equal("green", state, label)
                assert.matches("(fallback)", why, 1, true)
            end)
        end)

        it("Fallback, mob targeting a group member", function()
            each(function(threat, label)
                local dps = world.partyMember({ role = "HEALER" })
                assert.equal("red", (classify({ threat = threat, target = dps })), label)
            end)
        end)

        it("Fallback, mob targeting a co-tank", function()
            each(function(threat, label)
                local tank = world.partyMember({ role = "TANK" })
                local state, why = classify({ threat = threat, target = tank })
                assert.equal("grey", state, label)
                assert.matches("(fallback, co-tank: role TANK)", why, 1, true)
            end)
        end)

        it("Fallback, mob targeting a stranger", function()
            each(function(threat, label)
                local stranger = world.stranger()
                local state, why = classify({ threat = threat, target = stranger })
                assert.equal("grey", state, label)
                assert.matches("(fallback, target not in group)", why, 1, true)
            end)
        end)

        it("Fallback, no usable target", function()
            each(function(threat, label)
                local state, why = classify({ threat = threat })
                assert.is_nil(state, label)
                assert.matches("(no target)", why, 1, true)
                state = classify({ threat = threat, target = SECRET })
                assert.is_nil(state, label)
            end)
        end)
    end)

    describe("Group membership definition", function()
        it("Target is the player's pet", function()
            local pet = world.pet()
            assert.is_true(L.IsGroupMember(pet))
            -- The pet is in the group but never a co-tank: a mob on it is loose.
            assert.is_false(L.IsCoTank(pet))
            assert.equal("red", (classify({ threat = 0, target = pet })))
            assert.equal("red", (classify({ target = pet })))
        end)

        it("Target is a raid member", function()
            local raider = world.raidMember()
            assert.is_true(L.IsGroupMember(raider))
            assert.equal("red", (classify({ threat = 0, target = raider })))
            assert.equal("red", (classify({ target = raider })))
        end)
    end)

    describe("Every classification has an explanation", function()
        it("Explaining a fallback decision", function()
            local dps = world.partyMember({ name = "Stabby" })
            local state, why = classify({ threat = SECRET, target = dps })
            assert.equal("red", state)
            assert.equal("status=SECRET target=Stabby (fallback)", why)

            -- The same reason reaches the player through `/ttl why`.
            ctx.slash("why")
            local found
            for _, line in ipairs(world.chat) do
                if line:find("nameplate1 Skeleton: red | status=SECRET target=Stabby (fallback)", 1, true) then
                    found = true
                end
            end
            assert.is_true(found, table.concat(world.chat, "\n"))
            local log = ctx.db().traceLog
            assert.matches("^WHY ", log[#log])
        end)
    end)

    describe("Co-tank definition", function()
        it("Other tank in a dungeon group", function()
            local tank = world.partyMember({ role = "TANK" })
            local isCoTank, reason = L.IsCoTank(tank)
            assert.is_true(isCoTank)
            assert.equal("co-tank: role TANK", reason)
        end)

        it("Raid main tank without a role", function()
            local mt = world.raidMember({ role = "NONE", mainTank = true })
            local isCoTank, reason = L.IsCoTank(mt)
            assert.is_true(isCoTank)
            assert.equal("co-tank: main tank", reason)
            local state, why = classify({ threat = 0, target = mt })
            assert.equal("grey", state)
            assert.matches("(co-tank: main tank)", why, 1, true)
        end)

        it("Role unreadable", function()
            local member = world.partyMember({ role = SECRET, mainTank = SECRET })
            assert.is_false(L.IsCoTank(member))
            assert.equal("red", (classify({ threat = 0, target = member })))
            assert.equal("red", (classify({ target = member })))
        end)
    end)

    describe("Grey light can be turned off", function()
        before_each(function() load({ showGrey = false }) end)

        it("Grey off, mob fighting a stranger", function()
            local state, why = classify({ threat = 0, target = world.stranger() })
            assert.is_nil(state)
            assert.matches("(on someone outside your group) (grey off)", why, 1, true)
            state, why = classify({ target = world.stranger() })
            assert.is_nil(state)
            assert.matches("(fallback, target not in group) (grey off)", why, 1, true)
        end)

        it("Grey off, mob on co-tank", function()
            local tank = world.partyMember({ role = "TANK" })
            local state, why = classify({ threat = 0, target = tank })
            assert.is_nil(state)
            assert.matches("(co-tank: role TANK) (grey off)", why, 1, true)
            state = classify({ target = tank })
            assert.is_nil(state)
        end)
    end)
end)

describe("unit: threat-classification membership reads", function()
    local world, L

    before_each(function()
        local ctx = addon.load()
        world, L = ctx.world, ctx.TT.Lights
    end)

    it("counts unreadable membership checks as not a member", function()
        local unit = world.stranger({ inParty = world.SECRET, raidIndex = world.SECRET })
        assert.is_false(L.IsGroupMember(unit))
        assert.is_false(L.IsCoTank(unit))
    end)

    it("never produces YELLOW through the fallback", function()
        for _, threat in ipairs({ world.SECRET, false }) do
            for _, target in ipairs({ "player", world.partyMember(), world.stranger() }) do
                local mob = world.mob({ threat = threat or nil, target = target })
                assert.are_not.equal("yellow", (L.StateFor(mob)))
            end
        end
    end)

    it("never counts the player as a co-tank", function()
        assert.is_true(L.IsGroupMember("player"))
        assert.is_false(L.IsCoTank("player"))
    end)
end)
