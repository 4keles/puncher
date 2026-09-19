local luaunit = require("luaunit")
local transform = require("core.transform")

local EPSILON = 1e-9

local TestTransform = {}

function TestTransform:testIdentityLeavesAPointAlone()
  local point = transform.apply(transform.identity(), { x = 3, y = -7 })
  luaunit.assertAlmostEquals(point.x, 3, EPSILON)
  luaunit.assertAlmostEquals(point.y, -7, EPSILON)
end

function TestTransform:testTranslationMoves()
  local point = transform.apply(transform.translate(10, -4), { x = 1, y = 1 })
  luaunit.assertAlmostEquals(point.x, 11, EPSILON)
  luaunit.assertAlmostEquals(point.y, -3, EPSILON)
end

function TestTransform:testScaleStretches()
  local point = transform.apply(transform.scale(2, 0.5), { x = 3, y = 8 })
  luaunit.assertAlmostEquals(point.x, 6, EPSILON)
  luaunit.assertAlmostEquals(point.y, 4, EPSILON)
end

function TestTransform:testQuarterTurnRotatesAxes()
  local point = transform.apply(transform.rotate(math.pi / 2), { x = 1, y = 0 })
  luaunit.assertAlmostEquals(point.x, 0, 1e-12)
  luaunit.assertAlmostEquals(point.y, 1, 1e-12)
end

function TestTransform:testCompositionAppliesTheSecondFirst()
  local move = transform.translate(5, 0)
  local grow = transform.scale(2, 2)

  local combined = transform.compose(move, grow)
  local stepByStep = transform.apply(move, transform.apply(grow, { x = 3, y = 1 }))
  local inOneGo = transform.apply(combined, { x = 3, y = 1 })

  luaunit.assertAlmostEquals(inOneGo.x, stepByStep.x, EPSILON)
  luaunit.assertAlmostEquals(inOneGo.y, stepByStep.y, EPSILON)
end

function TestTransform:testSnapProducesWholeNumbers()
  local point = transform.snap { x = 3.4, y = -2.5 }
  luaunit.assertEquals(point.x, math.floor(point.x))
  luaunit.assertEquals(point.y, math.floor(point.y))
  luaunit.assertEquals(point.x, 3)
end

local TestAccumulator = {}

function TestAccumulator:testEmitsWholeNumbers()
  local accumulator = transform.newAccumulator()
  for _ = 1, 20 do
    local step = accumulator:step(0.37)
    luaunit.assertEquals(step, math.floor(step))
  end
end

function TestAccumulator:testTotalDoesNotDriftOverALongSequence()
  local accumulator = transform.newAccumulator()
  local total = 0
  local steps = 300
  local perStep = 0.1

  for _ = 1, steps do
    total = total + accumulator:step(perStep)
  end

  -- Naive rounding of each step would have produced zero movement over the
  -- whole sequence; carrying the remainder keeps the total honest.
  luaunit.assertAlmostEquals(total, steps * perStep, 0.5)
end

function TestAccumulator:testHandlesNegativeMovement()
  local accumulator = transform.newAccumulator()
  local total = 0
  for _ = 1, 100 do
    total = total + accumulator:step(-0.25)
  end
  luaunit.assertAlmostEquals(total, -25, 0.5)
end

function TestAccumulator:testCarryStaysSmall()
  local accumulator = transform.newAccumulator()
  for _ = 1, 50 do
    accumulator:step(0.6)
    luaunit.assertTrue(math.abs(accumulator.carry) <= 0.5 + EPSILON, "carry grew unbounded")
  end
end

function TestAccumulator:testResetClearsTheCarry()
  local accumulator = transform.newAccumulator()
  accumulator:step(0.4)
  accumulator:reset()
  luaunit.assertAlmostEquals(accumulator.carry, 0, EPSILON)
end

return { TestTransform = TestTransform, TestAccumulator = TestAccumulator }
