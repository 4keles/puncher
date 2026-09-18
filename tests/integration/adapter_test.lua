-- Runs inside the application. Proves the adapter turns a motion path into
-- real frames without disturbing what the artist already drew.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local bootstrap = dofile(app.fs.joinPath(here, "support.lua"))
bootstrap.addProjectToPath(bootstrap.projectRoot(debug.getinfo(1, "S").source))

local frames = require("adapter.frames")

local M = {}

local function newTestSprite()
  local sprite = Sprite(16, 16)
  local cel = sprite.cels[1]
  local image = cel.image

  -- A recognizable blob, so a moved copy is obviously a copy.
  for y = 4, 11 do
    for x = 4, 11 do
      image:drawPixel(x, y, Color { r = 255, g = 80, b = 40, a = 255 })
    end
  end

  return sprite
end

function M.run(support)
  local sprite = newTestSprite()
  local sourceLayer = sprite.layers[1]
  local sourceCel = sprite.cels[1]
  local originalFrameCount = #sprite.frames
  local originalPosition = sourceCel.position

  local path = {
    { x = 0, y = 0, duration = 100, held = true },
    { x = 5, y = 0, duration = 60, held = false },
    { x = 9, y = -2, duration = 60, held = false },
    { x = 12, y = 0, duration = 120, held = true },
  }

  local result = frames.applyMotion {
    sprite = sprite,
    cel = sourceCel,
    path = path,
    layerName = "Motion Test",
    tagName = "motion-test",
  }

  support.assertNotNil(result, "the adapter returned nothing")

  -- The sprite grew by exactly one frame per step.
  support.assertEquals(#sprite.frames, originalFrameCount + #path, "frame count")

  -- A new layer carries the motion, and the original layer is untouched.
  support.assertEquals(#sprite.layers, 2, "layer count")
  support.assertEquals(sourceLayer.name, sprite.layers[1].name, "source layer renamed")
  support.assertEquals(sourceCel.position.x, originalPosition.x, "source cel moved horizontally")
  support.assertEquals(sourceCel.position.y, originalPosition.y, "source cel moved vertically")

  -- Every produced cel sits at the offset the path asked for, measured against
  -- where the original drawing was.
  local motionLayer = result.layer
  support.assertEquals(motionLayer.name, "Motion Test", "layer name")

  for index, step in ipairs(path) do
    local frameNumber = result.firstFrame + index - 1
    local cel = motionLayer:cel(frameNumber)
    support.assertNotNil(cel, "no cel produced for step " .. index)
    support.assertEquals(
      cel.position.x,
      originalPosition.x + step.x,
      "step " .. index .. " horizontal"
    )
    support.assertEquals(
      cel.position.y,
      originalPosition.y + step.y,
      "step " .. index .. " vertical"
    )

    -- Durations are stored in seconds by the application, in milliseconds by us.
    support.assertEquals(
      math.floor(sprite.frames[frameNumber].duration * 1000 + 0.5),
      step.duration,
      "step " .. index .. " duration"
    )
  end

  -- A tag covers exactly the produced range, so the artist can play it back.
  local tag = nil
  for _, candidate in ipairs(sprite.tags) do
    if candidate.name == "motion-test" then
      tag = candidate
    end
  end
  support.assertNotNil(tag, "no tag was created")
  support.assertEquals(tag.fromFrame.frameNumber, result.firstFrame, "tag start")
  support.assertEquals(tag.toFrame.frameNumber, result.firstFrame + #path - 1, "tag end")

  sprite:close()
end

return M
