-- Generates the bundled sample character that has its parts marked.
--
--     "$ASEPRITE_BIN" --batch --script tools/make_rigged_sample.lua
--
-- The unrigged sample beside it stays exactly as it is, because it is what the
-- visual regression check compares against. This is its counterpart: the same
-- kind of figure, but drawn as separate pieces with the joints marked, so the
-- engine can move one limb without the rest of the body coming with it.
--
-- Each piece is drawn into its own image, outlined there, and only then placed.
-- Outlining the whole figure at once would run a single outline around
-- everything, and cutting a limb back out of that would take a sliver of the
-- body with it - which shows up the moment the limb turns.
--
-- The pieces are laid out so their boxes never overlap. Two pieces meeting
-- means their outlines sit side by side, which is how a pixel artist separates
-- a limb from a body anyway.

local root = app.fs.filePath(app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", "")))
package.path = table.concat({
  app.fs.joinPath(root, "?.lua"),
  app.fs.joinPath(root, "?", "init.lua"),
  package.path,
}, ";")

local rig = require("adapter.rig")

local OUTPUT = app.fs.joinPath(root, "assets", "sample-rigged.aseprite")

-- Room to the right to dash into, as with the other sample.
local CANVAS_WIDTH = 160
local CANVAS_HEIGHT = 32

-- Every piece gains a one pixel outline on each side, so its drawn box is its
-- core grown by one all round.
local OUTLINE = 1

local palette = {
  outline = Color { r = 34, g = 32, b = 52, a = 255 },
  skin = Color { r = 223, g = 166, b = 122, a = 255 },
  shirt = Color { r = 217, g = 87, b = 99, a = 255 },
  trousers = Color { r = 48, g = 96, b = 130, a = 255 },
}

-- x, y and size are the piece's core, before its outline. The pivot is given
-- in the piece's own coordinates, measured from the top left of its drawn box,
-- and is the joint it turns about.
local PIECES = {
  {
    name = "head",
    parent = "torso",
    colour = "skin",
    x = 13,
    y = 3,
    width = 8,
    height = 6,
    -- The neck: the middle of the bottom edge, where the head meets the body.
    pivot = { x = 5, y = 6 },
  },
  {
    name = "torso",
    colour = "shirt",
    x = 12,
    y = 11,
    width = 10,
    height = 9,
    -- The hips. A body turns about where it carries its weight, not about its
    -- middle.
    pivot = { x = 6, y = 9 },
  },
  {
    name = "arm",
    parent = "torso",
    colour = "skin",
    x = 7,
    y = 13,
    width = 3,
    height = 8,
    -- The shoulder, at the corner of the arm that touches the body rather than
    -- at the middle of its top edge. A pivot in the middle swings the whole
    -- limb sideways and it reads as having come off.
    pivot = { x = 3, y = 1 },
  },
  {
    name = "legs",
    parent = "torso",
    colour = "trousers",
    x = 12,
    y = 22,
    width = 9,
    height = 6,
    pivot = { x = 5, y = 1 },
  },
}

--- Draw a filled rectangle with a one pixel outline around it.
local function piece(spec)
  local image = Image(ImageSpec {
    width = spec.width + OUTLINE * 2,
    height = spec.height + OUTLINE * 2,
    colorMode = ColorMode.RGB,
  })

  for y = 0, spec.height + OUTLINE * 2 - 1 do
    for x = 0, spec.width + OUTLINE * 2 - 1 do
      local inside = x >= OUTLINE
        and y >= OUTLINE
        and x < spec.width + OUTLINE
        and y < spec.height + OUTLINE
      image:drawPixel(x, y, inside and palette[spec.colour] or palette.outline)
    end
  end

  return image
end

local sprite = Sprite(CANVAS_WIDTH, CANVAS_HEIGHT, ColorMode.RGB)
sprite.layers[1].name = "Character"
local canvas = sprite.cels[1].image

for _, spec in ipairs(PIECES) do
  local drawn = piece(spec)
  local left = spec.x - OUTLINE
  local top = spec.y - OUTLINE
  canvas:drawImage(drawn, Point(left, top))

  rig.mark(sprite, {
    name = spec.name,
    role = spec.name,
    parent = spec.parent,
    rect = { x = left, y = top, width = drawn.width, height = drawn.height },
    pivot = spec.pivot,
  })
end

sprite:saveAs(OUTPUT)
print(("wrote %s (%dx%d, %d parts)"):format(OUTPUT, CANVAS_WIDTH, CANVAS_HEIGHT, #PIECES))
