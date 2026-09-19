-- Generates the bundled sample character.
--
-- Run it with the application in batch mode:
--     "$ASEPRITE_BIN" --batch --script tools/make_sample.lua
--
-- The figure is drawn from fixed coordinates rather than anything random, so
-- the file this produces is identical on every machine. That matters because
-- the visual checks compare against it.

-- The figure is small, but the canvas is not: a dash that only travels one
-- body width does not read as a dash, and a character that leaves the canvas
-- cannot be watched at all. So there is room to the right to move into.
local FIGURE_HEIGHT = 32
local CANVAS_WIDTH = 160
local OUTPUT = "assets/sample-character.aseprite"

local palette = {
  outline = Color { r = 34, g = 32, b = 52, a = 255 },
  skin = Color { r = 223, g = 166, b = 122, a = 255 },
  shirt = Color { r = 217, g = 87, b = 99, a = 255 },
  trousers = Color { r = 48, g = 96, b = 130, a = 255 },
}

local function fill(image, left, top, width, height, color)
  for y = top, top + height - 1 do
    for x = left, left + width - 1 do
      image:drawPixel(x, y, color)
    end
  end
end

--- Draw a one pixel outline around everything already drawn.
local function outline(image, color)
  local transparent = image.spec.transparentColor
  local original = Image(image)

  for y = 0, image.height - 1 do
    for x = 0, image.width - 1 do
      if original:getPixel(x, y) == transparent then
        local touching = false
        for _, offset in ipairs { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
          local nx, ny = x + offset[1], y + offset[2]
          if nx >= 0 and ny >= 0 and nx < image.width and ny < image.height then
            if original:getPixel(nx, ny) ~= transparent then
              touching = true
            end
          end
        end
        if touching then
          image:drawPixel(x, y, color)
        end
      end
    end
  end
end

local sprite = Sprite(CANVAS_WIDTH, FIGURE_HEIGHT, ColorMode.RGB)
sprite.layers[1].name = "Character"

local image = sprite.cels[1].image

fill(image, 12, 5, 8, 7, palette.skin) -- head
fill(image, 11, 12, 10, 9, palette.shirt) -- body
fill(image, 9, 13, 2, 6, palette.skin) -- left arm
fill(image, 21, 13, 2, 6, palette.skin) -- right arm
fill(image, 12, 21, 3, 6, palette.trousers) -- left leg
fill(image, 17, 21, 3, 6, palette.trousers) -- right leg

outline(image, palette.outline)

sprite:saveAs(OUTPUT)
print(("wrote %s (%dx%d)"):format(OUTPUT, CANVAS_WIDTH, FIGURE_HEIGHT))
