-- How much of a drawing survives a turn, measured against a standard that
-- shares nothing with any of the candidates.
--
--     lua tools/measure_detail.lua
--
-- The comparison in tools/compare_rotation.lua scores each route against a
-- much finer version of one of the routes. That is a fair measure of angular
-- precision and an unfair one for the reduction rule, because the standard
-- makes the same kind of mistake as the thing it is judging. It is also blind
-- to detail: agreement counts every pixel alike, and the pixels that carry a
-- face are three out of two hundred.
--
-- This measures something no candidate can flatter. A turn preserves area, so
-- the number of pixels of each colour should come back. A colour far below
-- its own count was destroyed; far above it was smeared.

package.path = table.concat({
  "./?.lua",
  "./?/init.lua",
  package.path,
}, ";")

local matrix = require("core.matrix")
local raster = require("core.raster")

-- The angles worth looking at: small ones, where a turn is most likely to
-- fall apart, then further round to see it hold together. The same set the
-- original comparison used, so the two can be read beside each other.
local ANGLES = { 10, 20, 30, 45, 60, 75 }

-- The enlargements the routes use. Eight is what ships; sixteen is here to
-- answer whether a finer grid recovers detail, which is a different question
-- from whether it sharpens an edge.
local SHIPPING_ENLARGEMENT = 8
local FINER_ENLARGEMENT = 16

--- Take whatever sits at the middle of each block, with no vote at all.
-- The third way of reducing, included because it is the obvious alternative
-- to a vote and the measurement should say what it actually costs.
local function reduceByCentre(source, factor)
  local result = matrix.new(source.width / factor, source.height / factor, source.transparent)
  local middle = math.floor(factor / 2)
  for y = 0, result.height - 1 do
    for x = 0, result.width - 1 do
      result:set(x, y, source:get(x * factor + middle, y * factor + middle))
    end
  end
  return result
end

--- Enlarge, turn, and bring it back down by whichever rule is being measured.
local function detour(source, degrees, factor, reduce)
  local enlarged = raster.enlargeBy(source, factor)
  local turned, left, top = raster.rotate(enlarged, degrees)

  local alignedLeft = math.floor(left / factor) * factor
  local alignedTop = math.floor(top / factor) * factor
  local padLeft = left - alignedLeft
  local padTop = top - alignedTop

  local padded = matrix.new(
    math.ceil((padLeft + turned.width) / factor) * factor,
    math.ceil((padTop + turned.height) / factor) * factor,
    source.transparent
  )
  matrix.blit(padded, turned, padLeft, padTop)

  return reduce(padded, factor)
end

local CANDIDATES = {
  {
    name = "native grid",
    turn = function(source, degrees)
      return (raster.rotate(source, degrees))
    end,
  },
  {
    name = "detour 8, vote",
    turn = function(source, degrees)
      return detour(source, degrees, SHIPPING_ENLARGEMENT, raster.reduce)
    end,
  },
  {
    name = "detour 8, centre",
    turn = function(source, degrees)
      return detour(source, degrees, SHIPPING_ENLARGEMENT, reduceByCentre)
    end,
  },
  {
    name = "detour 16, vote",
    turn = function(source, degrees)
      return detour(source, degrees, FINER_ENLARGEMENT, raster.reduce)
    end,
  },
}

-- A figure at the size this engine works at, with detail drawn into it the way
-- a pixel artist draws it: a face made of single pixels, a belt two rows deep,
-- an arm one pixel wide. Built here rather than read from a file so the
-- measurement says exactly what it measured.
local BODY, HEAD, EYE, MOUTH, BELT, ARM = 1, 2, 3, 4, 5, 6

local function figure()
  local drawing = matrix.new(16, 24, 0)
  for y = 6, 23 do
    for x = 4, 11 do
      drawing:set(x, y, BODY)
    end
  end
  for y = 1, 6 do
    for x = 5, 10 do
      drawing:set(x, y, HEAD)
    end
  end
  drawing:set(6, 3, EYE)
  drawing:set(9, 3, EYE)
  drawing:set(7, 5, MOUTH)
  for y = 12, 13 do
    for x = 4, 11 do
      drawing:set(x, y, BELT)
    end
  end
  for y = 8, 16 do
    drawing:set(12, y, ARM)
  end
  return drawing
end

local FEATURES = {
  { value = BODY, name = "body" },
  { value = HEAD, name = "head" },
  { value = BELT, name = "belt" },
  { value = ARM, name = "arm, one wide" },
  { value = EYE, name = "eyes, one each" },
  { value = MOUTH, name = "mouth, one pixel" },
}

local function tally(drawing)
  local counts = {}
  for y = 0, drawing.height - 1 do
    for x = 0, drawing.width - 1 do
      local value = drawing:get(x, y)
      if value ~= drawing.transparent then
        counts[value] = (counts[value] or 0) + 1
      end
    end
  end
  return counts
end

local subject = figure()
local before = tally(subject)

print("How much of each colour comes back from a turn, as a share of what went")
print("in, averaged over " .. #ANGLES .. " angles: " .. table.concat(ANGLES, ", ") .. " degrees.")
print("A turn preserves area, so anything far below a hundred was destroyed and")
print("anything far above it was smeared.")
print("")

local header = ("  %-18s"):format("route")
for _, feature in ipairs(FEATURES) do
  header = header .. ("%-17s"):format(feature.name)
end
print(header)

for _, candidate in ipairs(CANDIDATES) do
  local totals = {}
  for _, degrees in ipairs(ANGLES) do
    local after = tally(candidate.turn(subject, degrees))
    for _, feature in ipairs(FEATURES) do
      totals[feature.value] = (totals[feature.value] or 0) + (after[feature.value] or 0)
    end
  end

  local line = ("  %-18s"):format(candidate.name)
  for _, feature in ipairs(FEATURES) do
    local kept = 100 * (totals[feature.value] / #ANGLES) / before[feature.value]
    line = line .. ("%-17s"):format(("%.0f%% of %d"):format(kept, before[feature.value]))
  end
  print(line)
end

print("")
print("Read it as: every route holds a large region and the shipping route holds")
print("a thin limb best, but a detail one pixel across is lost by all of them,")
print("worst by the vote. A finer grid recovers none of it, which puts the cause")
print("in the vote rather than the grid: a block the body merely outnumbers goes")
print("to the body, and an eye is always outnumbered.")
