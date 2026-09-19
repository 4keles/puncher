-- What to draw, said once, in a form nothing has to interpret twice.
--
-- The engine used to hand the application a list of offsets and one unchanged
-- picture. That could express a cut-out sliding across a table and nothing
-- else: no parts, no turning, no pixels drawn that were not already there.
--
-- A draw list replaces it. Per frame: how long it lasts, and a list of
-- instructions saying which part is drawn, turned how far, with its pivot
-- landing where. It is plain data, which means the whole of what an animation
-- will look like can be worked out and checked with no editor running, and the
-- adapter's job shrinks to carrying it out.
--
-- Instructions come in drawing order, parents before children, because that is
-- the order a body has to be assembled in.

local parts = require("core.parts")
local easing = require("core.easing")

local M = {}

local function check(condition, message, ...)
  if not condition then
    error(message:format(...), 3)
  end
end

--- Build a list from a rig and a pose per frame.
-- @tparam table options  tree, frames (duration, held, pose), layer
-- @treturn table the draw list
function M.fromPoses(options)
  local tree = options.tree
  local layer = options.layer

  local frames = {}

  for index, frame in ipairs(options.frames) do
    local placed = parts.solve(tree, frame.pose or {})
    local draws = {}

    for _, name in ipairs(tree.order) do
      local at = placed[name]
      draws[#draws + 1] = {
        part = name,
        angle = at.angle,
        pivot = { x = at.pivot.x, y = at.pivot.y },
        layer = layer,
      }
    end

    frames[index] = {
      duration = frame.duration,
      held = frame.held or false,
      draws = draws,
    }
  end

  return { layers = { layer }, frames = frames }
end

--- Build a list from a motion path, which pushes a single part about.
-- The animation this engine produced before parts existed is this case, so it
-- now goes through the same machinery as everything else rather than down a
-- path of its own that could drift away from it.
--
-- A swing may be laid over the top: one named part turning through an angle as
-- the motion runs. When the rig has no part by that name, nothing swings and
-- what comes out is exactly the plain motion. That is not a special case bolted
-- on - it is what lets one command serve a character whose parts are marked and
-- one whose are not, and produce the right thing for each.
-- @tparam table options  tree, part, path, layer, and optionally swing
-- @treturn table the draw list
function M.fromMotionPath(options)
  local frames = {}
  local swing = options.swing
  local swings = swing and options.tree.byName[swing.part] ~= nil

  local curve = swings and easing.byName(swing.curve or "linear") or nil

  for index, step in ipairs(options.path) do
    local pose = { [options.part] = { offset = { x = step.x, y = step.y } } }

    if swings then
      local through = curve(step.progress or 0)
      pose[swing.part] = { rotation = swing.from + (swing.to - swing.from) * through }
    end

    frames[index] = {
      duration = step.duration,
      held = step.held,
      pose = pose,
    }
  end

  return M.fromPoses {
    tree = options.tree,
    layer = options.layer,
    frames = frames,
  }
end

--- Refuse a list that cannot be drawn, naming what is wrong and where.
-- Refusing rather than skipping is the point. A frame quietly missing a limb
-- looks like an animation right up until somebody notices, which is usually
-- several tracks later and far from the cause.
-- @tparam table list
-- @tparam table tree
-- @treturn boolean true, or an error naming the frame and the instruction
function M.validate(list, tree)
  check(list.frames and #list.frames > 0, "this draw list has no frames, so it would draw nothing")
  check(list.layers and #list.layers > 0, "this draw list names no layer to draw on")

  -- An instruction may only name a layer the list declares. The adapter
  -- creates exactly the declared layers and then looks each instruction's
  -- layer up among them; one that was never declared is not a drawing that
  -- goes somewhere unexpected, it is a drawing that goes nowhere.
  local declared = {}
  for _, name in ipairs(list.layers) do
    declared[name] = true
  end

  for frameIndex, frame in ipairs(list.frames) do
    local where = ("frame %d"):format(frameIndex)

    check(type(frame.duration) == "number", "%s has no duration", where)
    check(
      frame.duration > 0,
      "%s has a duration of %s, which is not a length of time",
      where,
      tostring(frame.duration)
    )
    check(frame.draws and #frame.draws > 0, "%s draws nothing at all", where)

    for drawIndex, draw in ipairs(frame.draws) do
      local which = ("%s, instruction %d"):format(where, drawIndex)

      check(draw.part ~= nil, "%s does not say which part it draws", which)
      check(
        tree.byName[draw.part] ~= nil,
        "%s draws '%s', which is not in the rig",
        which,
        tostring(draw.part)
      )
      check(type(draw.angle) == "number", "%s has no angle", which)
      check(
        type(draw.pivot) == "table"
          and type(draw.pivot.x) == "number"
          and type(draw.pivot.y) == "number",
        "%s has no pivot to land on",
        which
      )
      check(type(draw.layer) == "string", "%s does not say which layer it draws on", which)
      check(
        declared[draw.layer] == true,
        "%s draws on '%s', which this list never declares",
        which,
        tostring(draw.layer)
      )
    end
  end

  return true
end

return M
