local luaunit = require("luaunit")
local parts = require("core.parts")

local TestParts = {}

local function rectangle(x, y, width, height)
  return { x = x, y = y, width = width, height = height }
end

local FIGURE = {
  { name = "torso", rect = rectangle(4, 8, 8, 9), pivot = { x = 4, y = 8 } },
  { name = "head", rect = rectangle(5, 2, 6, 6), pivot = { x = 3, y = 5 }, parent = "torso" },
  { name = "upper-arm", rect = rectangle(1, 9, 3, 5), pivot = { x = 2, y = 0 }, parent = "torso" },
  {
    name = "forearm",
    rect = rectangle(0, 14, 3, 5),
    pivot = { x = 2, y = 0 },
    parent = "upper-arm",
  },
}

-- A fraction along a rectangle, as a whole pixel. Both default pivots and the
-- slice reader's own go through this one rule, because the same idea measured
-- two different ways is how a limb ends up a pixel off in one direction only.

function TestParts:testAFractionOfNoughtIsTheFirstPixelAndOneIsTheLast()
  luaunit.assertEquals(parts.alongExtent(10, 0), 0)
  luaunit.assertEquals(parts.alongExtent(10, 1), 9)
  luaunit.assertEquals(parts.alongExtent(1, 0), 0)
  luaunit.assertEquals(parts.alongExtent(1, 1), 0)
end

function TestParts:testTheMiddleOfAnEvenRunAndAnOddRunBothLandInside()
  luaunit.assertEquals(parts.alongExtent(16, 0.5), 8)
  luaunit.assertEquals(parts.alongExtent(15, 0.5), 7)
  luaunit.assertEquals(parts.alongExtent(2, 0.5), 1)
end

-- The fallback. A drawing nobody has marked up is still a rig: one part, the
-- whole thing, which is how the old single-image motion keeps working.

function TestParts:testAnUnmarkedDrawingIsOnePartCoveringIt()
  local only = parts.fromWholeDrawing(rectangle(3, 4, 16, 24))
  luaunit.assertEquals(#only, 1)
  luaunit.assertEquals(only[1].rect, rectangle(3, 4, 16, 24))
  luaunit.assertNil(only[1].parent)
end

function TestParts:testTheWholeDrawingPivotsAboutItsOwnFeet()
  -- A body turns about where it stands, not about its middle.
  local only = parts.fromWholeDrawing(rectangle(0, 0, 16, 24))
  luaunit.assertEquals(only[1].pivot, { x = 8, y = 23 })
end

-- The tree.

function TestParts:testTheTreeFindsTheRoot()
  local tree = parts.tree(FIGURE)
  luaunit.assertEquals(#tree.roots, 1)
  luaunit.assertEquals(tree.roots[1], "torso")
end

function TestParts:testChildrenSitUnderTheirParent()
  local tree = parts.tree(FIGURE)
  luaunit.assertEquals(tree.childrenOf["torso"], { "head", "upper-arm" })
  luaunit.assertEquals(tree.childrenOf["upper-arm"], { "forearm" })
  luaunit.assertEquals(tree.childrenOf["forearm"], {})
end

function TestParts:testEveryPartIsReachableFromARoot()
  local tree = parts.tree(FIGURE)
  luaunit.assertEquals(#tree.order, 4)
  -- A parent always comes before its children, so drawing in this order never
  -- needs a transform that has not been worked out yet.
  local seen = {}
  for _, name in ipairs(tree.order) do
    local part = tree.byName[name]
    if part.parent then
      luaunit.assertTrue(seen[part.parent], name .. " came before its parent")
    end
    seen[name] = true
  end
end

function TestParts:testAMissingParentIsRefusedWithThePartNamed()
  local broken = {
    { name = "hand", rect = rectangle(0, 0, 2, 2), pivot = { x = 0, y = 0 }, parent = "arm" },
  }
  luaunit.assertErrorMsgContains("hand", parts.tree, broken)
  luaunit.assertErrorMsgContains("arm", parts.tree, broken)
end

function TestParts:testACycleIsRefusedWithThePartsNamed()
  local circular = {
    { name = "a", rect = rectangle(0, 0, 2, 2), pivot = { x = 0, y = 0 }, parent = "b" },
    { name = "b", rect = rectangle(0, 0, 2, 2), pivot = { x = 0, y = 0 }, parent = "a" },
  }
  luaunit.assertErrorMsgContains("in a circle", parts.tree, circular)
end

function TestParts:testAPartThatIsItsOwnParentIsRefused()
  local selfish = {
    { name = "a", rect = rectangle(0, 0, 2, 2), pivot = { x = 0, y = 0 }, parent = "a" },
  }
  luaunit.assertErrorMsgContains("in a circle", parts.tree, selfish)
end

function TestParts:testTwoPartsWithTheSameNameAreRefused()
  local twins = {
    { name = "arm", rect = rectangle(0, 0, 2, 2), pivot = { x = 0, y = 0 } },
    { name = "arm", rect = rectangle(4, 0, 2, 2), pivot = { x = 0, y = 0 } },
  }
  luaunit.assertErrorMsgContains("arm", parts.tree, twins)
end

function TestParts:testAPivotOutsideItsOwnPartIsRefused()
  local wrong = {
    { name = "arm", rect = rectangle(0, 0, 3, 5), pivot = { x = 9, y = 0 } },
  }
  luaunit.assertErrorMsgContains("pivot", parts.tree, wrong)
  luaunit.assertErrorMsgContains("arm", parts.tree, wrong)
end

function TestParts:testAPivotOnTheFarEdgeIsAllowed()
  -- A limb very often turns about its own last pixel.
  local edge = {
    { name = "arm", rect = rectangle(0, 0, 3, 5), pivot = { x = 2, y = 4 } },
  }
  luaunit.assertEquals(#parts.tree(edge).order, 1)
end

function TestParts:testAnEmptyRigIsRefusedRatherThanProducingNothingQuietly()
  luaunit.assertErrorMsgContains("no parts", parts.tree, {})
end

-- Forward kinematics. What a pose actually produces is, per part, the angle it
-- ended up turned by and where its pivot landed on the canvas.

local function nearly(luaunitRef, got, wanted, what)
  luaunitRef.assertAlmostEquals(got, wanted, 0.0001, what)
end

function TestParts:testAnEmptyPoseLeavesEveryPartWhereItWasDrawn()
  local placed = parts.solve(parts.tree(FIGURE), {})
  -- The torso's pivot sits at its rectangle's corner plus its own pivot.
  nearly(luaunit, placed["torso"].pivot.x, 8, "torso pivot x")
  nearly(luaunit, placed["torso"].pivot.y, 16, "torso pivot y")
  nearly(luaunit, placed["torso"].angle, 0, "torso angle")
  nearly(luaunit, placed["head"].pivot.x, 8, "head pivot x")
  nearly(luaunit, placed["head"].pivot.y, 7, "head pivot y")
end

function TestParts:testAPartsOwnTurnShowsUpInItsAngle()
  local placed = parts.solve(parts.tree(FIGURE), { ["upper-arm"] = { rotation = 30 } })
  nearly(luaunit, placed["upper-arm"].angle, 30, "the arm's own turn")
end

function TestParts:testAParentsTurnCarriesItsChildren()
  local placed = parts.solve(parts.tree(FIGURE), { torso = { rotation = 20 } })
  nearly(luaunit, placed["head"].angle, 20, "the head follows the torso")
  nearly(luaunit, placed["upper-arm"].angle, 20, "the arm follows the torso")
  nearly(luaunit, placed["forearm"].angle, 20, "the forearm follows too")
end

function TestParts:testTurnsAddDownTheChain()
  local placed = parts.solve(parts.tree(FIGURE), {
    torso = { rotation = 10 },
    ["upper-arm"] = { rotation = 20 },
    forearm = { rotation = 30 },
  })
  nearly(luaunit, placed["upper-arm"].angle, 30, "torso plus arm")
  nearly(luaunit, placed["forearm"].angle, 60, "torso plus arm plus forearm")
end

function TestParts:testAQuarterTurnOfTheTorsoSwingsTheHeadToWhereItShouldBe()
  -- The torso pivots at 8,16. The head's pivot rests at 8,7 - nine pixels
  -- straight up. Turned a quarter clockwise, nine pixels up becomes nine
  -- pixels to the right.
  local placed = parts.solve(parts.tree(FIGURE), { torso = { rotation = 90 } })
  nearly(luaunit, placed["head"].pivot.x, 17, "the head swung right")
  nearly(luaunit, placed["head"].pivot.y, 16, "the head came level")
end

function TestParts:testAPartsOwnTurnDoesNotMoveItsOwnPivot()
  local placed = parts.solve(parts.tree(FIGURE), { torso = { rotation = 90 } })
  nearly(luaunit, placed["torso"].pivot.x, 8, "the torso turned about itself")
  nearly(luaunit, placed["torso"].pivot.y, 16, "the torso turned about itself")
end

function TestParts:testAnOffsetMovesAPartAndEverythingUnderIt()
  local placed = parts.solve(parts.tree(FIGURE), { torso = { offset = { x = 5, y = -2 } } })
  nearly(luaunit, placed["torso"].pivot.x, 13, "the torso moved")
  nearly(luaunit, placed["head"].pivot.x, 13, "the head came along")
  nearly(luaunit, placed["head"].pivot.y, 5, "the head came along vertically")
end

function TestParts:testAPoseNamingAPartThatIsNotInTheRigIsRefused()
  luaunit.assertErrorMsgContains(
    "tail",
    parts.solve,
    parts.tree(FIGURE),
    { tail = { rotation = 1 } }
  )
end

function TestParts:testEveryPartComesBackPlaced()
  local placed = parts.solve(parts.tree(FIGURE), {})
  for _, part in ipairs(FIGURE) do
    luaunit.assertNotNil(placed[part.name], part.name .. " was not placed")
  end
end

-- Three levels. A two-level rig passing does not prove that a grandchild is
-- carried correctly, because at two levels the inherited angle and the total
-- angle are the same number. These expectations were worked out by hand from
-- the geometry, not read back out of the solver.

local CHAIN = {
  { name = "shoulder", rect = rectangle(16, 20, 8, 8), pivot = { x = 4, y = 0 } },
  {
    name = "elbow",
    rect = rectangle(16, 30, 8, 8),
    pivot = { x = 4, y = 0 },
    parent = "shoulder",
  },
  { name = "wrist", rect = rectangle(16, 40, 8, 8), pivot = { x = 4, y = 0 }, parent = "elbow" },
}

-- Rest pivots: shoulder 20,20, elbow 20,30, wrist 20,40. Each hangs ten below
-- the one above it, so the arithmetic below is readable rather than magic.
local function chainPose(shoulder, elbow)
  return parts.solve(parts.tree(CHAIN), {
    shoulder = { rotation = shoulder },
    elbow = { rotation = elbow },
  })
end

function TestParts:testAGrandchildInheritsBothAnglesAbove()
  local placed = chainPose(90, 90)
  -- Each angle is the total the part ended up at, not the amount it was asked
  -- to turn. The shoulder turned a quarter and stays at a quarter. The elbow
  -- was asked for another quarter on top of that, so it sits at half a turn.
  -- The wrist was asked for nothing, and still sits at half a turn, because
  -- everything above it carried it there.
  luaunit.assertAlmostEquals(placed.shoulder.angle, 90, 1e-9)
  luaunit.assertAlmostEquals(placed.elbow.angle, 180, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.angle, 180, 1e-9)
end

function TestParts:testAGrandchildIsCarriedByEveryTurnAboveIt()
  -- The shoulder turns a quarter clockwise on screen. The elbow sat ten below
  -- it, so it swings to ten to the left: 10,20. The wrist sat ten below the
  -- elbow, and both turns carry it, so it swings a further ten left: 0,20.
  local placed = chainPose(90, 0)
  luaunit.assertAlmostEquals(placed.elbow.pivot.x, 10, 1e-9)
  luaunit.assertAlmostEquals(placed.elbow.pivot.y, 20, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.pivot.x, 0, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.pivot.y, 20, 1e-9)
end

function TestParts:testATurnAtTheElbowLeavesTheShoulderWhereItWas()
  -- Only what hangs below a joint may move when it turns.
  local placed = chainPose(0, 90)
  luaunit.assertAlmostEquals(placed.shoulder.pivot.x, 20, 1e-9)
  luaunit.assertAlmostEquals(placed.shoulder.pivot.y, 20, 1e-9)
  luaunit.assertAlmostEquals(placed.elbow.pivot.x, 20, 1e-9)
  luaunit.assertAlmostEquals(placed.elbow.pivot.y, 30, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.pivot.x, 10, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.pivot.y, 30, 1e-9)
end

function TestParts:testAPushAtTheShoulderCarriesEverythingBelowIt()
  -- An offset is in canvas units and must travel down the chain, or a limb
  -- detaches from the body the moment the body moves.
  local placed = parts.solve(parts.tree(CHAIN), {
    shoulder = { offset = { x = 7, y = -3 } },
  })
  luaunit.assertAlmostEquals(placed.elbow.pivot.x, 27, 1e-9)
  luaunit.assertAlmostEquals(placed.elbow.pivot.y, 27, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.pivot.x, 27, 1e-9)
  luaunit.assertAlmostEquals(placed.wrist.pivot.y, 37, 1e-9)
end

return { TestParts = TestParts }
