-- A picture, as plain data.
--
-- The application's images cannot be reasoned about outside the application,
-- and the core layer is not allowed to touch them. So the two sides agree on
-- this instead: a width, a height, a value standing for nothing, and one value
-- per pixel. The adapter fills one of these from a cel and writes one back;
-- everything between those two points is arithmetic this layer can test with
-- no editor running.
--
-- Coordinates start at zero and run to one less than the dimension, matching
-- how the application addresses its own images. Getting that wrong by one is
-- the classic raster mistake, so there is only ever one convention.

local M = {}

-- What a pixel holds when nothing has been drawn there. Zero is the
-- application's own transparent index, so the common case needs no argument.
M.DEFAULT_TRANSPARENT = 0

local Matrix = {}
Matrix.__index = Matrix

--- Whether a coordinate is inside the picture.
function Matrix:contains(x, y)
  return x >= 0 and y >= 0 and x < self.width and y < self.height
end

--- The value at a coordinate, or nothing when the coordinate is outside.
-- Reading past the edge is not a mistake: a transform sampling its source
-- will ask about places the source does not reach, and the honest answer
-- there is that nothing is drawn.
function Matrix:get(x, y)
  if not self:contains(x, y) then
    return self.transparent
  end
  return self.pixels[y * self.width + x + 1]
end

--- Write a value, ignoring a coordinate outside the picture.
-- Ignoring rather than growing keeps a matrix the size it was declared to be,
-- which is what everything downstream assumes.
function Matrix:set(x, y, value)
  if not self:contains(x, y) then
    return
  end
  self.pixels[y * self.width + x + 1] = value
end

--- A new picture with nothing drawn on it.
-- @tparam number width
-- @tparam number height
-- @tparam ?number transparent  what stands for nothing
-- @treturn table
function M.new(width, height, transparent)
  if width < 0 or height < 0 then
    error("a matrix cannot have a negative width or height", 2)
  end

  transparent = transparent or M.DEFAULT_TRANSPARENT

  local pixels = {}
  for index = 1, width * height do
    pixels[index] = transparent
  end

  return setmetatable({
    width = width,
    height = height,
    transparent = transparent,
    pixels = pixels,
  }, Matrix)
end

--- An independent copy.
function M.clone(source)
  local copy = M.new(source.width, source.height, source.transparent)
  for index = 1, source.width * source.height do
    copy.pixels[index] = source.pixels[index]
  end
  return copy
end

--- Draw one picture onto another at an offset.
-- Where the source holds nothing, the destination keeps what it had: this is
-- compositing, not overwriting, because a part drawn over a body must not
-- punch a rectangular hole in it. Anything falling outside the destination is
-- dropped rather than wrapping.
function M.blit(destination, source, offsetX, offsetY)
  for y = 0, source.height - 1 do
    for x = 0, source.width - 1 do
      local value = source:get(x, y)
      if value ~= source.transparent then
        destination:set(x + offsetX, y + offsetY, value)
      end
    end
  end
  return destination
end

--- The smallest rectangle holding everything that is drawn.
-- @treturn ?table { x, y, width, height }, or nil when nothing is drawn
function M.shrinkBounds(source)
  local left, top, right, bottom

  for y = 0, source.height - 1 do
    for x = 0, source.width - 1 do
      if source:get(x, y) ~= source.transparent then
        left = (left and math.min(left, x)) or x
        right = (right and math.max(right, x)) or x
        top = (top and math.min(top, y)) or y
        bottom = (bottom and math.max(bottom, y)) or y
      end
    end
  end

  if not left then
    return nil
  end

  return {
    x = left,
    y = top,
    width = right - left + 1,
    height = bottom - top + 1,
  }
end

--- Every value the picture uses, each once, ignoring what stands for nothing.
-- This is what makes "a transform must not invent a colour" a thing a test
-- can check rather than a thing a comment claims.
function M.colours(source)
  local seen = {}
  local found = {}

  for index = 1, source.width * source.height do
    local value = source.pixels[index]
    if value ~= source.transparent and not seen[value] then
      seen[value] = true
      found[#found + 1] = value
    end
  end

  return found
end

return M
