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

-- Which frames are beats rather than steps. Nothing downstream reads this yet,
-- and that is exactly why it needs checking: it is carried through the motion
-- and into the draw list on the strength of being right here, and the motion
-- work that follows will decide where a freeze goes by asking it. A field that
-- nothing reads is a field that can quietly become wrong.

function TestSampler:testTheHeldFramesAreTheOnesAtEitherEnd()
  local frames = sampler.sample {
    frameCount = 4,
    curve = "linear",
    holdFirst = 2,
    holdLast = 3,
  }

  local marks = {}
  for index, frame in ipairs(frames) do
    marks[index] = frame.held and "h" or "-"
  end
  -- Two beats, then four steps, then three beats.
  luaunit.assertEquals(table.concat(marks), "hh----hhh")
end

function TestSampler:testAMotionWithNoHoldsHasNoHeldFrames()
  local frames = sampler.sample { frameCount = 5, curve = "linear" }
  for index, frame in ipairs(frames) do
    luaunit.assertFalse(frame.held, "frame " .. index .. " claims to be a held beat")
  end
end

function TestSampler:testAHeldFrameIsTheOneThatLastsLonger()
  -- The mark and the duration have to agree, or a later reader will trust one
  -- and get the other. Every held frame lasts the multiplier longer, and no
  -- moving frame does.
  local base = 40
  local multiplier = 3
  local frames = sampler.sample {
    frameCount = 3,
    curve = "linear",
    holdFirst = 1,
    holdLast = 1,
    baseDuration = base,
    holdMultiplier = multiplier,
  }

  for index, frame in ipairs(frames) do
    local expected = frame.held and (base * multiplier) or base
    luaunit.assertAlmostEquals(
      frame.duration,
      expected,
      EPSILON,
      "frame " .. index .. " is marked " .. tostring(frame.held) .. " but lasts " .. frame.duration
    )
  end
end

function TestSampler:testAHeldFrameSitsAtOneEndOfTheTravelOrTheOther()
  -- A beat is a pause, so nothing may have moved during it: the ones at the
  -- start are still at the beginning and the ones at the end have arrived.
  local frames = sampler.sample {
    frameCount = 3,
    curve = "quadOut",
    holdFirst = 2,
    holdLast = 2,
  }
  for index, frame in ipairs(frames) do
    if frame.held then
      local atAnEnd = math.abs(frame.progress) < EPSILON or math.abs(frame.progress - 1) < EPSILON
      luaunit.assertTrue(
        atAnEnd,
        "held frame " .. index .. " is part way along at " .. frame.progress
      )
    end
  end
end

return { TestSampler = TestSampler }
