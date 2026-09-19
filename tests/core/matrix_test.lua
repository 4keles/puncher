local luaunit = require("luaunit")
local matrix = require("core.matrix")
local raster = require("tests.support.raster")

local TestMatrix = {}

function TestMatrix:testANewMatrixIsEmpty()
  local built = matrix.new(4, 3)
  luaunit.assertEquals(built.width, 4)
  luaunit.assertEquals(built.height, 3)
  for y = 0, 2 do
    for x = 0, 3 do
      luaunit.assertEquals(built:get(x, y), built.transparent)
    end
  end
end

function TestMatrix:testAMatrixCarriesWhateverStandsForNothing()
  local built = matrix.new(2, 2, 7)
  luaunit.assertEquals(built.transparent, 7)
  luaunit.assertEquals(built:get(0, 0), 7)
end

function TestMatrix:testWritingAndReadingBack()
  local built = matrix.new(3, 3)
  built:set(1, 2, 42)
  luaunit.assertEquals(built:get(1, 2), 42)
  luaunit.assertEquals(built:get(2, 1), built.transparent)
end

-- Reading and writing outside the picture are the two places a raster
-- routine goes wrong quietly, so both are pinned.

function TestMatrix:testReadingOutsideTheBoundsIsNothingRatherThanAFailure()
  local built = matrix.new(2, 2)
  built:set(0, 0, 9)
  luaunit.assertEquals(built:get(-1, 0), built.transparent)
  luaunit.assertEquals(built:get(0, -1), built.transparent)
  luaunit.assertEquals(built:get(2, 0), built.transparent)
  luaunit.assertEquals(built:get(0, 2), built.transparent)
end

function TestMatrix:testWritingOutsideTheBoundsIsIgnoredRatherThanGrowing()
  local built = matrix.new(2, 2)
  built:set(5, 5, 9)
  built:set(-1, -1, 9)
  luaunit.assertEquals(built.width, 2)
  luaunit.assertEquals(built.height, 2)
  luaunit.assertEquals(#matrix.colours(built), 0)
end

function TestMatrix:testCloningCopiesThePixelsAndNotTheReference()
  local built = raster.fromRows { "ab", "cd" }
  local copy = matrix.clone(built)
  copy:set(0, 0, string.byte("z"))
  luaunit.assertEquals(raster.toRows(built), { "ab", "cd" })
  luaunit.assertEquals(raster.toRows(copy), { "zb", "cd" })
end

function TestMatrix:testBlittingLandsWhereItWasAsked()
  local destination = matrix.new(5, 4)
  local source = raster.fromRows { "ab", "cd" }
  matrix.blit(destination, source, 2, 1)
  luaunit.assertEquals(raster.toRows(destination), {
    ".....",
    "..ab.",
    "..cd.",
    ".....",
  })
end

function TestMatrix:testBlittingLeavesNothingWhereTheSourceHadNothing()
  local destination = raster.fromRows { "xxx", "xxx" }
  local source = raster.fromRows { "a.", ".b" }
  matrix.blit(destination, source, 0, 0)
  luaunit.assertEquals(raster.toRows(destination), { "axx", "xbx" })
end

function TestMatrix:testBlittingPartlyOutsideTheEdgeKeepsWhatFits()
  local destination = matrix.new(3, 3)
  local source = raster.fromRows { "ab", "cd" }
  matrix.blit(destination, source, 2, 2)
  luaunit.assertEquals(raster.toRows(destination), { "...", "...", "..a" })
end

function TestMatrix:testShrinkingFindsTheSmallestRectangleHoldingSomething()
  local built = raster.fromRows {
    "....",
    ".ab.",
    ".cd.",
    "....",
  }
  local bounds = matrix.shrinkBounds(built)
  luaunit.assertEquals(bounds, { x = 1, y = 1, width = 2, height = 2 })
end

function TestMatrix:testShrinkingAnEmptyMatrixFindsNothing()
  luaunit.assertNil(matrix.shrinkBounds(matrix.new(4, 4)))
end

function TestMatrix:testTheColoursUsedAreReportedWithoutRepeats()
  local built = raster.fromRows { "aab", "b.a" }
  local colours = matrix.colours(built)
  table.sort(colours)
  luaunit.assertEquals(colours, { string.byte("a"), string.byte("b") })
end

function TestMatrix:testAMatrixWithNoAreaIsAllowedAndHoldsNothing()
  local built = matrix.new(0, 0)
  luaunit.assertEquals(built:get(0, 0), built.transparent)
  luaunit.assertNil(matrix.shrinkBounds(built))
end

function TestMatrix:testNegativeDimensionsAreRejected()
  luaunit.assertErrorMsgContains("negative", matrix.new, -1, 2)
  luaunit.assertErrorMsgContains("negative", matrix.new, 2, -1)
end

return { TestMatrix = TestMatrix }
