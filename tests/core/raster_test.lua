local luaunit = require("luaunit")
local rasterOps = require("core.raster")
local matrix = require("core.matrix")
local raster = require("tests.support.raster")

local TestRaster = {}

local SHAPE = {
  "ab.",
  ".c.",
  "d.e",
}

function TestRaster:testTranslatingMovesEveryPixelByTheSameAmount()
  local source = raster.fromRows(SHAPE)
  local moved = rasterOps.translate(source, 1, 0)
  luaunit.assertEquals(raster.toRows(moved), {
    ".ab",
    "..c",
    ".d.",
  })
  raster.assertNoColourInvented(luaunit, source, moved)
end

function TestRaster:testTranslatingByNothingIsTheIdentity()
  local source = raster.fromRows(SHAPE)
  luaunit.assertEquals(raster.toRows(rasterOps.translate(source, 0, 0)), SHAPE)
end

function TestRaster:testTranslatingOffTheEdgeDropsWhatLeavesRatherThanWrapping()
  local source = raster.fromRows { "ab", "cd" }
  luaunit.assertEquals(raster.toRows(rasterOps.translate(source, 2, 0)), { "..", ".." })
end

function TestRaster:testTranslationRefusesAFractionOfAPixel()
  local source = raster.fromRows(SHAPE)
  luaunit.assertErrorMsgContains("whole", rasterOps.translate, source, 0.5, 0)
end

function TestRaster:testMirroringHorizontallyReversesEachRow()
  local source = raster.fromRows(SHAPE)
  local flipped = rasterOps.mirror(source, "horizontal")
  luaunit.assertEquals(raster.toRows(flipped), {
    ".ba",
    ".c.",
    "e.d",
  })
  raster.assertNoColourInvented(luaunit, source, flipped)
end

function TestRaster:testMirroringVerticallyReversesTheRowOrder()
  local source = raster.fromRows(SHAPE)
  luaunit.assertEquals(raster.toRows(rasterOps.mirror(source, "vertical")), {
    "d.e",
    ".c.",
    "ab.",
  })
end

function TestRaster:testMirroringTwiceReturnsTheOriginalExactly()
  local source = raster.fromRows(SHAPE)
  for _, axis in ipairs { "horizontal", "vertical" } do
    local there = rasterOps.mirror(source, axis)
    local back = rasterOps.mirror(there, axis)
    luaunit.assertEquals(raster.toRows(back), SHAPE)
  end
end

function TestRaster:testMirroringRefusesAnAxisItDoesNotKnow()
  local source = raster.fromRows(SHAPE)
  luaunit.assertErrorMsgContains("diagonal", rasterOps.mirror, source, "diagonal")
end

-- Shear displaces whole rows by whole numbers of pixels. It never resamples,
-- which is why it survives the pixel grid where a true affine shear does not.

function TestRaster:testShearDisplacesEachRowByAWholeNumberOfPixels()
  local source = raster.fromRows {
    "a",
    "a",
    "a",
  }
  local sheared, left = rasterOps.shear(source, { factor = 1, pivotRow = 0 })
  luaunit.assertEquals(raster.toRows(sheared), {
    "a..",
    ".a.",
    "..a",
  })
  luaunit.assertEquals(left, 0)
  raster.assertNoColourInvented(luaunit, source, sheared)
end

-- The whole reason the result grows: at any lean worth having, the rows
-- furthest from the pivot travel further than the picture is wide.

function TestRaster:testShearGrowsRatherThanLosingTheRowsThatTravelFurthest()
  local source = raster.fromRows {
    "a",
    "a",
    "a",
    "a",
    "a",
  }
  local sheared = rasterOps.shear(source, { factor = 1, pivotRow = 0 })
  luaunit.assertEquals(sheared.width, 5)
  luaunit.assertEquals(#matrix.colours(sheared), 1)
  for y = 0, 4 do
    luaunit.assertEquals(sheared:get(y, y), string.byte("a"), "row " .. y .. " was lost")
  end
end

function TestRaster:testShearReportsWhereTheNewLeftEdgeSits()
  local source = raster.fromRows { "a", "a", "a" }
  local _, left = rasterOps.shear(source, { factor = -1, pivotRow = 0 })
  -- Leaning the other way pushes rows to the left of where the picture began,
  -- so the caller is told how far the frame moved.
  luaunit.assertEquals(left, -2)
end

function TestRaster:testShearLeansTheOtherWayForANegativeFactor()
  local source = raster.fromRows { "a", "a", "a" }
  luaunit.assertEquals(raster.toRows(rasterOps.shear(source, { factor = -1, pivotRow = 0 })), {
    "..a",
    ".a.",
    "a..",
  })
end

function TestRaster:testShearPivotsAboutTheRowItWasGiven()
  local source = raster.fromRows { "a", "a", "a" }
  local sheared, left = rasterOps.shear(source, { factor = 1, pivotRow = 1 })
  luaunit.assertEquals(raster.toRows(sheared), { "a..", ".a.", "..a" })
  -- Pivoting about the middle row sends the first row one place left of where
  -- the picture started.
  luaunit.assertEquals(left, -1)
end

function TestRaster:testShearByNothingIsTheIdentity()
  local source = raster.fromRows(SHAPE)
  luaunit.assertEquals(raster.toRows(rasterOps.shear(source, { factor = 0 })), SHAPE)
end

function TestRaster:testAFractionalShearStillDisplacesByWholePixels()
  local source = raster.fromRows { "a", "a", "a", "a" }
  -- Half a pixel per row: the offsets round, so rows share displacements
  -- rather than landing between pixels.
  local sheared = rasterOps.shear(source, { factor = 0.5, pivotRow = 0 })
  luaunit.assertEquals(raster.toRows(sheared), {
    "a..",
    ".a.",
    ".a.",
    "..a",
  })
end

function TestRaster:testEveryTransformLeavesAnEmptyPictureEmpty()
  local empty = matrix.new(3, 3)
  luaunit.assertEquals(#matrix.colours(rasterOps.translate(empty, 1, 1)), 0)
  luaunit.assertEquals(#matrix.colours(rasterOps.mirror(empty, "horizontal")), 0)
  luaunit.assertEquals(#matrix.colours(rasterOps.shear(empty, { factor = 1 })), 0)
end

function TestRaster:testTheTransformsThatCannotLosePixelsKeepTheirSize()
  local source = raster.fromRows(SHAPE)
  for _, result in ipairs {
    rasterOps.translate(source, 1, 1),
    rasterOps.mirror(source, "vertical"),
  } do
    luaunit.assertEquals(result.width, source.width)
    luaunit.assertEquals(result.height, source.height)
  end
end

return { TestRaster = TestRaster }
