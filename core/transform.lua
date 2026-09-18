-- Transforms, pixel snapping and the sub-pixel accumulator.
--
-- Two ideas live here. The first is ordinary: move, scale and rotate points,
-- and combine those operations into one.
--
-- The second is the one pixel art cannot do without. Positions are computed as
-- real numbers but drawn on a whole-number grid, and rounding each frame
-- independently throws away a fraction every time. Over a dozen frames those
-- discarded fractions add up to a motion that stops short of where it was
-- supposed to land. The accumulator carries the remainder forward, so the
-- rounding error stays under half a pixel no matter how long the sequence is.

local M = {}

-- A transform is stored as the six meaningful numbers of a 2x3 matrix:
--   x' = a * x + c * y + tx
--   y' = b * x + d * y + ty
local function newTransform(a, b, c, d, tx, ty)
  return { a = a, b = b, c = c, d = d, tx = tx, ty = ty }
end

function M.identity()
  return newTransform(1, 0, 0, 1, 0, 0)
end

function M.translate(x, y)
  return newTransform(1, 0, 0, 1, x, y)
end

function M.scale(x, y)
  return newTransform(x, 0, 0, y, 0, 0)
end

function M.rotate(radians)
  local cos = math.cos(radians)
  local sin = math.sin(radians)
  return newTransform(cos, sin, -sin, cos, 0, 0)
end

--- Combine two transforms. The second is applied first, matching how the two
-- would read if written out as nested calls.
function M.compose(outer, inner)
  return newTransform(
    outer.a * inner.a + outer.c * inner.b,
    outer.b * inner.a + outer.d * inner.b,
    outer.a * inner.c + outer.c * inner.d,
    outer.b * inner.c + outer.d * inner.d,
    outer.a * inner.tx + outer.c * inner.ty + outer.tx,
    outer.b * inner.tx + outer.d * inner.ty + outer.ty
  )
end

function M.apply(t, point)
  return {
    x = t.a * point.x + t.c * point.y + t.tx,
    y = t.b * point.x + t.d * point.y + t.ty,
  }
end

local function round(value)
  return math.floor(value + 0.5)
end

--- Put a point on the pixel grid.
function M.snap(point)
  return { x = round(point.x), y = round(point.y) }
end

local Accumulator = {}
Accumulator.__index = Accumulator

--- Convert a real movement into a whole-pixel movement, remembering what was
-- left over so it is not silently lost.
function Accumulator:step(amount)
  self.carry = self.carry + amount
  local whole = round(self.carry)
  self.carry = self.carry - whole
  return whole
end

function Accumulator:reset()
  self.carry = 0
end

function M.newAccumulator()
  return setmetatable({ carry = 0 }, Accumulator)
end

return M
