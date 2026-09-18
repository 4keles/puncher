local luaunit = require("luaunit")
local arc = require("core.arc")

local EPSILON = 1e-9

local TestArc = {}

function TestArc:testQuadraticPassesThroughItsEndpoints()
  local start = { x = 0, y = 0 }
  local control = { x = 5, y = 10 }
  local finish = { x = 10, y = 0 }

  local first = arc.quadratic(start, control, finish, 0)
  local last = arc.quadratic(start, control, finish, 1)

  luaunit.assertAlmostEquals(first.x, 0, EPSILON)
  luaunit.assertAlmostEquals(first.y, 0, EPSILON)
  luaunit.assertAlmostEquals(last.x, 10, EPSILON)
  luaunit.assertAlmostEquals(last.y, 0, EPSILON)
end

function TestArc:testControlPointPullsTheMiddleTowardsIt()
  local start = { x = 0, y = 0 }
  local control = { x = 5, y = 10 }
  local finish = { x = 10, y = 0 }

  local middle = arc.quadratic(start, control, finish, 0.5)

  -- The midpoint of a quadratic sits a quarter of the way between the straight
  -- chord and the control point, not on the control point itself.
  luaunit.assertAlmostEquals(middle.x, 5, EPSILON)
  luaunit.assertAlmostEquals(middle.y, 5, EPSILON)
end

function TestArc:testStraightControlPointGivesAStraightLine()
  local start = { x = 0, y = 0 }
  local control = { x = 5, y = 0 }
  local finish = { x = 10, y = 0 }

  for step = 0, 10 do
    local t = step / 10
    local point = arc.quadratic(start, control, finish, t)
    luaunit.assertAlmostEquals(point.y, 0, EPSILON)
    luaunit.assertAlmostEquals(point.x, t * 10, EPSILON)
  end
end

function TestArc:testParabolaIsZeroAtBothEnds()
  luaunit.assertAlmostEquals(arc.parabola(16, 0), 0, EPSILON)
  luaunit.assertAlmostEquals(arc.parabola(16, 1), 0, EPSILON)
end

function TestArc:testParabolaPeaksAtItsHeightHalfway()
  luaunit.assertAlmostEquals(arc.parabola(16, 0.5), 16, EPSILON)
end

function TestArc:testParabolaIsSymmetric()
  for step = 0, 10 do
    local t = step / 10
    luaunit.assertAlmostEquals(arc.parabola(9, t), arc.parabola(9, 1 - t), EPSILON)
  end
end

function TestArc:testParabolaNeverExceedsItsHeight()
  for step = 0, 100 do
    local value = arc.parabola(7, step / 100)
    luaunit.assertTrue(value <= 7 + EPSILON, "parabola rose above its height")
    luaunit.assertTrue(value >= -EPSILON, "parabola dipped below zero")
  end
end

function TestArc:testTimeIsClamped()
  luaunit.assertAlmostEquals(arc.parabola(10, -1), 0, EPSILON)
  luaunit.assertAlmostEquals(arc.parabola(10, 2), 0, EPSILON)

  local point = arc.quadratic({ x = 0, y = 0 }, { x = 1, y = 1 }, { x = 2, y = 0 }, 5)
  luaunit.assertAlmostEquals(point.x, 2, EPSILON)
end

return { TestArc = TestArc }
