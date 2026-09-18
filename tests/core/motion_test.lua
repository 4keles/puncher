local luaunit = require("luaunit")
local motion = require("core.motion")

local TestMotion = {}

function TestMotion:testProducesOneStepPerFrame()
  local path = motion.linear { frameCount = 6, distance = 30, curve = "linear" }
  luaunit.assertEquals(#path, 6)
end

function TestMotion:testEveryOffsetIsAWholePixel()
  local path = motion.linear { frameCount = 9, distance = 25, curve = "cubicOut" }
  for index, step in ipairs(path) do
    luaunit.assertEquals(step.x, math.floor(step.x), "frame " .. index .. " is not on the grid")
    luaunit.assertEquals(step.y, math.floor(step.y), "frame " .. index .. " is not on the grid")
  end
end

function TestMotion:testStartsAtZeroAndLandsExactlyOnTheTarget()
  local path = motion.linear { frameCount = 11, distance = 37, curve = "quadOut" }
  luaunit.assertEquals(path[1].x, 0)
  luaunit.assertEquals(path[#path].x, 37)
end

function TestMotion:testLandsExactlyForManyAwkwardDistances()
  for distance = 1, 60 do
    local path = motion.linear { frameCount = 7, distance = distance, curve = "cubicOut" }
    luaunit.assertEquals(path[#path].x, distance, "missed the target for distance " .. distance)
  end
end

function TestMotion:testNegativeDistanceTravelsBackwards()
  local path = motion.linear { frameCount = 8, distance = -24, curve = "linear" }
  luaunit.assertEquals(path[#path].x, -24)
  for index = 2, #path do
    luaunit.assertTrue(path[index].x <= path[index - 1].x, "moved forwards during a backwards dash")
  end
end

function TestMotion:testVerticalMotionUsesTheVerticalAxis()
  local path = motion.linear { frameCount = 5, distance = 20, curve = "linear", axis = "y" }
  luaunit.assertEquals(path[#path].y, 20)
  luaunit.assertEquals(path[#path].x, 0)
end

function TestMotion:testEachStepCarriesItsDuration()
  local path = motion.linear { frameCount = 5, distance = 10, curve = "linear", baseDuration = 40 }
  for _, step in ipairs(path) do
    luaunit.assertEquals(step.duration, 40)
  end
end

function TestMotion:testHeldBeatsAreIncludedAndDoNotMove()
  local path = motion.linear {
    frameCount = 5,
    distance = 10,
    curve = "linear",
    holdFirst = 2,
    holdLast = 1,
  }
  luaunit.assertEquals(#path, 8)
  luaunit.assertEquals(path[1].x, 0)
  luaunit.assertEquals(path[2].x, 0)
  luaunit.assertEquals(path[#path].x, 10)
end

function TestMotion:testAJumpRisesAndReturns()
  local path = motion.jump { frameCount = 9, distance = 24, height = 16 }
  luaunit.assertEquals(path[1].y, 0)
  luaunit.assertEquals(path[#path].y, 0)
  luaunit.assertEquals(path[#path].x, 24)

  local highest = 0
  for _, step in ipairs(path) do
    highest = math.min(highest, step.y)
  end
  -- Up is a smaller vertical coordinate, which is how the application counts.
  luaunit.assertTrue(highest < 0, "the jump never left the ground")
  luaunit.assertTrue(highest >= -16, "the jump rose higher than it was asked to")
end

function TestMotion:testAMissingDistanceIsRejected()
  luaunit.assertErrorMsgContains("distance", motion.linear, { frameCount = 5 })
end

return { TestMotion = TestMotion }
