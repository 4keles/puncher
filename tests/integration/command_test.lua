-- Runs inside the application. Proves the menu command puts a refusal in front
-- of the person who can fix it.
--
-- Every refusal this extension raises is written in the words an artist uses:
-- which part, what is wrong with it. None of that reaches them if the command
-- lets the error out, because the application shows a raised error as a script
-- failure with a file path and a line number - a message for whoever wrote the
-- extension, not for whoever drew the character.
--
-- The command returns its reason as well as showing it, because a dialog
-- cannot be inspected from a batch run, and a check that only asked "did it
-- avoid raising" would pass just as well on a command that quietly did
-- nothing at all.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local bootstrap = dofile(app.fs.joinPath(here, "support.lua"))
local projectRoot = bootstrap.projectRoot(debug.getinfo(1, "S").source)
bootstrap.addProjectToPath(projectRoot)

local rig = require("adapter.rig")

local M = {}

local CANVAS_WIDTH = 96
local CANVAS_HEIGHT = 32
local DRAWING_WIDTH = 10
local DRAWING_HEIGHT = 12
local DRAWING_AT = { x = 8, y = 8 }

local function spriteWithADrawing()
  local sprite = Sprite(ImageSpec {
    width = CANVAS_WIDTH,
    height = CANVAS_HEIGHT,
    colorMode = ColorMode.RGB,
  })
  local image = Image(DRAWING_WIDTH, DRAWING_HEIGHT, ColorMode.RGB)
  for y = 0, DRAWING_HEIGHT - 1 do
    for x = 0, DRAWING_WIDTH - 1 do
      image:drawPixel(x, y, app.pixelColor.rgba(200, 60, 60, 255))
    end
  end
  -- A new document becomes the active one, which is what the command reads.
  sprite:newCel(sprite.layers[1], 1, image, Point(DRAWING_AT.x, DRAWING_AT.y))
  return sprite
end

local function markPart(sprite, name, rectangle, pivot, parent)
  local slice = sprite:newSlice(rectangle)
  slice.name = name
  slice.pivot = pivot
  if parent then
    slice.properties(rig.PLUGIN_KEY).parent = parent
  end
  return slice
end

local CASES = {
  {
    what = "a rig whose parts hang from each other in a circle",
    expect = "circle",
    mark = function(sprite)
      markPart(sprite, "a", Rectangle(8, 8, 6, 6), Point(3, 0), "b")
      markPart(sprite, "b", Rectangle(14, 8, 6, 6), Point(3, 0), "a")
    end,
  },
  {
    what = "a part whose pivot is outside its own rectangle",
    expect = "outside its own",
    mark = function(sprite)
      markPart(sprite, "torso", Rectangle(8, 8, 6, 6), Point(90, 0))
    end,
  },
  {
    what = "a part hanging from a name that is not in the rig",
    expect = "not in the rig",
    mark = function(sprite)
      markPart(sprite, "arm", Rectangle(8, 8, 6, 6), Point(3, 0), "shoulder")
    end,
  },
  {
    what = "parts marked where the artwork is not",
    expect = "empty",
    mark = function(sprite)
      markPart(sprite, "torso", Rectangle(70, 20, 6, 6), Point(3, 5))
    end,
  },
}

function M.run(support)
  local command = dofile(app.fs.joinPath(projectRoot, "commands", "demo_motion.lua"))
  command.root = projectRoot

  for _, case in ipairs(CASES) do
    local sprite = spriteWithADrawing()
    case.mark(sprite)

    local reached, produced, reason = pcall(command.run)
    support.assertTrue(reached, case.what .. ": the command let the error out")
    support.assertEquals(produced, false, case.what .. ": an animation was reported")
    support.assertNotNil(reason, case.what .. ": no reason was given")
    support.assertTrue(
      tostring(reason):find(case.expect, 1, true) ~= nil,
      case.what
        .. ": the reason did not mention "
        .. case.expect
        .. ", it said: "
        .. tostring(reason)
    )
    -- And whatever it says, it must not be a path into this extension.
    support.assertTrue(
      tostring(reason):find(".lua:", 1, true) == nil,
      case.what .. ": the artist was shown a file and a line"
    )

    sprite:close()
  end

  -- And the case that should work still works, so none of the above is a
  -- command that refuses everything.
  local sprite = spriteWithADrawing()
  local reached, produced = pcall(command.run)
  support.assertTrue(reached, "an unmarked character raised instead of dashing")
  support.assertEquals(produced, true, "an unmarked character produced nothing")
  sprite:close()
end

return M
