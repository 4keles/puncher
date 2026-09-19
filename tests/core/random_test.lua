local luaunit = require("luaunit")
local random = require("core.random")

local TestRandom = {}

local function collect(source, count)
  local values = {}
  for _ = 1, count do
    values[#values + 1] = source:float()
  end
  return values
end

function TestRandom:testTheSameSeedGivesTheSameSequence()
  local first = collect(random.new(12345), 20)
  local second = collect(random.new(12345), 20)
  luaunit.assertEquals(first, second)
end

function TestRandom:testDifferentSeedsDiverge()
  local first = collect(random.new(1), 20)
  local second = collect(random.new(2), 20)
  luaunit.assertNotEquals(first, second)
end

function TestRandom:testFloatsStayInsideTheUnitRange()
  local source = random.new(99)
  for _ = 1, 500 do
    local value = source:float()
    luaunit.assertTrue(value >= 0, "float fell below zero")
    luaunit.assertTrue(value < 1, "float reached one")
  end
end

function TestRandom:testRangeRespectsItsBounds()
  local source = random.new(7)
  for _ = 1, 500 do
    local value = source:range(-3, 8)
    luaunit.assertTrue(value >= -3 and value <= 8, "range escaped its bounds")
  end
end

function TestRandom:testIntegersRespectTheirBoundsAndAreWhole()
  local source = random.new(4242)
  for _ = 1, 500 do
    local value = source:integer(2, 5)
    luaunit.assertEquals(value, math.floor(value))
    luaunit.assertTrue(value >= 2 and value <= 5, "integer escaped its bounds")
  end
end

function TestRandom:testIntegersEventuallyCoverTheirWholeRange()
  local source = random.new(31337)
  local seen = {}
  for _ = 1, 500 do
    seen[source:integer(1, 4)] = true
  end
  for value = 1, 4 do
    luaunit.assertTrue(seen[value], "value " .. value .. " never came up")
  end
end

function TestRandom:testAZeroSeedStillProducesMovement()
  local source = random.new(0)
  local first = source:float()
  local second = source:float()
  luaunit.assertNotEquals(first, second)
end

function TestRandom:testReseedingRestartsTheSequence()
  local source = random.new(500)
  local before = source:float()
  source:reseed(500)
  luaunit.assertEquals(source:float(), before)
end

return { TestRandom = TestRandom }
