-- Turning a motion path into real frames.
--
-- Everything the core produced is plain numbers. This is where those numbers
-- become frames, cels and a tag inside the artist's document.
--
-- Two rules govern the whole module. The artist's own artwork is never
-- modified: the motion is written to a new layer and new frames, and the cel it
-- was built from is left exactly where it was. And every write happens inside
-- one transaction, so a single undo removes the entire result rather than
-- peeling it back one frame at a time.

local M = {}

local DEFAULT_LAYER_NAME = "Puncher Motion"
local DEFAULT_TAG_NAME = "Puncher"
local MILLISECONDS_PER_SECOND = 1000

local function requireValue(value, message)
  if value == nil then
    error(message, 3)
  end
end

--- Write a motion path into the sprite.
-- @param options table
--   sprite     Sprite    the document to write into
--   cel        Cel       the drawing to move; never modified
--   path       table     per-frame offsets and durations from the core
--   layerName  string    optional name for the produced layer
--   tagName    string    optional name for the produced tag
-- @return table  { layer = Layer, tag = Tag, firstFrame = number, lastFrame = number }
function M.applyMotion(options)
  requireValue(options.sprite, "applyMotion needs a sprite to write into")
  requireValue(options.cel, "applyMotion needs a cel to move")
  requireValue(options.path, "applyMotion needs a motion path")

  local sprite = options.sprite
  local sourceCel = options.cel
  local path = options.path

  if #path == 0 then
    error("the motion path is empty, so there is nothing to draw", 2)
  end

  local layerName = options.layerName or DEFAULT_LAYER_NAME
  local tagName = options.tagName or DEFAULT_TAG_NAME
  local origin = sourceCel.position
  local sourceImage = sourceCel.image

  local result = {}

  app.transaction("Puncher: apply motion", function()
    local layer = sprite:newLayer()
    layer.name = layerName

    local firstFrame = #sprite.frames + 1

    for index, step in ipairs(path) do
      local frameNumber = firstFrame + index - 1
      sprite:newEmptyFrame(frameNumber)
      sprite.frames[frameNumber].duration = step.duration / MILLISECONDS_PER_SECOND

      sprite:newCel(layer, frameNumber, sourceImage, Point(origin.x + step.x, origin.y + step.y))
    end

    local lastFrame = firstFrame + #path - 1
    local tag = sprite:newTag(firstFrame, lastFrame)
    tag.name = tagName

    result.layer = layer
    result.tag = tag
    result.firstFrame = firstFrame
    result.lastFrame = lastFrame
  end)

  return result
end

return M
