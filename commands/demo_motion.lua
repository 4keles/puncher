-- The demonstration command.
--
-- Takes whatever the artist has selected, asks the core for a dash of that
-- length, and hands the result to the adapter. It carries no mathematics and
-- no document manipulation of its own; if either starts appearing here, it
-- belongs in one of the other two layers.

local motion = require("core.motion")
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

  local preset = dofile(app.fs.joinPath(M.root, "presets", "demo_dash.lua"))
  local path = motion.linear(preset)

  local result = frames.applyMotion {
    sprite = sprite,
    cel = cel,
    path = path,
    layerName = LAYER_NAME,
    tagName = TAG_NAME,
  }

  app.refresh()

  explain {
    ("Produced %d frames on a new layer."):format(result.lastFrame - result.firstFrame + 1),
    "Your original layer is untouched. One undo removes all of it.",
  }
end

return M
