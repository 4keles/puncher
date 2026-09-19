local luaunit = require("luaunit")
local rasterOps = require("core.raster")
local matrix = require("core.matrix")
local raster = require("tests.support.raster")

local TestResample = {}

-- Enlarging. The point is not size, it is room: a turn needs somewhere finer
-- than the pixel grid to happen in. The filter must never blend, so every
-- pixel it writes has to be one it copied from a neighbour.

function TestResample:testEnlargingDoublesBothDimensions()
  local enlarged = rasterOps.enlarge(raster.fromRows { "ab", "cd" })
  luaunit.assertEquals(enlarged.width, 4)
  luaunit.assertEquals(enlarged.height, 4)
end

function TestResample:testAFlatRegionEnlargesUnchanged()
  local source = raster.fromRows { "aaa", "aaa", "aaa" }
  local enlarged = rasterOps.enlarge(source)
  for y = 0, enlarged.height - 1 do
    for x = 0, enlarged.width - 1 do
      luaunit.assertEquals(enlarged:get(x, y), string.byte("a"))
    end
  end
end

function TestResample:testAStaircaseGainsTheCornerThatSmoothsIt()
  -- A two-step staircase. The filter's whole job is to fill the inner corner
  -- where two like neighbours meet, which is what turns a jagged edge into a
  -- clean diagonal once the picture is reduced again.
  local source = raster.fromRows {
    "a.",
    "aa",
  }
  local enlarged = rasterOps.enlarge(source)
  luaunit.assertEquals(raster.toRows(enlarged), {
    "aa..",
    "aaa.",
    "aaaa",
    "aaaa",
  })
end

function TestResample:testEnlargingInventsNoColour()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  raster.assertNoColourInvented(luaunit, source, rasterOps.enlarge(source))
end

function TestResample:testEnlargingTwiceGivesFourTimesTheSize()
  local source = raster.fromRows { "ab", "cd" }
  local enlarged = rasterOps.enlarge(rasterOps.enlarge(source))
  luaunit.assertEquals(enlarged.width, 8)
  luaunit.assertEquals(enlarged.height, 8)
end

function TestResample:testEnlargingToAFactorAppliesTheFilterRepeatedly()
  local source = raster.fromRows { "ab", "cd" }
  local byFactor = rasterOps.enlargeBy(source, 8)
  luaunit.assertEquals(byFactor.width, 16)
  luaunit.assertEquals(byFactor.height, 16)
end

function TestResample:testEnlargingRefusesAFactorItCannotReachByDoubling()
  local source = raster.fromRows { "ab", "cd" }
  luaunit.assertErrorMsgContains("doubling", rasterOps.enlargeBy, source, 3)
end

-- Reducing. This is where a colour would be invented if anything averaged, so
-- it picks a value that was already in the block instead.

function TestResample:testReducingAUniformBlockGivesThatValue()
  local source = raster.fromRows { "aa", "aa" }
  luaunit.assertEquals(raster.toRows(rasterOps.reduce(source, 2)), { "a" })
end

function TestResample:testReducingTakesTheValueMostOfTheBlockHolds()
  local source = raster.fromRows { "aa", "ab" }
  luaunit.assertEquals(raster.toRows(rasterOps.reduce(source, 2)), { "a" })
end

function TestResample:testATieKeepsTheDrawnValueRatherThanTheEmptyOne()
  -- Half drawn, half empty. Eroding the silhouette on every reduction would
  -- eat a small sprite alive, so a drawn value wins.
  local source = raster.fromRows { "a.", "a." }
  luaunit.assertEquals(raster.toRows(rasterOps.reduce(source, 2)), { "a" })
end

function TestResample:testATieBetweenTwoDrawnValuesResolvesTheSameWayEveryTime()
  local source = raster.fromRows { "ab", "ba" }
  local first = raster.toRows(rasterOps.reduce(source, 2))
  for _ = 1, 20 do
    luaunit.assertEquals(raster.toRows(rasterOps.reduce(source, 2)), first)
  end
end

function TestResample:testReducingDividesBothDimensions()
  local source = matrix.new(8, 4)
  local reduced = rasterOps.reduce(source, 4)
  luaunit.assertEquals(reduced.width, 2)
  luaunit.assertEquals(reduced.height, 1)
end

function TestResample:testReducingInventsNoColour()
  local source = raster.fromRows { "ab", "cd" }
  raster.assertNoColourInvented(luaunit, source, rasterOps.reduce(source, 2))
end

function TestResample:testReducingRefusesAFactorThatDoesNotDivideThePicture()
  local source = matrix.new(5, 4)
  luaunit.assertErrorMsgContains("divide", rasterOps.reduce, source, 2)
end

function TestResample:testEnlargingThenReducingReturnsTheOriginal()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  local round = rasterOps.reduce(rasterOps.enlargeBy(source, 4), 4)
  luaunit.assertEquals(raster.toRows(round), raster.toRows(source))
end

-- The detour: enlarge, turn there, vote back down.

function TestResample:testTurningThroughTheDetourInventsNoColour()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  raster.assertNoColourInvented(luaunit, source, rasterOps.rotateSmoothly(source, 23))
end

function TestResample:testTheDetourLeavesASolidShapeSolidOnAQuarterTurn()
  local source = raster.fromRows { "aaaa", "aaaa", "aaaa", "aaaa" }
  local turned = rasterOps.rotateSmoothly(source, 90, { factor = 4 })
  local drawn = matrix.shrinkBounds(turned)
  luaunit.assertNotNil(drawn)
  luaunit.assertEquals(drawn.width, 4)
  luaunit.assertEquals(drawn.height, 4)
end

function TestResample:testTheDetourReportsAWholePixelOffset()
  local source = raster.fromRows { "ab", "cd" }
  local _, left, top = rasterOps.rotateSmoothly(source, 37, { factor = 4 })
  luaunit.assertEquals(left % 1, 0)
  luaunit.assertEquals(top % 1, 0)
end

function TestResample:testTheDetourKeepsMoreOfTheShapeThanTurningDirectlyDoes()
  -- A thin bar at an awkward angle is where a direct turn falls apart: it
  -- samples the same source pixel into several destination pixels and misses
  -- others entirely. The detour should hold on to more of it.
  local source = raster.fromRows {
    "aaaaaaaa",
    "aaaaaaaa",
    "........",
    "........",
    "........",
    "........",
    "........",
    "........",
  }
  local function drawnCount(picture)
    local total = 0
    for y = 0, picture.height - 1 do
      for x = 0, picture.width - 1 do
        if picture:get(x, y) ~= picture.transparent then
          total = total + 1
        end
      end
    end
    return total
  end

  local direct = drawnCount(rasterOps.rotate(source, 20))
  local detour = drawnCount(rasterOps.rotateSmoothly(source, 20, { factor = 8 }))
  luaunit.assertTrue(
    detour >= direct,
    ("the detour kept %d pixels, the direct turn %d"):format(detour, direct)
  )
end

-- The third way: refuse any angle that is not free.

function TestResample:testSnappingChoosesTheNearestQuarterTurn()
  local source = raster.fromRows { "ab", "cd" }
  local _, _, _, used = rasterOps.rotateToNearestExact(source, 80)
  luaunit.assertEquals(used, 90)
end

function TestResample:testSnappingLeavesASmallAngleAlone()
  local source = raster.fromRows { "ab", "cd" }
  local turned, _, _, used = rasterOps.rotateToNearestExact(source, 20)
  luaunit.assertEquals(used, 0)
  luaunit.assertEquals(raster.toRows(turned), { "ab", "cd" })
end

function TestResample:testSnappingCrossesTheWrapPointCorrectly()
  local source = raster.fromRows { "ab", "cd" }
  local _, _, _, used = rasterOps.rotateToNearestExact(source, 350)
  luaunit.assertEquals(used, 0)
end

function TestResample:testSnappingNeverInventsAColour()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  raster.assertNoColourInvented(luaunit, source, rasterOps.rotateToNearestExact(source, 100))
end

-- The route the engine actually takes.

function TestResample:testAQuarterTurnGoesTheExactWay()
  local source = raster.fromRows { "ab", "cd" }
  luaunit.assertEquals(
    raster.toRows(rasterOps.turn(source, 90)),
    raster.toRows(rasterOps.rotate(source, 90))
  )
end

function TestResample:testAnAngleBetweenQuarterTurnsTakesTheDetour()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  luaunit.assertEquals(
    raster.toRows(rasterOps.turn(source, 30)),
    raster.toRows(rasterOps.rotateSmoothly(source, 30))
  )
end

function TestResample:testTurningByNothingLeavesThePictureAlone()
  local source = raster.fromRows { "ab", "cd" }
  luaunit.assertEquals(raster.toRows(rasterOps.turn(source, 0)), { "ab", "cd" })
end

function TestResample:testTurningInventsNoColourWhicheverRouteItTakes()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  for _, degrees in ipairs { 0, 30, 90, 137, 180, 270 } do
    raster.assertNoColourInvented(luaunit, source, rasterOps.turn(source, degrees))
  end
end

return { TestResample = TestResample }
