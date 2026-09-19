local luaunit = require("luaunit")
local unit = require("core.unit")

local TestUnit = {}

function TestUnit:testAValueInsideTheRangeIsUntouched()
  luaunit.assertEquals(unit.clamp(0.25), 0.25)
  luaunit.assertEquals(unit.clamp(0), 0)
  luaunit.assertEquals(unit.clamp(1), 1)
end

function TestUnit:testBelowTheRangeBecomesTheStart()
  luaunit.assertEquals(unit.clamp(-0.5), 0)
  luaunit.assertEquals(unit.clamp(-1000), 0)
end

function TestUnit:testAboveTheRangeBecomesTheEnd()
  luaunit.assertEquals(unit.clamp(1.2), 1)
  luaunit.assertEquals(unit.clamp(1000), 1)
end

return { TestUnit = TestUnit }
