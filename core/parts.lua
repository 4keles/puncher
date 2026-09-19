-- What a character is made of.
--
-- A part is a named rectangle with a pivot: the piece of the drawing that
-- moves as one thing, and the point it turns about. Parts name a parent, so a
-- shoulder turning carries the arm and the hand with it.
--
-- Nothing here knows where parts come from. The artist's own slices are one
-- supplier and a drawing nobody marked up is another; working them out from
-- the silhouette will be a third. They all hand over the same shape, and
-- everything above this line is written once.
--
-- A pivot is given in the part's own coordinates, measured from the top left
-- of its rectangle. That is how the application states a slice's pivot, and
-- two conventions for the same idea is how a limb ends up turning about
-- somewhere on the far side of the canvas.

local M = {}

-- Where a whole unmarked drawing turns about: the middle of its bottom edge.
-- A body pivots about where it stands. Turning it about its middle makes it
-- rotate like a thrown plank, which is right for a thrown plank and wrong for
-- everything else.
M.WHOLE_PIVOT_X = 0.5
M.WHOLE_PIVOT_Y = 1.0

--- The rig for a drawing nobody has marked up.
-- One part covering everything, which is exactly what the motion this engine
-- produced before parts existed was doing implicitly.
-- @tparam table bounds  x, y, width, height
-- @treturn table a list of parts
function M.fromWholeDrawing(bounds)
  return {
    {
      name = "body",
      role = "body",
      rect = { x = bounds.x, y = bounds.y, width = bounds.width, height = bounds.height },
      pivot = {
        x = math.floor(bounds.width * M.WHOLE_PIVOT_X),
        y = math.floor((bounds.height - 1) * M.WHOLE_PIVOT_Y),
      },
    },
  }
end

local function checkPivot(part)
  local pivot = part.pivot
  local inside = pivot.x >= 0
    and pivot.y >= 0
    and pivot.x < part.rect.width
    and pivot.y < part.rect.height
  if not inside then
    error(
      ("the part '%s' has its pivot at %d,%d, which is outside its own %dx%d rectangle"):format(
        part.name,
        pivot.x,
        pivot.y,
        part.rect.width,
        part.rect.height
      ),
      3
    )
  end
end

--- Turn a flat list of parts into a tree, refusing one that cannot be drawn.
-- A rig that is wrong should say so here, where the mistake is still a name
-- the artist recognises, rather than three layers later as a limb in the
-- wrong place.
-- @tparam table list  parts
-- @treturn table  { byName, childrenOf, roots, order }
function M.tree(list)
  if #list == 0 then
    error("a rig with no parts cannot be drawn", 2)
  end

  local byName = {}
  for _, part in ipairs(list) do
    if byName[part.name] then
      error(("two parts are both called '%s'"):format(part.name), 2)
    end
    checkPivot(part)
    byName[part.name] = part
  end

  local childrenOf = {}
  local roots = {}

  for _, part in ipairs(list) do
    childrenOf[part.name] = childrenOf[part.name] or {}
    if part.parent then
      if not byName[part.parent] then
        error(
          ("the part '%s' hangs from '%s', which is not in the rig"):format(part.name, part.parent),
          2
        )
      end
      childrenOf[part.parent] = childrenOf[part.parent] or {}
      table.insert(childrenOf[part.parent], part.name)
    else
      roots[#roots + 1] = part.name
    end
  end

  -- Parents before children, so a transform is never needed before it has
  -- been worked out. Anything left over after walking down from every root
  -- can only be hanging from itself.
  local order = {}
  local placed = {}

  local function walk(name)
    order[#order + 1] = name
    placed[name] = true
    for _, child in ipairs(childrenOf[name]) do
      walk(child)
    end
  end

  for _, name in ipairs(roots) do
    walk(name)
  end

  if #order ~= #list then
    -- Every part that is not a root names a parent, so anything the walk did
    -- not reach is hanging from something that hangs from it.
    local stranded = {}
    for _, part in ipairs(list) do
      if not placed[part.name] then
        stranded[#stranded + 1] = part.name
      end
    end
    table.sort(stranded)
    error(
      ("these parts hang from each other in a circle: %s"):format(table.concat(stranded, ", ")),
      2
    )
  end

  return { byName = byName, childrenOf = childrenOf, roots = roots, order = order }
end

--- Work out where every part ends up, given a pose.
--
-- A pose says what each part does on its own: how far it turns about its own
-- pivot, and how far it is pushed. What comes back is what a renderer needs:
-- the angle each part ended up at, and where its pivot landed on the canvas.
--
-- The rule is one line and everything else follows from it. A parent's
-- placement maps any point of the drawing's rest position to where it now
-- sits, by turning it about the parent's own rest pivot and then moving that
-- pivot to where the parent ended up. A child's pivot is such a point, so a
-- shoulder turning carries the arm without the arm knowing anything about it.
--
-- Angles are in degrees, turning clockwise on screen, so they match what the
-- raster layer takes and what a preset would sensibly be written in.
-- @tparam table tree  from `M.tree`
-- @tparam table pose  per part: rotation in degrees, and an offset
-- @treturn table  per part: { angle = degrees, pivot = { x, y } }
function M.solve(tree, pose)
  for name in pairs(pose) do
    if not tree.byName[name] then
      error(("the pose moves '%s', which is not in the rig"):format(name), 2)
    end
  end

  local placed = {}

  for _, name in ipairs(tree.order) do
    local part = tree.byName[name]
    local own = pose[name] or {}
    local offset = own.offset or { x = 0, y = 0 }

    local restX = part.rect.x + part.pivot.x
    local restY = part.rect.y + part.pivot.y

    local inheritedAngle = 0
    local x, y = restX, restY

    if part.parent then
      local parent = placed[part.parent]
      inheritedAngle = parent.angle

      local radians = math.rad(inheritedAngle)
      local cosine, sine = math.cos(radians), math.sin(radians)
      local dx = restX - parent.restX
      local dy = restY - parent.restY

      x = parent.pivot.x + dx * cosine - dy * sine
      y = parent.pivot.y + dx * sine + dy * cosine
    end

    placed[name] = {
      angle = inheritedAngle + (own.rotation or 0),
      pivot = { x = x + offset.x, y = y + offset.y },
      -- Kept so a child can measure itself against where its parent rested.
      restX = restX,
      restY = restY,
    }
  end

  return placed
end

return M
