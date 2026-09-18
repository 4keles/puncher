-- Easing curves.
--
-- Each curve maps normalized time in [0, 1] to normalized progress. Progress
-- is not always inside that range: an overshoot curve deliberately passes its
-- target and settles back, which is what gives a motion its snap.
--
-- Input is clamped, so a caller that produces a slightly out-of-range time
-- through floating point division gets the endpoint rather than a surprise.

local M = {}

-- The classic overshoot constant. It decides how far past the target a back
-- curve travels; larger values exaggerate the snap.
local BACK_OVERSHOOT = 1.70158
local BACK_SCALED = BACK_OVERSHOOT + 1

local function clamp(t)
  if t < 0 then
    return 0
  end
  if t > 1 then
    return 1
  end
  return t
end

M.curves = {}

function M.curves.linear(t)
  return clamp(t)
end

function M.curves.quadIn(t)
  t = clamp(t)
  return t * t
end

function M.curves.quadOut(t)
  t = clamp(t)
  local inverse = 1 - t
  return 1 - inverse * inverse
end

function M.curves.quadInOut(t)
  t = clamp(t)
  if t < 0.5 then
    return 2 * t * t
  end
  local inverse = -2 * t + 2
  return 1 - (inverse * inverse) / 2
end

function M.curves.cubicIn(t)
  t = clamp(t)
  return t * t * t
end

function M.curves.cubicOut(t)
  t = clamp(t)
  local inverse = 1 - t
  return 1 - inverse * inverse * inverse
end

function M.curves.cubicInOut(t)
  t = clamp(t)
  if t < 0.5 then
    return 4 * t * t * t
  end
  local inverse = -2 * t + 2
  return 1 - (inverse * inverse * inverse) / 2
end

function M.curves.expoIn(t)
  t = clamp(t)
  if t == 0 then
    return 0
  end
  return 2 ^ (10 * t - 10)
end

function M.curves.expoOut(t)
  t = clamp(t)
  if t == 1 then
    return 1
  end
  return 1 - 2 ^ (-10 * t)
end

-- Travels past the target and settles back. Use it where a motion should feel
-- like it carried momentum into its landing.
function M.curves.backOut(t)
  t = clamp(t)
  local shifted = t - 1
  return 1 + BACK_SCALED * shifted * shifted * shifted + BACK_OVERSHOOT * shifted * shifted
end

function M.byName(name)
  local curve = M.curves[name]
  if not curve then
    error("unknown easing curve: " .. tostring(name), 2)
  end
  return curve
end

return M
