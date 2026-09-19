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

    -- A window reaching past the image. A part is marked in the sprite's
    -- coordinates while a cel holds only what was drawn on, so a rectangle
    -- with any margin around a limb starts outside the cel it is cut from.
    -- Nothing is there, and the answer has to say so: indexing the buffer from
    -- before its start counts backwards from its end in this language, which
    -- returns real bytes from the far side of the picture and assembles them
    -- into colours the drawing never held.
    local transparent = image.spec.transparentColor
    local outside = {
      { name = "entirely left", bounds = { x = -4, y = 0, width = 2, height = 2 } },
      { name = "entirely above", bounds = { x = 0, y = -3, width = 2, height = 2 } },
      { name = "entirely right", bounds = { x = image.width + 1, y = 0, width = 2, height = 2 } },
      { name = "entirely below", bounds = { x = 0, y = image.height + 1, width = 2, height = 2 } },
    }
    for _, case in ipairs(outside) do
      local read = picture.toMatrix(image, case.bounds)
      local invented = 0
      for y = 0, read.height - 1 do
        for x = 0, read.width - 1 do
          if read:get(x, y) ~= transparent then
            invented = invented + 1
          end
        end
      end
      support.assertEquals(
        invented,
        0,
        mode.name .. ": a window " .. case.name .. " outside the image invented no pixels"
      )
    end

    -- And one straddling the edge keeps the pixels that are really there.
    local straddling = picture.toMatrix(image, { x = -2, y = -2, width = 5, height = 5 })
    support.assertEquals(
      straddling:get(2, 2),
      image:getPixel(0, 0),
      mode.name .. ": a window straddling the corner kept the pixel that exists"
    )
    support.assertEquals(
      straddling:get(0, 0),
      transparent,
      mode.name .. ": and left nothing where the image does not reach"
    )

    sprite:close()
  end
end

return M
