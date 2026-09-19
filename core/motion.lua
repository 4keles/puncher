-- Motion paths.
--
-- This is where the separate pieces of the core become a usable answer: a
-- curve decides the pacing, the sampler turns it into frames, and the
-- accumulator turns real positions into whole pixels without losing the
-- fractions along the way.
--
-- What comes out is plain data - a list of per-frame offsets and durations -
-- and nothing here knows what will draw it.

local sampler = require("core.sampler")
local transform = require("core.transform")
local arc = require("core.arc")

local M = {}

local DEFAULT_CURVE = "cubicOut"

local function requireNumber(value, label)
  if type(value) ~= "number" then
    error("a motion path needs a " .. label, 3)
  end
end

--- Walk a sampled curve, converting progress into whole-pixel offsets.
-- The accumulator carries each rounding remainder into the next frame, and the
-- final frame is pinned to the exact target so a motion always lands where it
-- was asked to.
local function offsetsAlong(frames, distance)
  local accumulator = transform.newAccumulator()
  local position = 0
  local offsets = {}

  for index, frame in ipairs(frames) do
    local target = frame.progress * distance
    position = position + accumulator:step(target - position)

    if index == #frames then
      position = distance
    end

    offsets[index] = position
  end

  return offsets
end

--- A straight move along one axis.
-- @param options table
--   frameCount, distance, curve, axis ("x" or "y"),
--   holdFirst, holdLast, baseDuration, holdMultiplier
-- @return table  list of { x = number, y = number, duration = number, held = bool }
function M.linear(options)
  requireNumber(options.distance, "distance")

  local frames = sampler.sample {
    frameCount = options.frameCount,
    curve = options.curve or DEFAULT_CURVE,
    holdFirst = options.holdFirst,
    holdLast = options.holdLast,
    baseDuration = options.baseDuration,
    holdMultiplier = options.holdMultiplier,
  }

  local axis = options.axis or "x"
  local offsets = offsetsAlong(frames, options.distance)
  local path = {}

  for index, frame in ipairs(frames) do
    path[index] = {
      x = (axis == "x") and offsets[index] or 0,
      y = (axis == "y") and offsets[index] or 0,
      duration = frame.duration,
      held = frame.held,
      -- How far along its curve this frame sits. Carried out with the step
      -- because anything layered on top of a path - a height, a rotation, a
      -- scale - needs the same number, and re-deriving it from the frame's
      -- position in the list is wrong the moment hold frames exist.
      progress = frame.progress,
    }
  end

  return path
end

--- A move that travels forward while rising and falling.
-- Height is subtracted rather than added: on a canvas, up is the smaller
-- vertical coordinate. The height of each frame follows the progress the
-- sampler gave it, not the frame's position in the list: a held frame repeats
-- an extreme, so it must stay at that extreme's height rather than being
-- lifted part way up the arc.
-- @param options table  as for a straight move, plus height
function M.jump(options)
  requireNumber(options.distance, "distance")
  requireNumber(options.height, "height")

  local path = M.linear {
    frameCount = options.frameCount,
    distance = options.distance,
    curve = options.curve or "linear",
    holdFirst = options.holdFirst,
    holdLast = options.holdLast,
    baseDuration = options.baseDuration,
    holdMultiplier = options.holdMultiplier,
  }

  for _, step in ipairs(path) do
    step.y = -math.floor(arc.parabola(options.height, step.progress) + 0.5)
  end

  return path
end

return M
