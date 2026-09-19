-- Frame sampling.
--
-- Turns a continuous curve into the handful of frames a pixel art animation
-- actually has. Two things make this more than dividing a line into equal
-- parts:
--
-- Frames do not have to last the same time. Holding the extremes longer is how
-- a short animation reads as deliberate rather than rushed, and it is why a
-- four frame action can feel like twelve.
--
-- The endpoints must land exactly. A dash that stops a fraction short of its
-- target looks like a mistake, so the first and last positions are pinned
-- rather than sampled.

local easing = require("core.easing")

local M = {}

local DEFAULT_BASE_DURATION = 100
local DEFAULT_HOLD_MULTIPLIER = 2

local function resolveCurve(curve)
  if type(curve) == "function" then
    return curve
  end
  return easing.byName(curve or "linear")
end

local function requireNonNegative(value, label)
  if value < 0 then
    error(label .. " cannot be negative", 3)
  end
end

--- Sample a curve into frames.
-- @param options table
--   frameCount      number  moving frames, at least two
--   curve           string|function  name from the curve set, or a function
--   holdFirst       number  extra repeats of the first frame (default 0)
--   holdLast        number  extra repeats of the last frame (default 0)
--   baseDuration    number  milliseconds a moving frame lasts (default 100)
--   holdMultiplier  number  how much longer a held frame lasts (default 2)
-- @return table  list of { progress = number, duration = number, held = bool }
function M.sample(options)
  local frameCount = options.frameCount or 0
  if frameCount < 2 then
    error("a sampled motion needs at least two frames", 2)
  end

  local holdFirst = options.holdFirst or 0
  local holdLast = options.holdLast or 0
  requireNonNegative(holdFirst, "holdFirst")
  requireNonNegative(holdLast, "holdLast")

  local baseDuration = options.baseDuration or DEFAULT_BASE_DURATION
  local holdMultiplier = options.holdMultiplier or DEFAULT_HOLD_MULTIPLIER
  local curve = resolveCurve(options.curve)

  local frames = {}

  for _ = 1, holdFirst do
    frames[#frames + 1] = {
      progress = 0,
      duration = baseDuration * holdMultiplier,
      held = true,
    }
  end

  for index = 0, frameCount - 1 do
    local progress
    if index == 0 then
      progress = 0
    elseif index == frameCount - 1 then
      progress = 1
    else
      progress = curve(index / (frameCount - 1))
    end

    frames[#frames + 1] = {
      progress = progress,
      duration = baseDuration,
      held = false,
    }
  end

  for _ = 1, holdLast do
    frames[#frames + 1] = {
      progress = 1,
      duration = baseDuration * holdMultiplier,
      held = true,
    }
  end

  return frames
end

return M
