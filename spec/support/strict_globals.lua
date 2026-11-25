-- busted helper (see .busted): fails every test after which a fake world built during
-- that test lists a global the addon read but the world lacks (world.missing). This
-- catches reads that a pcall in the addon swallowed. A test that reads an unknown
-- global on purpose must empty world.missing itself. A world built in setup() and reused
-- across tests is never checked, so build every world per test (before_each or the test).
--
-- Required here, before any spec file, so every spec shares this module's world list.
local wow = require("spec.support.wow")

-- busted calls the returned function with itself; the after_each lands on the root
-- context, so it runs after every test in every spec file.
return function(busted)
    busted.executors.after_each(function()
        local worlds = wow.worlds
        wow.worlds = {}
        local missing = {}
        for _, world in ipairs(worlds) do
            for _, name in ipairs(world.missing) do missing[#missing + 1] = name end
        end
        if #missing > 0 then
            error("addon read globals the fake world lacks: " .. table.concat(missing, ", "), 0)
        end
    end)
    return true
end
