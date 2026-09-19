-- Runs inside the application. Proves the bulk crossing between an image and a
-- matrix agrees with the application's own per-pixel accessors, in every
-- colour mode, because the fast path rests on an assumption about someone
-- else's byte layout.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local bootstrap = dofile(app.fs.joinPath(here, "support.lua"))
bootstrap.addProjectToPath(bootstrap.projectRoot(debug.getinfo(1, "S").source))

local picture = require("adapter.picture")

local M = {}

local MODES = {
  { name = "rgb", mode = ColorMode.RGB },
  { name = "grayscale", mode = ColorMode.GRAY },
  { name = "indexed", mode = ColorMode.INDEXED },
}

local function paint(image)
  -- A pattern rather than a flat fill, so a wrong stride or a wrong byte order
  -- cannot pass by accident.
  local value = 0
  for y = 0, image.height - 1 do
    for x = 0, image.width - 1 do
      value = (value * 31 + x * 7 + y * 13) % 200 + 1
      image:drawPixel(x, y, value)
    end
  end
end

function M.run(support)
  for _, mode in ipairs(MODES) do
    local sprite = Sprite(11, 7, mode.mode)
    local image = sprite.cels[1].image
    paint(image)

    local built = picture.toMatrix(image)
    support.assertEquals(built.width, 11, mode.name .. ": width")
    support.assertEquals(built.height, 7, mode.name .. ": height")

    local disagreements = 0
    for y = 0, image.height - 1 do
      for x = 0, image.width - 1 do
        if built:get(x, y) ~= image:getPixel(x, y) then
          disagreements = disagreements + 1
        end
      end
    end
    support.assertEquals(disagreements, 0, mode.name .. ": reading in bulk matched pixel by pixel")

    -- And back again.
    local rebuilt = picture.toImage(built, image.spec)
    local lost = 0
    for y = 0, image.height - 1 do
      for x = 0, image.width - 1 do
        if rebuilt:getPixel(x, y) ~= image:getPixel(x, y) then
          lost = lost + 1
        end
      end
    end
    support.assertEquals(lost, 0, mode.name .. ": the round trip returned the same pixels")

    -- Reading a window rather than the whole thing.
    local window = picture.toMatrix(image, { x = 3, y = 2, width = 4, height = 3 })
    support.assertEquals(window.width, 4, mode.name .. ": window width")
    support.assertEquals(
      window:get(0, 0),
      image:getPixel(3, 2),
      mode.name .. ": the window started where it was asked to"
    )

    sprite:close()
  end
end

return M
