-- Building a pixel matrix out of text.
--
-- A raster test is about a picture, so it should read like one. A test that
-- spells out a shape as rows of characters fails with the shape visible;
-- one that builds the same shape with nested loops fails with an index.
--
-- Not part of the extension. Test scaffolding only.

local matrix = require("core.matrix")

local M = {}

-- The character standing for "nothing here". Every other character becomes a
-- distinct colour, so a test can tell two colours apart without inventing a
-- palette.
M.EMPTY = "."

--- Build a matrix from a list of equal-length rows of characters.
-- @tparam table rows list of strings
-- @treturn table a matrix
function M.fromRows(rows)
  local height = #rows
  local width = (height > 0) and #rows[1] or 0

  for index, row in ipairs(rows) do
    if #row ~= width then
      error(("row %d is %d characters wide, but row 1 is %d"):format(index, #row, width), 2)
    end
  end

  local built = matrix.new(width, height)

  for y = 0, height - 1 do
    local row = rows[y + 1]
    for x = 0, width - 1 do
      local character = row:sub(x + 1, x + 1)
      if character ~= M.EMPTY then
        built:set(x, y, string.byte(character))
      end
    end
  end

  return built
end

--- Turn a matrix back into rows of characters, for a readable failure.
-- @tparam table built a matrix
-- @treturn table list of strings
function M.toRows(built)
  local rows = {}
  for y = 0, built.height - 1 do
    local characters = {}
    for x = 0, built.width - 1 do
      local value = built:get(x, y)
      characters[#characters + 1] = (value == built.transparent) and M.EMPTY or string.char(value)
    end
    rows[#rows + 1] = table.concat(characters)
  end
  return rows
end

--- Fail unless every colour in the result was already in the source.
-- Every transform in this layer must move, drop or duplicate pixels, never
-- blend them. A blended pixel is a colour the artist never chose, and on an
-- indexed sprite it cannot even be represented. This is the check that makes
-- that rule something a test enforces rather than something a comment claims.
-- @tparam table luaunit the test library, passed in so this file stays a
--   helper rather than a test
-- @tparam table source the matrix a transform was given
-- @tparam table result the matrix it returned
function M.assertNoColourInvented(luaunit, source, result)
  local allowed = {}
  for _, colour in ipairs(matrix.colours(source)) do
    allowed[colour] = true
  end

  for _, colour in ipairs(matrix.colours(result)) do
    luaunit.assertTrue(
      allowed[colour],
      ("the transform produced colour %d, which was not in its input"):format(colour)
    )
  end
end

return M
