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
-- @tparam table options  tree, part, path, layer
-- @treturn table the draw list
function M.fromMotionPath(options)
  local frames = {}

  for index, step in ipairs(options.path) do
    frames[index] = {
      duration = step.duration,
      held = step.held,
      pose = { [options.part] = { offset = { x = step.x, y = step.y } } },
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
    end
  end

  return true
end

return M
