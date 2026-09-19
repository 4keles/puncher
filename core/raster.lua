-- Moving pixels without inventing any.
--
-- Every routine here takes a picture and returns a new one of the same size.
-- None of them blends: each output pixel is a value that was already in the
-- input, or nothing. That is not an aesthetic preference. On an indexed sprite
-- a blended value cannot even be represented, and on any sprite it is a colour
-- the artist never chose, which is what makes a transformed pixel look wrong
-- next to an untransformed one.
--
-- Anything pushed outside the picture is dropped. Nothing wraps.

local matrix = require("core.matrix")

local M = {}

-- The two mirrors that cost nothing: a picture flipped about a vertical or a
-- horizontal line lands exactly on the pixel grid it came from. A mirror about
-- any other line does not, which is why there are only two.
M.AXES = {
  horizontal = true,
  vertical = true,
}

local function requireWholeNumber(value, label)
  if value % 1 ~= 0 then
    error(("%s must be a whole number of pixels, not %s"):format(label, tostring(value)), 3)
  end
end

--- Round to the nearest whole pixel, away from zero on a tie.
-- Which way a tie goes is invisible at this scale, but it has to be decided
-- once so the same input always produces the same picture.
local function round(value)
  if value >= 0 then
    return math.floor(value + 0.5)
  end
  return -math.floor(-value + 0.5)
end

--- Move every pixel by the same whole number of pixels.
-- @tparam table source
-- @tparam number dx
-- @tparam number dy
-- @treturn table a new matrix
function M.translate(source, dx, dy)
  requireWholeNumber(dx, "a horizontal translation")
  requireWholeNumber(dy, "a vertical translation")

  local result = matrix.new(source.width, source.height, source.transparent)
  matrix.blit(result, source, dx, dy)
  return result
end

--- Flip a picture about its own centre line.
-- @tparam table source
-- @tparam string axis  "horizontal" or "vertical"
-- @treturn table a new matrix
function M.mirror(source, axis)
  if not M.AXES[axis] then
    error(
      ("a picture can be mirrored horizontally or vertically, not %s"):format(tostring(axis)),
      2
    )
  end

  local result = matrix.new(source.width, source.height, source.transparent)

  for y = 0, source.height - 1 do
    for x = 0, source.width - 1 do
      local sourceX = (axis == "horizontal") and (source.width - 1 - x) or x
      local sourceY = (axis == "vertical") and (source.height - 1 - y) or y
      result:set(x, y, source:get(sourceX, sourceY))
    end
  end

  return result
end

--- Lean a picture by displacing whole rows.
-- A true affine shear samples between pixels and blurs the result. This does
-- not shear the pixels at all: it slides each row sideways by a whole number,
-- so the picture leans while every pixel stays exactly itself. Rows near each
-- other therefore share a displacement rather than landing between two, which
-- is the staircase a pixel artist would draw by hand.
-- @tparam table source
-- @tparam table options  factor, and the row the lean pivots about
-- @treturn table a new matrix
function M.shear(source, options)
  local factor = options.factor or 0
  local pivotRow = options.pivotRow or 0

  local result = matrix.new(source.width, source.height, source.transparent)

  for y = 0, source.height - 1 do
    local offset = round(factor * (y - pivotRow))
    for x = 0, source.width - 1 do
      result:set(x + offset, y, source:get(x, y))
    end
  end

  return result
end

return M
