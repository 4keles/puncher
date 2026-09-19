local luaunit = require("luaunit")
local sampler = require("core.sampler")

local EPSILON = 1e-9

local TestSampler = {}

function TestSampler:testProducesTheRequestedNumberOfFrames()
  local frames = sampler.sample { frameCount = 8, curve = "linear" }
  luaunit.assertEquals(#frames, 8)
end

function TestSampler:testHoldFramesAddToTheTotal()
  local frames = sampler.sample {
    frameCount = 6,
    curve = "linear",
    holdFirst = 2,
    holdLast = 3,
  }
  luaunit.assertEquals(#frames, 11)
end

function TestSampler:testFirstAndLastProgressAreExact()
  local frames = sampler.sample { frameCount = 5, curve = "cubicOut" }
  luaunit.assertAlmostEquals(frames[1].progress, 0, EPSILON)
  luaunit.assertAlmostEquals(frames[#frames].progress, 1, EPSILON)
end

function TestSampler:testHoldFramesRepeatTheExtremes()
  local frames = sampler.sample {
    frameCount = 4,
    curve = "linear",
    holdFirst = 2,
    holdLast = 2,
  }
  luaunit.assertAlmostEquals(frames[1].progress, 0, EPSILON)
  luaunit.assertAlmostEquals(frames[2].progress, 0, EPSILON)
  luaunit.assertAlmostEquals(frames[#frames].progress, 1, EPSILON)
  luaunit.assertAlmostEquals(frames[#frames - 1].progress, 1, EPSILON)
end

function TestSampler:testProgressNeverMovesBackwards()
  local frames = sampler.sample { frameCount = 12, curve = "quadInOut" }
  for index = 2, #frames do
    luaunit.assertTrue(
      frames[index].progress >= frames[index - 1].progress - EPSILON,
      "progress went backwards at frame " .. index
    )
  end
end

function TestSampler:testDurationsCanDifferBetweenHeldAndMovingFrames()
  local frames = sampler.sample {
    frameCount = 4,
    curve = "linear",
    holdFirst = 1,
    baseDuration = 100,
    holdMultiplier = 3,
  }
  luaunit.assertEquals(frames[1].duration, 300)
  luaunit.assertEquals(frames[2].duration, 100)
end

function TestSampler:testEveryFrameCarriesAPositiveDuration()
  local frames = sampler.sample { frameCount = 6, curve = "linear", baseDuration = 50 }
  for index, frame in ipairs(frames) do
    luaunit.assertTrue(frame.duration > 0, "frame " .. index .. " has no duration")
  end
end

function TestSampler:testACurveCanBePassedDirectly()
  local frames = sampler.sample {
    frameCount = 3,
    curve = function(t)
      return t
    end,
  }
  luaunit.assertAlmostEquals(frames[2].progress, 0.5, EPSILON)
end

function TestSampler:testFewerThanTwoFramesIsRejected()
  luaunit.assertErrorMsgContains("at least two frames", sampler.sample, {
    frameCount = 1,
    curve = "linear",
  })
end

function TestSampler:testNegativeHoldIsRejected()
  luaunit.assertErrorMsgContains("cannot be negative", sampler.sample, {
    frameCount = 4,
    curve = "linear",
    holdFirst = -1,
  })
end

return { TestSampler = TestSampler }
