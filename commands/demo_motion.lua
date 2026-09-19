-- The demonstration command.
--
-- Takes whatever the artist has selected, reads its parts, asks the core for a
-- dash of that length, and hands the resulting draw list to the adapter. It
-- carries no mathematics and no document manipulation of its own; if either
-- starts appearing here, it belongs in one of the other two layers.

local motion = require("core.motion")
local parts = require("core.parts")
local drawlist = require("core.drawlist")
local rig = require("adapter.rig")
local frames = require("adapter.frames")

local M = {}

local LAYER_NAME = "Puncher Dash"
local TAG_NAME = "dash"

local function explain(message)
  app.alert { title = "Puncher", text = message }
end

function M.run()
  local sprite = app.sprite
  if not sprite then
    explain("Open a sprite first, then run this again.")
    return
  end

  local cel = app.cel
  if not cel then
    explain {
      "Select a frame that has something drawn on it.",
      "The dash is built from the artwork in the active cel.",
    }
    return
  end

  local list, source = rig.read(sprite, cel)
  local tree = parts.tree(list)

  local preset = dofile(app.fs.joinPath(M.root, "presets", "demo_dash.lua"))
  local path = motion.linear(preset)

  -- The dash pushes the body about. With no parts marked that is the whole
  -- drawing; with parts marked it is whichever one has no parent, and the
  -- rest follow it.
  local moving = tree.roots[1]

  local drawn = drawlist.fromMotionPath {
    tree = tree,
    part = moving,
    layer = LAYER_NAME,
    swing = preset.swing,
    path = path,
  }
  drawlist.validate(drawn, tree)

  local result = frames.applyDrawList {
    sprite = sprite,
    cel = cel,
    parts = tree.byName,
    drawList = drawn,
    tagName = TAG_NAME,
  }

  app.refresh()

  local said = {
    ("Produced %d frames on a new layer."):format(result.lastFrame - result.firstFrame + 1),
    ("Parts came from the %s."):format(source),
  }
  -- A frame that drew nothing is worth saying out loud. It is legitimate on
  -- its own, but it usually means a part is marked somewhere the artwork is
  -- not, and finding that out by playing the animation is worse than being
  -- told.
  if result.blankFrames and result.blankFrames > 0 then
    local empty = ("%d of them came out empty."):format(result.blankFrames)
    said[#said + 1] = empty .. " Check the parts are marked over the drawing."
  end
  said[#said + 1] = "Your original layer is untouched. One undo removes all of it."

  explain(said)
end

return M
