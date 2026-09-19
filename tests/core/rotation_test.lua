local luaunit = require("luaunit")
local rasterOps = require("core.raster")
local matrix = require("core.matrix")
local raster = require("tests.support.raster")

local TestRotation = {}

local SQUARE = { "ab", "cd" }

-- A quarter turn has an exact answer. If these ever drift, every angle in
-- between is wrong too and no amount of looking at a sheet will say why.

function TestRotation:testTurningByNothingIsTheIdentity()
  local source = raster.fromRows(SQUARE)
  local turned, left, top = rasterOps.rotate(source, 0)
  luaunit.assertEquals(raster.toRows(turned), SQUARE)
  luaunit.assertEquals(left, 0)
  luaunit.assertEquals(top, 0)
end

function TestRotation:testAQuarterTurnGoesClockwise()
  local source = raster.fromRows(SQUARE)
  luaunit.assertEquals(raster.toRows(rasterOps.rotate(source, 90)), { "ca", "db" })
end

function TestRotation:testAHalfTurn()
  local source = raster.fromRows(SQUARE)
  luaunit.assertEquals(raster.toRows(rasterOps.rotate(source, 180)), { "dc", "ba" })
end

function TestRotation:testThreeQuarterTurns()
  local source = raster.fromRows(SQUARE)
  luaunit.assertEquals(raster.toRows(rasterOps.rotate(source, 270)), { "bd", "ac" })
end

function TestRotation:testFourQuarterTurnsReturnTheOriginalExactly()
  local picture = raster.fromRows { "ab.", ".c.", "d.e" }
  local expected = raster.toRows(picture)
  for _ = 1, 4 do
    picture = rasterOps.rotate(picture, 90)
  end
  luaunit.assertEquals(raster.toRows(picture), expected)
end

function TestRotation:testAFullTurnIsTheIdentity()
  local source = raster.fromRows(SQUARE)
  luaunit.assertEquals(raster.toRows(rasterOps.rotate(source, 360)), SQUARE)
end

function TestRotation:testAnAngleBeyondAFullTurnIsTheSameAsTheAngleInside()
  local source = raster.fromRows(SQUARE)
  luaunit.assertEquals(
    raster.toRows(rasterOps.rotate(source, 450)),
    raster.toRows(rasterOps.rotate(source, 90))
  )
end

function TestRotation:testANegativeAngleTurnsTheOtherWay()
  local source = raster.fromRows(SQUARE)
  luaunit.assertEquals(
    raster.toRows(rasterOps.rotate(source, -90)),
    raster.toRows(rasterOps.rotate(source, 270))
  )
end

-- The frame is worked out from where the corners land, not guessed. A picture
-- that is not square must come back with its dimensions swapped.

function TestRotation:testATallPictureComesBackWide()
  local source = raster.fromRows { "a", "b", "c" }
  local turned = rasterOps.rotate(source, 90)
  luaunit.assertEquals(turned.width, 3)
  luaunit.assertEquals(turned.height, 1)
  luaunit.assertEquals(raster.toRows(turned), { "cba" })
end

function TestRotation:testNothingIsLostAtAnArbitraryAngle()
  local source = raster.fromRows { "aaaa", "aaaa", "aaaa", "aaaa" }
  local turned = rasterOps.rotate(source, 30)
  local before = 0
  for y = 0, source.height - 1 do
    for x = 0, source.width - 1 do
      if source:get(x, y) ~= source.transparent then
        before = before + 1
      end
    end
  end
  local after = 0
  for y = 0, turned.height - 1 do
    for x = 0, turned.width - 1 do
      if turned:get(x, y) ~= turned.transparent then
        after = after + 1
      end
    end
  end
  -- Sampling loses and duplicates pixels; what must not happen is the picture
  -- coming back empty or barely there.
  luaunit.assertTrue(after > before * 0.6, "the turn lost most of the picture")
end

function TestRotation:testAnArbitraryAngleInventsNoColour()
  local source = raster.fromRows { "ab.", ".c.", "d.e" }
  raster.assertNoColourInvented(luaunit, source, rasterOps.rotate(source, 37))
end

function TestRotation:testThePivotMovesTheFrameWithoutChangingThePicture()
  local source = raster.fromRows(SQUARE)
  local atCentre, leftCentre = rasterOps.rotate(source, 90)
  local atCorner, leftCorner = rasterOps.rotate(source, 90, { pivot = { x = 0, y = 0 } })
  luaunit.assertEquals(raster.toRows(atCorner), raster.toRows(atCentre))
  luaunit.assertNotEquals(leftCorner, leftCentre)
end

function TestRotation:testTheReportedOffsetPlacesTheTurnedPictureCorrectly()
  local source = raster.fromRows { "a", "b", "b" }
  local turned, left, top = rasterOps.rotate(source, 90, { pivot = { x = 0, y = 0 } })

  -- Put the turned picture back where the offsets say it belongs and the
  -- pixel that was at the pivot must still be at the pivot.
  luaunit.assertEquals(turned:get(0 - left, 0 - top), string.byte("a"))
end

function TestRotation:testTurningAnEmptyPictureGivesAnEmptyPicture()
  local turned = rasterOps.rotate(matrix.new(3, 3), 45)
  luaunit.assertEquals(#matrix.colours(turned), 0)
end

return { TestRotation = TestRotation }
