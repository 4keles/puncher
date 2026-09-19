-- Renders the raster transforms so they can be looked at.
--
--     "$ASEPRITE_BIN" --batch --script tools/render_transforms.lua
--
-- The unit tests prove these routines against pictures spelled out as text.
-- That is precise but small. This runs the same routines inside the real
-- runtime, on the real sample character, and writes the results side by side,
-- because a transform can satisfy every assertion and still look wrong.
--
-- It reads and writes pixels one at a time on purpose. The bulk path between
-- an image and a matrix is the adapter's to design; borrowing it here would
-- settle that decision by accident.

local root = app.fs.filePath(app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", "")))
package.path = table.concat({
  app.fs.joinPath(root, "?.lua"),
  app.fs.joinPath(root, "?", "init.lua"),
  package.path,
}, ";")

local matrix = require("core.matrix")
local raster = require("core.raster")

local OUTPUT = app.fs.joinPath(root, "build", "transforms.png")
local SAMPLE = app.fs.joinPath(root, "assets", "sample-character.aseprite")

-- How far apart the panels sit, and how far the lean travels per row.
local GAP = 2
local SHEAR_FACTOR = 0.5

local function toMatrix(image, bounds)
  local built = matrix.new(bounds.width, bounds.height, image.spec.transparentColor)
  for y = 0, bounds.height - 1 do
    for x = 0, bounds.width - 1 do
      built:set(x, y, image:getPixel(bounds.x + x, bounds.y + y))
    end
  end
  return built
end

local function drawInto(image, built, offsetX, offsetY)
  for y = 0, built.height - 1 do
    for x = 0, built.width - 1 do
      local value = built:get(x, y)
      if value ~= built.transparent then
        image:drawPixel(offsetX + x, offsetY + y, value)
      end
    end
  end
end

local sprite = app.open(SAMPLE)
if not sprite then
  error("could not open the sample character at " .. SAMPLE)
end

local cel = sprite.cels[1]
local drawn = cel.image:shrinkBounds()
local source = toMatrix(cel.image, drawn)

local leaning = raster.shear(source, { factor = SHEAR_FACTOR, pivotRow = 0 })

local panels = {
  { name = "original", picture = source },
  { name = "mirrored", picture = raster.mirror(source, "horizontal") },
  { name = "translated", picture = raster.translate(source, 3, 2) },
  { name = "leaning", picture = leaning },
}

-- Panels are as wide as the widest of them, so a lean that grew its own frame
-- is shown whole rather than being cropped back to the others' size.
local panelWidth = 0
for _, panel in ipairs(panels) do
  panelWidth = math.max(panelWidth, panel.picture.width)
end

local width = #panels * panelWidth + (#panels - 1) * GAP
local sheet = Sprite(width, source.height, sprite.colorMode)
sheet:setPalette(sprite.palettes[1])

local image = sheet.cels[1].image
for index, panel in ipairs(panels) do
  drawInto(image, panel.picture, (index - 1) * (panelWidth + GAP), 0)
end

if not app.fs.isDirectory(app.fs.filePath(OUTPUT)) then
  app.fs.makeDirectory(app.fs.filePath(OUTPUT))
end
sheet:saveCopyAs(OUTPUT)

local names = {}
for _, panel in ipairs(panels) do
  names[#names + 1] = panel.name
end
print(("wrote %s: %s"):format(OUTPUT, table.concat(names, ", ")))
