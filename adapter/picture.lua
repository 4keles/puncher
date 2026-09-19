-- Carrying pixels across the boundary.
--
-- The core works on a matrix, which is plain data it can reason about with no
-- editor running. The application works on an image, which it owns. This is
-- the only place the two meet.
--
-- The transfer goes through the image's raw bytes rather than one call per
-- pixel. A limb turned eight times finer is a few hundred thousand pixels, and
-- a crossing per pixel at that volume is the difference between a command that
-- feels instant and one that does not.
--
-- The layout is the application's own: each pixel is a fixed number of bytes,
-- least significant first, with rows a fixed stride apart. That is an
-- assumption about someone else's format, so it is not trusted - the runtime
-- tests read an image both ways and compare, on every colour mode, and they
-- fail if the two ever disagree.

local matrix = require("core.matrix")

local M = {}

--- Read part of an image into a matrix.
-- @tparam table image
-- @tparam ?table bounds  x, y, width, height; the whole image by default
-- @treturn table a matrix
function M.toMatrix(image, bounds)
  bounds = bounds or { x = 0, y = 0, width = image.width, height = image.height }

  local built = matrix.new(bounds.width, bounds.height, image.spec.transparentColor)
  local bytes = image.bytes
  local stride = image.rowStride
  local perPixel = image.bytesPerPixel

  for y = 0, bounds.height - 1 do
    local rowStart = (bounds.y + y) * stride + bounds.x * perPixel
    for x = 0, bounds.width - 1 do
      local at = rowStart + x * perPixel
      local value = 0
      local place = 1
      for offset = 1, perPixel do
        value = value + bytes:byte(at + offset) * place
        place = place * 256
      end
      built:set(x, y, value)
    end
  end

  return built
end

--- Turn a matrix into a new image of the same size.
-- @tparam table built  a matrix
-- @tparam table spec   the image specification to create against
-- @treturn table an image
function M.toImage(built, spec)
  local image = Image(ImageSpec {
    width = math.max(built.width, 1),
    height = math.max(built.height, 1),
    colorMode = spec.colorMode,
    transparentColor = spec.transparentColor,
  })

  local perPixel = image.bytesPerPixel
  local stride = image.rowStride
  local row = {}
  local all = {}

  for y = 0, built.height - 1 do
    for x = 0, built.width - 1 do
      local value = built:get(x, y)
      for _ = 1, perPixel do
        row[#row + 1] = string.char(value % 256)
        value = math.floor(value / 256)
      end
    end
    -- A row may be padded beyond the pixels it holds, so anything left over
    -- is filled rather than left for the next row to fall into.
    while #row * 1 < stride do
      row[#row + 1] = "\0"
    end
    all[#all + 1] = table.concat(row)
    row = {}
  end

  if #all > 0 then
    image.bytes = table.concat(all)
  end

  return image
end

return M
