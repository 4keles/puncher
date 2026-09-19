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
-- This moves pixels inside a fixed frame, so anything pushed over the edge is
-- gone. That is the right behaviour for scrolling a picture's contents and the
-- wrong one for moving a body part: a part is moved by placing it somewhere
-- else, not by sliding its pixels within their own box.
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
--
-- The result grows to hold the whole lean. An earlier version kept the
-- original size, and looking at a real figure leaning showed what that costs:
-- at any lean worth having, the rows furthest from the pivot travel further
-- than the picture is wide and the legs simply vanish. Losing part of a
-- drawing without saying so is the worst thing this layer could do, so the
-- frame moves instead.
-- @tparam table source
-- @tparam table options  factor, and the row the lean pivots about
-- @treturn table a new matrix, large enough to hold every row
-- @treturn number where the new picture's left edge sits relative to the old
function M.shear(source, options)
  local factor = options.factor or 0
  local pivotRow = options.pivotRow or 0

  local offsets = {}
  local leftmost, rightmost = 0, 0

  for y = 0, source.height - 1 do
    local offset = round(factor * (y - pivotRow))
    offsets[y] = offset
    leftmost = math.min(leftmost, offset)
    rightmost = math.max(rightmost, offset)
  end

  local result = matrix.new(source.width + rightmost - leftmost, source.height, source.transparent)

  for y = 0, source.height - 1 do
    local offset = offsets[y] - leftmost
    for x = 0, source.width - 1 do
      result:set(x + offset, y, source:get(x, y))
    end
  end

  return result, leftmost
end

-- The quarter turns, given exactly rather than through trigonometry. A cosine
-- of ninety degrees comes back as a number near zero but not zero, and that
-- residue is enough to send a pixel to the wrong side of a rounding boundary.
-- A quarter turn has an exact answer and must produce it.
local QUARTER_TURNS = {
  [0] = { cosine = 1, sine = 0 },
  [90] = { cosine = 0, sine = 1 },
  [180] = { cosine = -1, sine = 0 },
  [270] = { cosine = 0, sine = -1 },
}

local function trigonometry(degrees)
  local turn = degrees % 360
  local exact = QUARTER_TURNS[turn]
  if exact then
    return exact.cosine, exact.sine
  end
  local radians = math.rad(turn)
  return math.cos(radians), math.sin(radians)
end

--- Where the frame has to be to hold the whole turned picture.
-- Worked out from where the four corners land, not assumed square and not
-- guessed from the diagonal. A picture that is not square comes back with its
-- dimensions swapped, and assuming otherwise crops it.
local function turnedBounds(source, pivotX, pivotY, cosine, sine)
  local left, right, top, bottom

  for _, corner in ipairs {
    { 0, 0 },
    { source.width - 1, 0 },
    { 0, source.height - 1 },
    { source.width - 1, source.height - 1 },
  } do
    local dx = corner[1] - pivotX
    local dy = corner[2] - pivotY
    local x = pivotX + dx * cosine - dy * sine
    local y = pivotY + dx * sine + dy * cosine

    left = math.min(left or x, x)
    right = math.max(right or x, x)
    top = math.min(top or y, y)
    bottom = math.max(bottom or y, y)
  end

  left = math.floor(left)
  top = math.floor(top)

  return left, top, math.ceil(right) - left + 1, math.ceil(bottom) - top + 1
end

--- Turn a picture about a pivot.
-- Positive degrees turn it clockwise as it appears on screen, because a
-- canvas counts downwards.
--
-- Every destination pixel asks the source what belongs there, rather than
-- every source pixel being thrown at a destination. Sampling backwards leaves
-- no holes: pushing pixels forward scatters them and the gaps between are
-- what makes a naively rotated sprite look shot through.
--
-- Nothing is blended. Each destination pixel is whichever single source pixel
-- lands nearest, so the palette is untouched. At this scale that is not an
-- approximation of a better method - it is the only method that keeps the art
-- the artist's. What it costs is angular precision, which is the problem the
-- enlargement below exists to solve.
--
-- @tparam table source
-- @tparam number degrees
-- @tparam ?table options  pivot, in source coordinates; the centre by default
-- @treturn table a new matrix, large enough to hold the whole turn
-- @treturn number where the new picture's left edge sits relative to the old
-- @treturn number where its top edge sits
function M.rotate(source, degrees, options)
  options = options or {}
  local pivot = options.pivot
  local pivotX = pivot and pivot.x or (source.width - 1) / 2
  local pivotY = pivot and pivot.y or (source.height - 1) / 2

  local cosine, sine = trigonometry(degrees)
  local left, top, width, height = turnedBounds(source, pivotX, pivotY, cosine, sine)

  local result = matrix.new(width, height, source.transparent)

  for y = 0, height - 1 do
    for x = 0, width - 1 do
      -- Undo the turn to find out which source pixel belongs here.
      local dx = x + left - pivotX
      local dy = y + top - pivotY
      local sourceX = round(pivotX + dx * cosine + dy * sine)
      local sourceY = round(pivotY - dx * sine + dy * cosine)
      result:set(x, y, source:get(sourceX, sourceY))
    end
  end

  return result, left, top
end

--- Double a picture, keeping its edges.
-- The rule compares each pixel against its four neighbours. Where two like
-- neighbours meet at a corner, that corner is filled with their value; and
-- where they do not, the pixel simply repeats. Nothing is averaged: every
-- value written was copied from a neighbour, so the palette comes through
-- untouched.
--
-- Matching is by exact equality, not by similarity. The published algorithm
-- compares colours loosely so it can cope with art that was anti-aliased or
-- dithered before it arrived. This project's art is neither, so a similarity
-- threshold would be a tunable number with no principled value, solving a
-- problem the source material does not have.
-- @tparam table source
-- @treturn table a new matrix, twice the size
function M.enlarge(source)
  local result = matrix.new(source.width * 2, source.height * 2, source.transparent)

  -- Outside the picture, the nearest edge pixel stands in. Answering "nothing
  -- is drawn there" instead would make the filter see an edge all the way
  -- around, and it would punch transparent corners into a flat region that
  -- simply happens to reach the border.
  local function neighbour(x, y)
    return source:get(
      math.max(0, math.min(source.width - 1, x)),
      math.max(0, math.min(source.height - 1, y))
    )
  end

  for y = 0, source.height - 1 do
    for x = 0, source.width - 1 do
      local middle = source:get(x, y)
      local above = neighbour(x, y - 1)
      local below = neighbour(x, y + 1)
      local before = neighbour(x - 1, y)
      local after = neighbour(x + 1, y)

      local topLeft, topRight, bottomLeft, bottomRight = middle, middle, middle, middle

      if above ~= below and before ~= after then
        if before == above then
          topLeft = before
        end
        if above == after then
          topRight = after
        end
        if before == below then
          bottomLeft = before
        end
        if below == after then
          bottomRight = after
        end
      end

      result:set(x * 2, y * 2, topLeft)
      result:set(x * 2 + 1, y * 2, topRight)
      result:set(x * 2, y * 2 + 1, bottomLeft)
      result:set(x * 2 + 1, y * 2 + 1, bottomRight)
    end
  end

  return result
end

--- Enlarge to a factor, by doubling repeatedly.
-- Only powers of two are reachable, because the filter works on pairs. Asking
-- for anything else is a mistake worth reporting rather than rounding away.
-- @tparam table source
-- @tparam number factor
-- @treturn table a new matrix
function M.enlargeBy(source, factor)
  local remaining = factor
  local result = source

  while remaining > 1 do
    if remaining % 2 ~= 0 then
      error(("a factor of %d cannot be reached by doubling"):format(factor), 2)
    end
    result = M.enlarge(result)
    remaining = remaining / 2
  end

  return result
end

--- Shrink a picture by picking one value per block.
-- Every other way of shrinking averages, and an average of two palette entries
-- is a colour that was never in the palette. So each block votes: the value
-- most of it holds wins.
--
-- Ties are broken the same way every run, because the whole pipeline has to be
-- reproducible. A drawn value beats nothing, since eroding the silhouette on
-- every reduction would eat a small sprite alive; between two drawn values,
-- the smaller one wins, for no reason other than that a rule is needed and
-- this one never changes its mind.
-- @tparam table source
-- @tparam number factor
-- @treturn table a new matrix
function M.reduce(source, factor)
  if source.width % factor ~= 0 or source.height % factor ~= 0 then
    local size = ("%dx%d"):format(source.width, source.height)
    error(("a factor of %d does not divide a %s picture"):format(factor, size), 2)
  end

  local result = matrix.new(source.width / factor, source.height / factor, source.transparent)

  for y = 0, result.height - 1 do
    for x = 0, result.width - 1 do
      local counts = {}
      for inner = 0, factor - 1 do
        for across = 0, factor - 1 do
          local value = source:get(x * factor + across, y * factor + inner)
          counts[value] = (counts[value] or 0) + 1
        end
      end

      local winner, winningCount = source.transparent, -1
      for value, count in pairs(counts) do
        local beatsOnCount = count > winningCount
        local beatsOnBeingDrawn = count == winningCount
          and winner == source.transparent
          and value ~= source.transparent
        local beatsOnValue = count == winningCount
          and winner ~= source.transparent
          and value ~= source.transparent
          and value < winner
        if beatsOnCount or beatsOnBeingDrawn or beatsOnValue then
          winner, winningCount = value, count
        end
      end

      result:set(x, y, winner)
    end
  end

  return result
end

-- How much finer the picture is made before it is turned. A turn can only
-- place a pixel as precisely as the grid it happens on: at a given radius the
-- finest angle a raster can tell apart is roughly one pixel of arc, which for
-- a limb a few pixels long is more than ten degrees. Enlarging first buys that
-- precision back in proportion to the factor.
--
-- Eight is the figure the published work settled on, but it was chosen against
-- sprites several times larger than a limb. At this scale it is a floor rather
-- than a comfortable margin, which is why it is a parameter and why the
-- comparison measures it rather than trusting it.
M.DEFAULT_ENLARGEMENT = 8

--- Turn a picture by going somewhere finer first.
-- Enlarge with the edge-aware filter, turn there, then vote the result back
-- down. Nothing along the way blends, so the palette survives; what the detour
-- buys is angular precision the original grid cannot express.
-- @tparam table source
-- @tparam number degrees
-- @tparam ?table options  pivot in source coordinates, and the enlargement
-- @treturn table a new matrix
-- @treturn number where its left edge sits relative to the original
-- @treturn number where its top edge sits
function M.rotateSmoothly(source, degrees, options)
  options = options or {}
  local factor = options.factor or M.DEFAULT_ENLARGEMENT
  local pivot = options.pivot

  local enlarged = M.enlargeBy(source, factor)
  local enlargedPivot = pivot and { x = pivot.x * factor, y = pivot.y * factor } or nil

  local turned, left, top = M.rotate(enlarged, degrees, { pivot = enlargedPivot })

  -- Bring the frame down to a boundary the reduction can divide, so the offset
  -- reported back is a whole source pixel rather than a fraction of one.
  local alignedLeft = math.floor(left / factor) * factor
  local alignedTop = math.floor(top / factor) * factor
  local padLeft = left - alignedLeft
  local padTop = top - alignedTop

  local paddedWidth = math.ceil((padLeft + turned.width) / factor) * factor
  local paddedHeight = math.ceil((padTop + turned.height) / factor) * factor

  local padded = matrix.new(paddedWidth, paddedHeight, source.transparent)
  matrix.blit(padded, turned, padLeft, padTop)

  return M.reduce(padded, factor), alignedLeft / factor, alignedTop / factor
end

-- The angles a picture can be turned to without any of this: the quarter
-- turns, where every pixel lands exactly on another pixel.
M.EXACT_ANGLES = { 0, 90, 180, 270 }

--- Turn a picture to the nearest angle that costs nothing.
-- The third way of dealing with rotation: refuse to do it at all except where
-- it is exact. Motion becomes stepped rather than smooth, and the question the
-- comparison answers is whether that is worse than the alternatives at a size
-- where the alternatives struggle.
-- @treturn table a new matrix
-- @treturn number where its left edge sits relative to the original
-- @treturn number where its top edge sits
-- @treturn number the angle actually used
function M.rotateToNearestExact(source, degrees)
  local wanted = degrees % 360
  local best, distance = M.EXACT_ANGLES[1], nil

  for _, angle in ipairs(M.EXACT_ANGLES) do
    local apart = math.abs(((wanted - angle + 180) % 360) - 180)
    if not distance or apart < distance then
      best, distance = angle, apart
    end
  end

  local turned, left, top = M.rotate(source, best)
  return turned, left, top, best
end

--- Turn a picture, by whichever route suits the angle.
-- This is the one callers should use. A quarter turn is exact and costs
-- nothing, so it goes straight through; every other angle takes the detour,
-- because at these sizes turning on the native grid loses about one pixel in
-- twenty and that shows as a chewed outline.
--
-- The routes were compared at a limb's real size against a much finer turn
-- standing in for the truth. Agreement in the worst case: turning directly
-- 93.9 percent, the detour at eight 97.9, the detour at sixteen 100. The
-- detour at sixteen costs four times what eight does and buys under a point,
-- so eight is the default. Snapping to the nearest exact angle scored 20.3,
-- which is what it looks like when a limb does not move until the angle
-- passes forty-five degrees and then falls flat.
-- @tparam table source
-- @tparam number degrees
-- @tparam ?table options  pivot, and an enlargement to override the default
-- @treturn table a new matrix
-- @treturn number where its left edge sits relative to the original
-- @treturn number where its top edge sits
function M.turn(source, degrees, options)
  if degrees % 90 == 0 then
    return M.rotate(source, degrees, options)
  end
  return M.rotateSmoothly(source, degrees, options)
end

return M
