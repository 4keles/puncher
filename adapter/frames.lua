-- Carrying out a draw list.
--
-- Everything about what an animation looks like was decided before this module
-- was called: which part is drawn, turned how far, with its pivot landing
-- where. This assembles it into the artist's document and does no thinking of
-- its own. If a decision starts appearing here, it belongs in the core.
--
-- Two rules govern the whole module, and they are the promises the product
-- makes. The artist's own artwork is never modified: the result goes onto new
-- layers and new frames, and the cel it was built from is left exactly where
-- it was. And every write happens inside one transaction, so a single undo
-- removes the entire result rather than peeling it back one frame at a time.

local matrix = require("core.matrix")
local raster = require("core.raster")
local picture = require("adapter.picture")

local M = {}

local DEFAULT_TAG_NAME = "Puncher"
local MILLISECONDS_PER_SECOND = 1000

local function requireValue(value, message)
  if value == nil then
    error(message, 3)
  end
end

local function round(value)
  if value >= 0 then
    return math.floor(value + 0.5)
  end
  return -math.floor(-value + 0.5)
end

--- The piece of the source drawing a part refers to.
-- Part rectangles are in the sprite's coordinates; a cel's image is in its
-- own. The difference is the cel's position, and forgetting it puts every
-- limb somewhere plausible and wrong.
local function cutOut(sourceCel, part)
  return picture.toMatrix(sourceCel.image, {
    x = part.rect.x - sourceCel.position.x,
    y = part.rect.y - sourceCel.position.y,
    width = part.rect.width,
    height = part.rect.height,
  })
end

--- Draw one instruction onto a canvas.
local function drawOne(canvas, cuts, part, instruction)
  local turned, left, top = raster.turn(cuts[part.name], instruction.angle, { pivot = part.pivot })

  -- Where the part's pivot ended up inside the turned picture, and therefore
  -- how far to move it so the pivot lands where the instruction asked.
  local pivotX = part.pivot.x - left
  local pivotY = part.pivot.y - top

  matrix.blit(
    canvas,
    turned,
    round(instruction.pivot.x - pivotX),
    round(instruction.pivot.y - pivotY)
  )
end

--- Write a draw list into the sprite.
-- @param options table
--   sprite   Sprite  the document to write into
--   cel      Cel     the drawing the parts are cut from; never modified
--   parts    table   the rig, by name
--   drawList table   what to draw, from the core
--   tagName  string  optional name for the produced tag
--
-- Refuses rather than returning when the whole list came out empty, so a run
-- of blank tagged frames is never handed back as a result.
-- @return table  { layers = {Layer}, tag = Tag, firstFrame, lastFrame,
--                  blankFrames = how many drew nothing }
function M.applyDrawList(options)
  requireValue(options.sprite, "applying a draw list needs a sprite to write into")
  requireValue(options.cel, "applying a draw list needs a cel to cut the parts from")
  requireValue(options.parts, "applying a draw list needs the rig the list refers to")
  requireValue(options.drawList, "applying a draw list needs a draw list")

  local sprite = options.sprite
  local sourceCel = options.cel
  local byName = options.parts
  local drawList = options.drawList

  if #drawList.frames == 0 then
    error("the draw list is empty, so there is nothing to draw", 2)
  end

  -- Cut every part out once. A part's pixels do not change between frames;
  -- only where they land does.
  local cuts = {}
  for name, part in pairs(byName) do
    cuts[name] = cutOut(sourceCel, part)
  end

  local tagName = options.tagName or DEFAULT_TAG_NAME
  local spec = sourceCel.image.spec
  local result = { layers = {} }

  app.transaction("Puncher: draw", function()
    local layerByName = {}
    for _, name in ipairs(drawList.layers) do
      local layer = sprite:newLayer()
      layer.name = name
      layerByName[name] = layer
      result.layers[#result.layers + 1] = layer
    end

    local firstFrame = #sprite.frames + 1
    local blankFrames = 0

    for index, frame in ipairs(drawList.frames) do
      local frameNumber = firstFrame + index - 1
      sprite:newEmptyFrame(frameNumber)
      sprite.frames[frameNumber].duration = frame.duration / MILLISECONDS_PER_SECOND

      local canvases = {}
      for _, name in ipairs(drawList.layers) do
        canvases[name] = matrix.new(sprite.width, sprite.height, spec.transparentColor)
      end

      for _, instruction in ipairs(frame.draws) do
        drawOne(canvases[instruction.layer], cuts, byName[instruction.part], instruction)
      end

      local drewSomething = false
      for name, canvas in pairs(canvases) do
        local drawn = matrix.shrinkBounds(canvas)
        if drawn then
          drewSomething = true
          local window = matrix.new(drawn.width, drawn.height, canvas.transparent)
          for y = 0, drawn.height - 1 do
            for x = 0, drawn.width - 1 do
              window:set(x, y, canvas:get(drawn.x + x, drawn.y + y))
            end
          end
          sprite:newCel(
            layerByName[name],
            frameNumber,
            picture.toImage(window, spec),
            Point(drawn.x, drawn.y)
          )
        end
      end

      if not drewSomething then
        blankFrames = blankFrames + 1
      end
    end

    -- A blank frame on its own is a real thing to draw: a character who has
    -- teleported out is not there. A whole animation of them is not. It means
    -- the parts and the drawing never met - the rectangles are somewhere the
    -- artwork is not - and reporting frames produced would hand back a tagged
    -- run of empty cels that looks like a result until somebody plays it.
    if blankFrames == #drawList.frames then
      error(
        "every frame came out empty, so nothing was drawn. The parts are "
          .. "marked somewhere the artwork is not: check that the slices sit "
          .. "over the drawing in the frame this was run from",
        2
      )
    end

    local lastFrame = firstFrame + #drawList.frames - 1
    local tag = sprite:newTag(firstFrame, lastFrame)
    tag.name = tagName

    result.tag = tag
    result.firstFrame = firstFrame
    result.lastFrame = lastFrame
    result.blankFrames = blankFrames
  end)

  return result
end

return M
