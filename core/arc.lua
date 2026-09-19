-- Arcs.
--
-- Motion that travels in a straight line reads as mechanical. A jump, a swing
-- and a thrown body all follow curves, and these are the two shapes that cover
-- almost every case in an action animation: a bent path between two points,
-- and the rise and fall of something thrown.

local unit = require("core.unit")

local M = {}

--- A point along a quadratic curve.
-- The control point is not passed through; it pulls the path towards itself,
-- and the middle of the curve ends up a quarter of the way between the
-- straight chord and that point.
-- @param start table  { x = number, y = number }
-- @param control table  the point that bends the path
-- @param finish table  { x = number, y = number }
-- @param t number  normalized time, clamped to [0, 1]
-- @return table  { x = number, y = number }
function M.quadratic(start, control, finish, t)
  t = unit.clamp(t)
  local inverse = 1 - t
  local a = inverse * inverse
  local b = 2 * inverse * t
  local c = t * t

  return {
    x = a * start.x + b * control.x + c * finish.x,
    y = a * start.y + b * control.y + c * finish.y,
  }
end

--- Height above the ground for something thrown, at normalized time.
-- Zero at both ends, peaking at the given height halfway through. The sign is
-- left to the caller, because whether up means a smaller or larger coordinate
-- depends on where this lands.
-- @param height number  peak height
-- @param t number  normalized time, clamped to [0, 1]
-- @return number
function M.parabola(height, t)
  t = unit.clamp(t)
  return 4 * height * t * (1 - t)
end

return M
