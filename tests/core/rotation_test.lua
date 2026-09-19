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

-- The property a limb depends on. A part turns about a joint, and the joint is
-- the one point that must not move: if it drifts by even a pixel as the angle
-- changes, an arm walks away from its shoulder over the course of a swing and
-- no amount of correct placement elsewhere can hide it.
--
-- This is easy to get wrong invisibly. The turn goes eightfold finer, rotates,
-- pads the frame out to a boundary the reduction can divide, and reduces; the
-- offset it reports has to account for all of that. A mistake anywhere in that
-- chain shows up here as drift and nowhere else as anything.

--- Where the marked pixels sit in a picture, as an average position.
-- A single pixel can be voted away by the reduction, so the marker is a block
-- and its centre is what gets compared. That makes the check robust to the
-- turn losing a pixel of it without making it blind to the block moving.
local function centreOfMarker(picture, marker)
  local sumX, sumY, count = 0, 0, 0
  for y = 0, picture.height - 1 do
    for x = 0, picture.width - 1 do
      if picture:get(x, y) == marker then
        sumX = sumX + x
        sumY = sumY + y
        count = count + 1
      end
    end
  end
  if count == 0 then
    return nil
  end
  return sumX / count, sumY / count
end

local JOINT = string.byte("j")

-- How far the joint's measured centre may sit from where the geometry puts
-- it. Not zero, because the reduction votes and can shave a pixel off the
-- marker or add one, which moves its average. A third of a pixel is what the
-- turn actually achieves once it works about the middle of a block rather
-- than its corner, and it is tight enough that the four-fifths of a pixel the
-- corner version drifted would fail here.
local JOINT_TOLERANCE = 0.35

--- Turn a limb and check the joint ends up where turning about it says it
--- should, given the offsets the turn reported.
--
-- The pivot is the fixed point, so any point of the drawing lands at the pivot
-- plus its own offset from the pivot, turned. Subtracting where the frame
-- moved to gives its place inside the result. Getting that expectation from
-- the geometry rather than from the offsets is what makes this a check on the
-- offsets rather than a restatement of them.
local function jointHolds(luaunitRef, rows, pivot, angles)
  local limb = raster.fromRows(rows)
  local markerX, markerY = centreOfMarker(limb, JOINT)
  luaunitRef.assertNotNil(markerX, "the subject has no joint marked")

  for _, degrees in ipairs(angles) do
    local turned, left, top = rasterOps.turn(limb, degrees, { pivot = pivot })

    local radians = math.rad(degrees % 360)
    local cosine, sine = math.cos(radians), math.sin(radians)
    local dx = markerX - pivot.x
    local dy = markerY - pivot.y
    local wantX = pivot.x + dx * cosine - dy * sine - left
    local wantY = pivot.y + dx * sine + dy * cosine - top

    local gotX, gotY = centreOfMarker(turned, JOINT)
    luaunitRef.assertNotNil(gotX, "the joint was lost entirely at " .. degrees)
    luaunitRef.assertAlmostEquals(
      gotX,
      wantX,
      JOINT_TOLERANCE,
      "the joint drifted horizontally at " .. degrees
    )
    luaunitRef.assertAlmostEquals(
      gotY,
      wantY,
      JOINT_TOLERANCE,
      "the joint drifted vertically at " .. degrees
    )
  end
end

local SWING_ANGLES = { -90, -70, -45, -25, -10, 0, 10, 25, 45, 70, 90, 135, 180, 250, 359 }

function TestRotation:testTheJointDoesNotDriftAtAnyAngle()
  -- A limb with its joint marked at the top, which is where a shoulder or a
  -- knee is. If the joint drifts as the angle changes, an arm walks away from
  -- its shoulder over a swing and no amount of correct placement elsewhere
  -- hides it.
  jointHolds(luaunit, {
    "jjaa",
    "jjaa",
    ".aa.",
    ".aa.",
    ".aa.",
    ".aa.",
  }, { x = 1, y = 1 }, SWING_ANGLES)
end

function TestRotation:testTheJointHoldsWhenItSitsInACorner()
  -- Which is where this project actually puts a shoulder: the corner of the
  -- limb that touches the body.
  jointHolds(luaunit, {
    "aajj",
    "aajj",
    "aa..",
    "aa..",
    "aa..",
  }, { x = 3, y = 1 }, SWING_ANGLES)
end

function TestRotation:testTheReportedOffsetIsAWholePixelAtEveryAngle()
  -- The turn works eight times finer than the picture and has to come back to
  -- whole pixels. A fractional offset would mean the adapter rounds a limb
  -- into place differently from one frame to the next, which reads as a jitter
  -- that no parameter can remove.
  local limb = raster.fromRows { "ab", "ab", "ab" }
  for degrees = -180, 180, 7 do
    local _, left, top = rasterOps.turn(limb, degrees, { pivot = { x = 1, y = 0 } })
    luaunit.assertEquals(left % 1, 0, "a fractional left offset at " .. degrees)
    luaunit.assertEquals(top % 1, 0, "a fractional top offset at " .. degrees)
  end
end

return { TestRotation = TestRotation }
