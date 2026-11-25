-- alerts: slipping sound, healer identification, mob-on-healer alerts, sound choice,
-- the test command, and gating with the lights.
--
-- Alerts are driven the real way: TT.Lights.Update on a nameplate mob, so Lights.lua
-- classifies and calls TT.Alerts.OnState. Time is the fake clock (world.time, via
-- world.advance); sounds are the SOUNDKIT ids recorded in world.played. The flash is
-- read from the fake frame Alerts.lua creates (its `text` font string).
--
-- Uncovered on purpose (purely visual or outside the loaded files):
--   * "Clicking during a flash": mouse click-through is a client input detail the
--     fake world does not model.
--   * "Preview cycling": the options window's sample light lives in Preview.lua /
--     Options.lua, which the harness does not load (design Non-Goals).
--   * Flash look in "Names readable" (red edge glow, fade timing) is not asserted;
--     only the flash being shown and its text are.

local addon = require("spec.support.addon")

local PING, BELL, RAID_WARNING = 880, 12867, 8959

describe("alerts", function()
    local ctx, world, TT

    local function load(db)
        ctx = addon.load({ db = db })
        world, TT = ctx.world, ctx.TT
    end

    before_each(function() load(nil) end)

    local function update(mob) TT.Lights.Update(mob) end

    -- Set a mob's threat/target and update it after `seconds` on the fake clock.
    local function step(mob, seconds, threat, target)
        world.advance(seconds or 0)
        world.units[mob].threat = threat
        world.units[mob].target = target
        update(mob)
    end

    local function count(id)
        local n = 0
        for _, played in ipairs(world.played) do if played == id then n = n + 1 end end
        return n
    end

    -- The flash frame, once an alert has created it.
    local function flash()
        for _, f in ipairs(world.frames) do
            if rawget(f, "text") then return f end
        end
    end

    local function healer(spec)
        spec = spec or {}
        spec.role = spec.role or "HEALER"
        spec.class = spec.class or "PRIEST"
        spec.name = spec.name or "Priestly"
        return world.partyMember(spec)
    end

    describe("Slipping sound", function()
        it("Mob starts slipping", function()
            local mob = world.mob({ threat = 3, target = "player" })
            update(mob)
            assert.same({}, world.played)
            step(mob, 1, 2, "player")
            assert.same({ PING }, world.played)
            -- Staying YELLOW is not a new slip.
            step(mob, 3, 2, "player")
            assert.same({ PING }, world.played)
        end)

        it("Several mobs slip together", function()
            local mobs = {}
            for i = 1, 3 do
                mobs[i] = world.mob({ threat = 3, target = "player" })
                update(mobs[i])
            end
            for i = 1, 3 do step(mobs[i], 0.3, 2, "player") end
            assert.same({ PING }, world.played)
        end)

        it("Setting off", function()
            load({ slipSound = false })
            local mob = world.mob({ threat = 3, target = "player" })
            update(mob)
            step(mob, 1, 2, "player")
            assert.same({}, world.played)
        end)
    end)

    describe("Healer identification", function()
        it("Assigned healer", function()
            local unit = world.partyMember({ role = "HEALER", class = "WARRIOR" })
            assert.is_true((TT.Alerts.IsHealer(unit)))
        end)

        it("Unassigned priest in a raid", function()
            local unit = world.raidMember({ role = "NONE", class = "PRIEST" })
            assert.is_true((TT.Alerts.IsHealer(unit)))
        end)

        it("Shaman queued as damage", function()
            local unit = world.partyMember({ role = "DAMAGER", class = "SHAMAN" })
            assert.is_false((TT.Alerts.IsHealer(unit)))
        end)
    end)

    describe("Mob-on-healer detection", function()
        it("Mob peels to the healer", function()
            local priest = healer()
            local mob = world.mob({ threat = 3, target = "player" })
            update(mob)
            step(mob, 1, 0, priest)
            assert.equal("red", world.plates[mob].TankTrafficLightFrame.state)
            assert.same({ RAID_WARNING }, world.played)
        end)

        it("Loose mob switches to healer", function()
            local priest = healer()
            local mage = world.partyMember({ role = "DAMAGER", class = "MAGE" })
            local mob = world.mob({ threat = 0, target = mage })
            update(mob)
            assert.equal("red", world.plates[mob].TankTrafficLightFrame.state)
            assert.same({}, world.played)
            step(mob, 1, 0, priest)
            assert.same({ RAID_WARNING }, world.played)
        end)

        it("Flicker", function()
            local priest = healer()
            local mob = world.mob({ threat = 0, target = priest })
            update(mob)
            -- Back and forth, each hop past the 1.5 s global throttle but inside 5 s.
            step(mob, 0.8, 0, "player")
            step(mob, 0.8, 0, priest)
            step(mob, 0.8, 0, "player")
            step(mob, 0.8, 0, priest)
            step(mob, 0.8, 0, "player")
            step(mob, 0.8, 0, priest)
            assert.equal(1, count(RAID_WARNING))
            -- After the 5 s window the same mob can alert again.
            step(mob, 1, 0, "player")
            step(mob, 0.5, 0, priest)
            assert.equal(2, count(RAID_WARNING))
        end)

        it("Mob on co-tank", function()
            local coTank = world.partyMember({ role = "NONE", class = "PALADIN", mainTank = true })
            local mob = world.mob({ threat = 3, target = "player" })
            update(mob)
            step(mob, 1, 0, coTank)
            assert.equal("grey", world.plates[mob].TankTrafficLightFrame.state)
            assert.same({}, world.played)
            assert.is_nil(flash())
        end)
    end)

    describe("Sound choice", function()
        it("Pick a healer sound", function()
            TT.Settings.Cycle("healerSoundName")
            assert.equal("ping", ctx.db().healerSoundName)
            assert.same({ PING }, world.played)

            world.played = {}
            local mob = world.mob({ threat = 0, target = healer() })
            update(mob)
            assert.same({ PING }, world.played)
        end)

        it("Same sound for both", function()
            ctx.slash("slipsoundname bell")
            ctx.slash("healersoundname bell")
            world.played = {}
            local priest = healer()
            local mob = world.mob({ threat = 3, target = "player" })
            update(mob)
            step(mob, 1, 2, "player") -- slipping
            step(mob, 1, 0, priest)   -- on the healer
            assert.same({ BELL, BELL }, world.played)
        end)

        it("Sound missing on client", function()
            world.globals.SOUNDKIT.RAID_WARNING = nil
            local mob = world.mob({ threat = 0, target = healer() })
            assert.has_no.errors(function() update(mob) end)
            assert.same({}, world.played)
            -- The rest of the alert still happens.
            assert.is_true(flash():IsShown())

            world.absent.SOUNDKIT = true
            assert.has_no.errors(function() TT.Alerts.PlayChoice("ping") end)
            assert.same({}, world.played)
        end)
    end)

    describe("Mob-on-healer sound", function()
        it("Healer sound", function()
            load({ healerFlash = false })
            local mob = world.mob({ threat = 0, target = healer() })
            update(mob)
            assert.same({ RAID_WARNING }, world.played)
        end)
    end)

    describe("Mob-on-healer flash", function()
        it("Names readable", function()
            local mob = world.mob({ name = "Skeleton", threat = 0, target = healer({ name = "Priestly" }) })
            update(mob)
            local f = flash()
            assert.is_true(f:IsShown())
            assert.equal("Skeleton -> Priestly", f.text:GetText())
        end)

        it("Names secret", function()
            local mob = world.mob({ name = "Skeleton", threat = 0, target = healer({ name = world.SECRET }) })
            update(mob)
            assert.is_true(flash():IsShown())
            assert.equal("Mob on your healer!", flash().text:GetText())

            -- A fresh world, so the first flash cannot stand in for a missing second one.
            load(nil)
            local mob2 = world.mob({ name = world.SECRET, threat = 0, target = healer({ name = "Holy" }) })
            update(mob2)
            assert.is_not_nil(flash())
            assert.is_true(flash():IsShown())
            assert.equal("Mob on your healer!", flash().text:GetText())
        end)
    end)

    describe("Alert test", function()
        it("Test from chat", function()
            load({ lights = false, slipSound = false, healerSound = false, healerFlash = false })
            world.combatLockdown = true
            ctx.slash("testalert")
            assert.same({ PING, RAID_WARNING }, world.played)
            local f = flash()
            assert.is_true(f:IsShown())
            assert.matches("Skeleton -> Priestly", f.text:GetText(), 1, true)
        end)
    end)

    describe("Alerts follow nameplate classification", function()
        it("Lights gated off", function()
            world.instance = { true, "pvp" } -- PvP is off by default
            local priest = healer()
            local mob = world.mob({ threat = 3, target = "player" })
            update(mob)
            step(mob, 1, 2, "player")
            step(mob, 1, 0, priest)
            assert.same({}, world.played)
            assert.is_nil(flash())

            ctx.db().lights = false
            world.instance = { false, "none" }
            step(mob, 1, 2, "player")
            step(mob, 1, 0, priest)
            assert.same({}, world.played)
            assert.is_nil(flash())
        end)
    end)
end)

describe("unit: alerts", function()
    local ctx, world, TT

    before_each(function()
        ctx = addon.load()
        world, TT = ctx.world, ctx.TT
    end)

    it("PLAYER_REGEN_ENABLED resets the per-mob healer throttle", function()
        local priest = world.partyMember({ role = "HEALER", class = "PRIEST" })
        local mob = world.mob({ threat = 0, target = priest })
        TT.Lights.Update(mob)
        assert.same({ 8959 }, world.played)

        local function hop()
            world.advance(1)
            world.units[mob].target = "player"
            TT.Lights.Update(mob)
            world.advance(1)
            world.units[mob].target = priest
            TT.Lights.Update(mob)
        end

        hop() -- 2 s later: still inside the same mob's 5 s window
        assert.same({ 8959 }, world.played)

        world.fire("PLAYER_REGEN_ENABLED")
        hop()
        assert.same({ 8959, 8959 }, world.played)
    end)

    it("the slipping sound plays again after its 2 s throttle", function()
        local mob = world.mob({ threat = 3, target = "player" })
        TT.Lights.Update(mob)
        for _ = 1, 2 do
            world.advance(0.5)
            world.units[mob].threat = 2
            TT.Lights.Update(mob)
            world.advance(0.5)
            world.units[mob].threat = 3
            TT.Lights.Update(mob)
        end
        assert.same({ 880 }, world.played)
        world.advance(1)
        world.units[mob].threat = 2
        TT.Lights.Update(mob)
        assert.same({ 880, 880 }, world.played)
    end)

    it("the pet and a member with no readable role or class are not healers", function()
        local pet = world.pet({ class = "PRIEST" })
        assert.is_false((TT.Alerts.IsHealer(pet)))
        local unknown = world.partyMember({ role = world.SECRET, class = world.SECRET })
        assert.is_false((TT.Alerts.IsHealer(unknown)))
        assert.is_false((TT.Alerts.IsHealer("player")))
    end)
end)
