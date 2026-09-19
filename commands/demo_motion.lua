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

--- Strip the file and line a raised error carries in front of its message.
-- The refusals this extension raises are written in the words an artist uses -
-- which part, what is wrong with it - and none of that reaches them behind a
-- path and a line number.
local function plainly(err)
  local text = tostring(err)
  return (text:gsub("^.-%.lua:%d+:%s*", ""))
end

--- Run something that may refuse, and put the refusal in front of the artist.
-- A refusal is not a crash: the rig says a limb hangs from a part that is not
-- there, and the person who drew it can fix that in a few seconds if they are
-- told. Raising it instead shows them a script error with a file path, which
-- is a message for whoever wrote this, not for them.
--
-- Anything that is genuinely a fault in this extension still comes through -
-- it just arrives as a sentence rather than as a trace, and nothing is
-- reported as having worked.
local function attempt(what, action)
  local ok, result = pcall(action)
  if ok then
    return true, result
  end
  return false, "Could not " .. what .. ". " .. plainly(result)
end

--- Refuse, telling the artist why, and say so to whoever called.
-- The dialog is what the artist reads. The returned reason is what a check can
-- read, because a dialog cannot be inspected from a batch run and "it did not
-- raise" would pass just as well on a command that quietly did nothing.
local function refuse(reason)
  explain(reason)
  return false, reason
end

--- Build the demonstration dash on whatever the artist has open.
-- @treturn boolean  whether an animation was produced
-- @treturn ?string  why not, in the words the artist was shown
function M.run()
  local sprite = app.sprite
  if not sprite then
    return refuse("Open a sprite first, then run this again.")
  end

  local cel = app.cel
  if not cel then
    return refuse(
      "Select a frame that has something drawn on it. "
        .. "The dash is built from the artwork in the active cel."
    )
  end

  local ok, read = attempt("read this character's parts", function()
    local list, source = rig.read(sprite, cel)
    return { tree = parts.tree(list), source = source }
  end)
  if not ok then
    return refuse(read)
  end
  local tree, source = read.tree, read.source

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
  local built
  ok, built = attempt("build the animation", function()
    drawlist.validate(drawn, tree)
    return frames.applyDrawList {
      sprite = sprite,
      cel = cel,
      parts = tree.byName,
      drawList = drawn,
      tagName = TAG_NAME,
    }
  end)
  if not ok then
    return refuse(built)
  end
  local result = built

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
  return true
end

return M
