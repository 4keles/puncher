-- Renders the rotation candidates side by side so one can be chosen.
--
--     "$ASEPRITE_BIN" --batch --script tools/compare_rotation.lua
--
-- Three ways of turning a small picture, at the size a limb actually is:
--
--   direct     sample the source once per destination pixel, at native size
--   detour 8   make the picture eight times finer, turn there, vote back down
--   detour 16  the same, sixteen times finer
--   snapped    refuse any angle that is not a quarter turn
--
-- The unit tests prove each of them does what it says. They cannot say which
-- one a person would accept, and at six pixels that is the only question that
-- matters. So this writes a sheet and reports what each one costs.

local root = app.fs.filePath(app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", "")))
package.path = table.concat({
  app.fs.joinPath(root, "?.lua"),
  app.fs.joinPath(root, "?", "init.lua"),
  package.path,
}, ";")

local matrix = require("core.matrix")
local raster = require("core.raster")

local OUTPUT_DIR = app.fs.joinPath(root, "build")
local SAMPLE = app.fs.joinPath(root, "assets", "sample-character.aseprite")

-- The angles worth looking at: small ones, where a turn is most likely to
-- fall apart, then further round to see it hold together.
local ANGLES = { 10, 20, 30, 45, 60, 75 }

local GAP = 2
local TIMING_REPEATS = 20

local function toMatrix(image, bounds)
  local built = matrix.new(bounds.width, bounds.height, image.spec.transparentColor)
  for y = 0, bounds.height - 1 do
    for x = 0, bounds.width - 1 do
      built:set(x, y, image:getPixel(bounds.x + x, bounds.y + y))
    end
  end
  return built
end

local function drawInto(image, built, offsetX, offsetY)
  for y = 0, built.height - 1 do
    for x = 0, built.width - 1 do
      local value = built:get(x, y)
      if value ~= built.transparent then
        image:drawPixel(offsetX + x, offsetY + y, value)
      end
    end
  end
end

local CANDIDATES = {
  {
    name = "direct",
    turn = function(picture, degrees)
      return raster.rotate(picture, degrees)
    end,
  },
  {
    name = "detour 8",
    turn = function(picture, degrees)
      return raster.rotateSmoothly(picture, degrees, { factor = 8 })
    end,
  },
  {
    name = "detour 16",
    turn = function(picture, degrees)
      return raster.rotateSmoothly(picture, degrees, { factor = 16 })
    end,
  },
  {
    name = "snapped",
    turn = function(picture, degrees)
      local turned, left, top = raster.rotateToNearestExact(picture, degrees)
      return turned, left, top
    end,
  },
}

local sprite = app.open(SAMPLE)
if not sprite then
  error("could not open the sample character at " .. SAMPLE)
end

local cel = sprite.cels[1]
local drawn = cel.image:shrinkBounds()
local figure = toMatrix(cel.image, drawn)

-- A limb, taken out of the figure itself rather than invented: the left arm
-- and the body edge beside it, which is the smallest thing this engine will
-- ever be asked to turn.
local LIMB = { x = 0, y = 8, width = 5, height = 12 }
local limb = matrix.new(LIMB.width, LIMB.height, figure.transparent)
for y = 0, LIMB.height - 1 do
  for x = 0, LIMB.width - 1 do
    limb:set(x, y, figure:get(LIMB.x + x, LIMB.y + y))
  end
end

local subjects = {
  { name = "limb", picture = limb },
  { name = "figure", picture = figure },
}

for _, subject in ipairs(subjects) do
  local results = {}
  local cellWidth, cellHeight = 0, 0

  for candidateIndex, candidate in ipairs(CANDIDATES) do
    results[candidateIndex] = {}
    for angleIndex, degrees in ipairs(ANGLES) do
      local turned = candidate.turn(subject.picture, degrees)
      results[candidateIndex][angleIndex] = turned
      cellWidth = math.max(cellWidth, turned.width)
      cellHeight = math.max(cellHeight, turned.height)
    end
  end

  local sheetWidth = #ANGLES * cellWidth + (#ANGLES - 1) * GAP
  local sheetHeight = #CANDIDATES * cellHeight + (#CANDIDATES - 1) * GAP
  local sheet = Sprite(sheetWidth, sheetHeight, sprite.colorMode)
  sheet:setPalette(sprite.palettes[1])
  local image = sheet.cels[1].image

  for candidateIndex = 1, #CANDIDATES do
    for angleIndex = 1, #ANGLES do
      local turned = results[candidateIndex][angleIndex]
      -- Centred in its cell, so a candidate that grows its frame is not
      -- mistaken for one that moved the picture.
      local offsetX = (angleIndex - 1) * (cellWidth + GAP)
        + math.floor((cellWidth - turned.width) / 2)
      local offsetY = (candidateIndex - 1) * (cellHeight + GAP)
        + math.floor((cellHeight - turned.height) / 2)
      drawInto(image, turned, offsetX, offsetY)
    end
  end

  local path = app.fs.joinPath(OUTPUT_DIR, "rotation-" .. subject.name .. ".png")
  if not app.fs.isDirectory(OUTPUT_DIR) then
    app.fs.makeDirectory(OUTPUT_DIR)
  end
  sheet:saveCopyAs(path)
  print(("wrote %s (%dx%d pixels)"):format(path, subject.picture.width, subject.picture.height))
end

print("")
print("rows, top to bottom: direct, detour 8, detour 16, snapped")
print("columns, left to right: " .. table.concat(ANGLES, ", ") .. " degrees")
-- Two earlier attempts at measuring the damage found nothing: no candidate
-- leaves holes surrounded on four sides, and none breaks the drawing into
-- separate pieces. Both are recorded here because they are the obvious things
-- to reach for and neither one works.
--
-- What does work is asking how close each candidate is to the turn it was
-- trying to make. A very fine detour is what the answer would be with the
-- grid out of the way, so it stands in for the truth, and each candidate is
-- scored on how much of it it agrees with.
local REFERENCE_ENLARGEMENT = 32

local function agreement(candidateResult, candidateLeft, candidateTop, truth, truthLeft, truthTop)
  local matching, total = 0, 0

  local left = math.min(candidateLeft, truthLeft)
  local top = math.min(candidateTop, truthTop)
  local right = math.max(candidateLeft + candidateResult.width, truthLeft + truth.width)
  local bottom = math.max(candidateTop + candidateResult.height, truthTop + truth.height)

  for y = top, bottom - 1 do
    for x = left, right - 1 do
      local mine = candidateResult:get(x - candidateLeft, y - candidateTop)
      local theirs = truth:get(x - truthLeft, y - truthTop)
      local drawnByEither = mine ~= candidateResult.transparent or theirs ~= truth.transparent
      if drawnByEither then
        total = total + 1
        if mine == theirs then
          matching = matching + 1
        end
      end
    end
  end

  if total == 0 then
    return 100
  end
  return matching / total * 100
end

print("")
for _, subject in ipairs(subjects) do
  print(("agreement with a much finer turn, %s, percent:"):format(subject.name))
  local truths = {}
  for angleIndex, degrees in ipairs(ANGLES) do
    local picture, left, top =
      raster.rotateSmoothly(subject.picture, degrees, { factor = REFERENCE_ENLARGEMENT })
    truths[angleIndex] = { picture = picture, left = left, top = top }
  end

  for _, candidate in ipairs(CANDIDATES) do
    local scores = {}
    local worst = 100
    for angleIndex, degrees in ipairs(ANGLES) do
      local picture, left, top = candidate.turn(subject.picture, degrees)
      local truth = truths[angleIndex]
      local score = agreement(picture, left, top, truth.picture, truth.left, truth.top)
      scores[#scores + 1] = ("%5.1f"):format(score)
      worst = math.min(worst, score)
    end
    print(("  %-10s %s   worst %5.1f"):format(candidate.name, table.concat(scores, " "), worst))
  end
end

print("")
print("cost, milliseconds for one turn:")

for _, subject in ipairs(subjects) do
  for _, candidate in ipairs(CANDIDATES) do
    local started = os.clock()
    for _ = 1, TIMING_REPEATS do
      candidate.turn(subject.picture, 30)
    end
    local each = (os.clock() - started) / TIMING_REPEATS * 1000
    print(("  %-8s %-10s %7.3f"):format(subject.name, candidate.name, each))
  end
end
