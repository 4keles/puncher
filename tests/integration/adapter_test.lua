-- Runs inside the application. Proves the adapter turns a draw list into real
-- frames without disturbing what the artist already drew.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local bootstrap = dofile(app.fs.joinPath(here, "support.lua"))
bootstrap.addProjectToPath(bootstrap.projectRoot(debug.getinfo(1, "S").source))

local frames = require("adapter.frames")
local rig = require("adapter.rig")
local parts = require("core.parts")
local drawlist = require("core.drawlist")

local M = {}

local function newTestSprite()
  local sprite = Sprite(32, 32)
  local image = sprite.cels[1].image

  -- A recognizable blob, so a moved copy is obviously a copy.
  for y = 4, 19 do
    for x = 8, 15 do
      image:drawPixel(x, y, Color { r = 255, g = 80, b = 40, a = 255 })
    end
  end

  return sprite
end

local PATH = {
  { x = 0, y = 0, duration = 100, held = true },
  { x = 5, y = 0, duration = 60, held = false },
  { x = 9, y = -2, duration = 60, held = false },
  { x = 12, y = 0, duration = 120, held = true },
}

function M.run(support)
  local sprite = newTestSprite()
  local sourceLayer = sprite.layers[1]
  local sourceCel = sprite.cels[1]
  local originalFrameCount = #sprite.frames
  local originalPosition = sourceCel.position

  local tree = parts.tree(rig.read(sprite))
  local list = drawlist.fromMotionPath {
    tree = tree,
    part = "body",
    layer = "Motion Test",
    path = PATH,
  }
  support.assertTrue(drawlist.validate(list, tree), "the produced list is one the adapter can draw")

  local result = frames.applyDrawList {
    sprite = sprite,
    cel = sourceCel,
    parts = tree.byName,
    drawList = list,
    tagName = "motion-test",
  }

  support.assertNotNil(result, "the adapter returned nothing")

  -- The sprite grew by exactly one frame per step.
  support.assertEquals(#sprite.frames, originalFrameCount + #PATH, "frame count")

  -- A new layer carries the motion, and the original layer is untouched.
  support.assertEquals(#sprite.layers, 2, "layer count")
  support.assertEquals(sourceLayer.name, sprite.layers[1].name, "source layer renamed")
  support.assertEquals(sourceCel.position.x, originalPosition.x, "source cel moved horizontally")
  support.assertEquals(sourceCel.position.y, originalPosition.y, "source cel moved vertically")

  -- The drawing the parts were cut from must come back out unchanged.
  local sourceDrawn = sourceCel.image:shrinkBounds()
  support.assertEquals(sourceDrawn.width, 8, "the source drawing changed width")
  support.assertEquals(sourceDrawn.height, 16, "the source drawing changed height")

  -- Every produced cel sits where the path asked, measured against where the
  -- original drawing was. This is the behaviour the engine had before draw
  -- lists existed, and it has to survive the change unaltered.
  local motionLayer = result.layers[1]
  support.assertEquals(motionLayer.name, "Motion Test", "layer name")

  for index, step in ipairs(PATH) do
    local frameNumber = result.firstFrame + index - 1
    local cel = motionLayer:cel(frameNumber)
    support.assertNotNil(cel, "no cel produced for step " .. index)
    support.assertEquals(
      cel.position.x,
      originalPosition.x + sourceDrawn.x + step.x,
      "step " .. index .. " horizontal"
    )
    support.assertEquals(
      cel.position.y,
      originalPosition.y + sourceDrawn.y + step.y,
      "step " .. index .. " vertical"
    )

    -- Durations are stored in seconds by the application, in milliseconds by us.
    support.assertEquals(
      math.floor(sprite.frames[frameNumber].duration * 1000 + 0.5),
      step.duration,
      "step " .. index .. " duration"
    )
  end

  -- The pixels arrive unchanged: an unturned part is a copy, not a resample.
  local firstCel = motionLayer:cel(result.firstFrame)
  support.assertEquals(firstCel.image.width, sourceDrawn.width, "produced cel width")
  support.assertEquals(firstCel.image.height, sourceDrawn.height, "produced cel height")
  local differing = 0
  for y = 0, sourceDrawn.height - 1 do
    for x = 0, sourceDrawn.width - 1 do
      local was = sourceCel.image:getPixel(sourceDrawn.x + x, sourceDrawn.y + y)
      if firstCel.image:getPixel(x, y) ~= was then
        differing = differing + 1
      end
    end
  end
  support.assertEquals(differing, 0, "an untouched part came through changed")

  -- A tag covers exactly the produced range, so the artist can play it back.
  local tag = nil
  for _, candidate in ipairs(sprite.tags) do
    if candidate.name == "motion-test" then
      tag = candidate
    end
  end
  support.assertNotNil(tag, "no tag was created")
  support.assertEquals(tag.fromFrame.frameNumber, result.firstFrame, "tag start")
  support.assertEquals(tag.toFrame.frameNumber, result.firstFrame + #PATH - 1, "tag end")

  -- The whole result must come back out in one step. Everything above was
  -- written inside a single transaction precisely so the artist never has to
  -- press undo eleven times to get rid of one mistake.
  app.command.Undo()

  support.assertEquals(#sprite.frames, originalFrameCount, "frame count after one undo")
  support.assertEquals(#sprite.layers, 1, "layer count after one undo")
  support.assertEquals(#sprite.tags, 0, "tag count after one undo")

  sprite:close()

  M.runEmptyResultIsRefused(support)
  M.runTransparentIndexIsNotAssumedToBeZero(support)
  M.runTurnsAreNeverCompounded(support)
end

--- A frame's turn is applied to the original drawing, never to the frame
--- before it.
-- Turning the previous result is the cheaper-looking thing to do and it
-- quietly destroys the drawing, because every turn resamples and the damage
-- compounds: going all the way round in steps of thirty degrees leaves 88
-- percent of a figure's pixels. Nothing in the module's shape stops a later
-- change from doing it, so this holds the property rather than the code.
local COMPOUNDING_ANGLES = { 0, 25, 50, 75 }

function M.runTurnsAreNeverCompounded(support)
  local function producedCel(angles, wanted)
    local sprite = newTestSprite()
    local list = {
      {
        name = "body",
        role = "body",
        rect = { x = 8, y = 4, width = 8, height = 16 },
        pivot = { x = 4, y = 15 },
      },
    }
    local tree = parts.tree(list)

    local frameList = { layers = { "Puncher Turns" }, frames = {} }
    for index, angle in ipairs(angles) do
      frameList.frames[index] = {
        duration = 60,
        held = false,
        draws = {
          { part = "body", angle = angle, pivot = { x = 20, y = 20 }, layer = "Puncher Turns" },
        },
      }
    end
    drawlist.validate(frameList, tree)

    frames.applyDrawList {
      sprite = sprite,
      cel = sprite.cels[1],
      parts = tree.byName,
      drawList = frameList,
      tagName = "turns-test",
    }

    local layer = nil
    for _, candidate in ipairs(sprite.layers) do
      if candidate.name == "Puncher Turns" then
        layer = candidate
      end
    end

    local pixels = {}
    local found = layer.cels[wanted]
    for y = 0, found.image.height - 1 do
      for x = 0, found.image.width - 1 do
        pixels[#pixels + 1] = found.image:getPixel(x, y)
      end
    end
    local position = { x = found.position.x, y = found.position.y }
    sprite:close()
    return pixels, position
  end

  -- The last angle, reached through three turns before it, against the same
  -- angle reached on its own. If the module ever turned the previous frame's
  -- result, these would differ.
  local throughOthers, positionA = producedCel(COMPOUNDING_ANGLES, #COMPOUNDING_ANGLES)
  local onItsOwn, positionB = producedCel({ COMPOUNDING_ANGLES[#COMPOUNDING_ANGLES] }, 1)

  support.assertEquals(#throughOthers, #onItsOwn, "the same angle produced a different size")
  support.assertEquals(positionA.x, positionB.x, "the same angle landed at a different place")
  support.assertEquals(positionA.y, positionB.y, "the same angle landed at a different height")

  local differences = 0
  for index = 1, #onItsOwn do
    if throughOthers[index] ~= onItsOwn[index] then
      differences = differences + 1
    end
  end
  support.assertEquals(differences, 0, "a turn was applied to the frame before it")
end

-- The whole chain on a document that calls something other than zero nothing.
-- The matrix layer defaults to zero meaning nothing, which makes this the easy
-- case to get wrong: a document whose transparent index is nine would either
-- lose every pixel of index nine, or gain nine as a colour it never had.
local ELSEWHERE_TRANSPARENT = 9
local TORSO_INDEX = 3
local ARM_INDEX = 7

function M.runTransparentIndexIsNotAssumedToBeZero(support)
  local sprite = Sprite(ImageSpec { width = 96, height = 48, colorMode = ColorMode.INDEXED })
  sprite.transparentColor = ELSEWHERE_TRANSPARENT

  local image = Image(ImageSpec {
    width = 12,
    height = 20,
    colorMode = ColorMode.INDEXED,
    transparentColor = ELSEWHERE_TRANSPARENT,
  })
  for y = 0, image.height - 1 do
    for x = 0, image.width - 1 do
      image:drawPixel(x, y, ELSEWHERE_TRANSPARENT)
    end
  end
  for y = 0, 13 do
    for x = 2, 9 do
      image:drawPixel(x, y, TORSO_INDEX)
    end
  end
  for y = 4, 11 do
    image:drawPixel(10, y, ARM_INDEX)
  end
  local cel = sprite:newCel(sprite.layers[1], 1, image, Point(10, 14))

  rig.mark(sprite, {
    name = "torso",
    role = "body",
    rect = { x = 12, y = 14, width = 8, height = 14 },
    pivot = { x = 4, y = 13 },
  })
  rig.mark(sprite, {
    name = "arm",
    role = "arm",
    parent = "torso",
    rect = { x = 20, y = 18, width = 1, height = 8 },
    pivot = { x = 0, y = 0 },
  })

  local list, source = rig.read(sprite, cel)
  support.assertEquals(source, "slices", "the marked parts were not read back")
  local tree = parts.tree(list)

  local drawn = drawlist.fromMotionPath {
    tree = tree,
    part = tree.roots[1],
    layer = "Puncher Indexed",
    swing = { part = "arm", from = -25, to = 70, curve = "cubicOut" },
    path = PATH,
  }
  drawlist.validate(drawn, tree)

  local result = frames.applyDrawList {
    sprite = sprite,
    cel = cel,
    parts = tree.byName,
    drawList = drawn,
    tagName = "indexed-test",
  }
  support.assertEquals(result.blankFrames, 0, "a frame came out empty on an indexed sprite")

  local produced = nil
  for _, layer in ipairs(sprite.layers) do
    if layer.name == "Puncher Indexed" then
      produced = layer
    end
  end
  support.assertNotNil(produced, "the layer was not created")

  local invented = 0
  local armPixels = 0
  for _, drawnCel in ipairs(produced.cels) do
    for y = 0, drawnCel.image.height - 1 do
      for x = 0, drawnCel.image.width - 1 do
        local value = drawnCel.image:getPixel(x, y)
        if value == ARM_INDEX then
          armPixels = armPixels + 1
        elseif value ~= TORSO_INDEX and value ~= ELSEWHERE_TRANSPARENT then
          invented = invented + 1
        end
      end
    end
  end
  support.assertEquals(invented, 0, "an index appeared that was not in the drawing")
  support.assertTrue(armPixels > 0, "the arm was lost entirely on an indexed sprite")

  -- And the promise that holds whatever the colour mode: the artist's own
  -- drawing comes through untouched.
  local disturbed = 0
  for y = 0, cel.image.height - 1 do
    for x = 0, cel.image.width - 1 do
      local expected = ELSEWHERE_TRANSPARENT
      if x >= 2 and x <= 9 and y <= 13 then
        expected = TORSO_INDEX
      elseif x == 10 and y >= 4 and y <= 11 then
        expected = ARM_INDEX
      end
      if cel.image:getPixel(x, y) ~= expected then
        disturbed = disturbed + 1
      end
    end
  end
  support.assertEquals(disturbed, 0, "the source cel was modified")

  sprite:close()
end

--- An animation where nothing was drawn must say so, not report success.
-- A blank frame on its own is a real thing to draw. A whole animation of them
-- means the parts are marked somewhere the artwork is not, and handing back a
-- tagged run of empty cels looks like a result until somebody plays it.
function M.runEmptyResultIsRefused(support)
  local sprite = newTestSprite()
  local layersBefore = #sprite.layers
  local framesBefore = #sprite.frames
  local tagsBefore = #sprite.tags

  -- A part marked in the corner the blob does not reach.
  local list = {
    {
      name = "body",
      role = "body",
      rect = { x = 24, y = 24, width = 6, height = 6 },
      pivot = { x = 0, y = 5 },
    },
  }
  local tree = parts.tree(list)
  local list2 = drawlist.fromMotionPath {
    tree = tree,
    part = "body",
    layer = "Puncher Empty",
    path = PATH,
  }
  drawlist.validate(list2, tree)

  local ok, message = pcall(frames.applyDrawList, {
    sprite = sprite,
    cel = sprite.cels[1],
    parts = tree.byName,
    drawList = list2,
    tagName = "empty-test",
  })

  support.assertEquals(ok, false, "an animation that drew nothing was accepted")
  support.assertTrue(
    tostring(message):find("empty") ~= nil,
    "the refusal did not say the frames came out empty"
  )

  -- And the refusal has to leave the document exactly as it was. A failure
  -- part way through a transaction that did not roll back is a corrupted
  -- document, which is worse than the thing being guarded against.
  support.assertEquals(#sprite.layers, layersBefore, "layers left behind by a refusal")
  support.assertEquals(#sprite.frames, framesBefore, "frames left behind by a refusal")
  support.assertEquals(#sprite.tags, tagsBefore, "tags left behind by a refusal")

  sprite:close()
end

return M
