-- Reading a character's parts out of a document.
--
-- A part is a named rectangle with a pivot, which is exactly what a slice is.
-- So the rig is not a file format this extension invents and hides somewhere:
-- the artist marks parts with the editor's own slice tool, sets pivots with
-- its own pivot control, and this reads them back. It survives saving, it is
-- visible in the timeline, and the artist can correct it by hand - which is
-- what the product rules ask of every step.
--
-- A slice's own text and its extension properties both survive a save; this
-- was checked in the running application rather than assumed, because the
-- documentation does not say.
--
-- A document with no slices is not an error. It is a character nobody has
-- marked up yet, and it gets one part covering the whole drawing, which is
-- what the motion before parts existed was doing anyway.

local parts = require("core.parts")

local M = {}

-- Namespaced so nothing this extension writes can collide with another's.
-- The application requires the form publisher slash name, matching the
-- manifest.
M.PLUGIN_KEY = "4keles/puncher"

-- Where a part turns when the artist has not said. The top middle is the
-- joint end of a limb far more often than not: an arm hangs from its
-- shoulder, a shin from its knee.
M.DEFAULT_PIVOT_X = 0.5
M.DEFAULT_PIVOT_Y = 0

local function pivotOf(slice)
  if slice.pivot then
    return { x = slice.pivot.x, y = slice.pivot.y }
  end
  return {
    x = math.floor(slice.bounds.width * M.DEFAULT_PIVOT_X),
    y = math.floor((slice.bounds.height - 1) * M.DEFAULT_PIVOT_Y),
  }
end

--- The parts a sprite declares, or the whole drawing when it declares none.
-- @tparam table sprite
-- @tparam ?table cel  the drawing to fall back to; the sprite's first by default
-- @treturn table a list of parts
-- @treturn string where they came from, "slices" or "whole drawing"
function M.read(sprite, cel)
  if #sprite.slices == 0 then
    cel = cel or sprite.cels[1]
    if not cel then
      error("this sprite has nothing drawn on it, so there is no rig to read", 2)
    end
    local drawn = cel.image:shrinkBounds()
    if not drawn then
      error("the drawing is empty, so there is no rig to read", 2)
    end
    return parts.fromWholeDrawing {
      x = cel.position.x + drawn.x,
      y = cel.position.y + drawn.y,
      width = drawn.width,
      height = drawn.height,
    },
      "whole drawing"
  end

  local list = {}
  for _, slice in ipairs(sprite.slices) do
    local properties = slice.properties(M.PLUGIN_KEY)
    list[#list + 1] = {
      name = slice.name,
      role = properties.role or slice.name,
      parent = properties.parent,
      rect = {
        x = slice.bounds.x,
        y = slice.bounds.y,
        width = slice.bounds.width,
        height = slice.bounds.height,
      },
      pivot = pivotOf(slice),
    }
  end

  return list, "slices"
end

--- Mark a part on a sprite, the way this extension expects to read it back.
-- Used by the sample generator and by anything that prepares a character
-- without a person clicking. The artist's own tools write the same thing.
function M.mark(sprite, part)
  local slice =
    sprite:newSlice(Rectangle(part.rect.x, part.rect.y, part.rect.width, part.rect.height))
  slice.name = part.name
  slice.pivot = Point(part.pivot.x, part.pivot.y)

  local properties = slice.properties(M.PLUGIN_KEY)
  if part.parent then
    properties.parent = part.parent
  end
  if part.role then
    properties.role = part.role
  end

  return slice
end

return M
