local luaunit = require("luaunit")
local drawlist = require("core.drawlist")
local parts = require("core.parts")

local TestDrawList = {}

local function rectangle(x, y, width, height)
  return { x = x, y = y, width = width, height = height }
end

local FIGURE = {
  { name = "torso", rect = rectangle(4, 8, 8, 9), pivot = { x = 4, y = 8 } },
  { name = "arm", rect = rectangle(1, 9, 3, 5), pivot = { x = 2, y = 0 }, parent = "torso" },
}

local function tree()
  return parts.tree(FIGURE)
end

function TestDrawList:testAFrameCarriesOneInstructionPerPart()
  local list = drawlist.fromPoses {
    tree = tree(),
    layer = "Puncher",
    frames = { { duration = 60, pose = {} } },
  }
  luaunit.assertEquals(#list.frames, 1)
  luaunit.assertEquals(#list.frames[1].draws, 2)
end

function TestDrawList:testInstructionsComeInDrawingOrderParentFirst()
  local list = drawlist.fromPoses {
    tree = tree(),
    layer = "Puncher",
    frames = { { duration = 60, pose = {} } },
  }
  luaunit.assertEquals(list.frames[1].draws[1].part, "torso")
  luaunit.assertEquals(list.frames[1].draws[2].part, "arm")
end

-- The rig above has two parts, and with two entries a walk over a hash table
-- can land on the right order by chance. A body has more than two, and the
-- order they are drawn in is what decides which limb is in front, so it has to
-- be the tree's order every time rather than whatever the table hands back.
local DEEP_FIGURE = {
  { name = "torso", rect = rectangle(4, 8, 8, 9), pivot = { x = 4, y = 8 } },
  { name = "head", rect = rectangle(5, 2, 6, 6), pivot = { x = 3, y = 5 }, parent = "torso" },
  { name = "upper-arm", rect = rectangle(1, 9, 3, 5), pivot = { x = 2, y = 0 }, parent = "torso" },
  {
    name = "forearm",
    rect = rectangle(0, 14, 3, 5),
    pivot = { x = 2, y = 0 },
    parent = "upper-arm",
  },
  { name = "hand", rect = rectangle(0, 19, 2, 2), pivot = { x = 1, y = 0 }, parent = "forearm" },
  { name = "legs", rect = rectangle(4, 17, 8, 6), pivot = { x = 4, y = 0 }, parent = "torso" },
  { name = "foot", rect = rectangle(4, 23, 4, 2), pivot = { x = 2, y = 0 }, parent = "legs" },
}

function TestDrawList:testEveryPartIsDrawnAfterTheOneItHangsFrom()
  local built = parts.tree(DEEP_FIGURE)
  local list = drawlist.fromPoses {
    tree = built,
    layer = "Puncher",
    frames = { { duration = 60, pose = {} } },
  }

  local drawnAt = {}
  for index, draw in ipairs(list.frames[1].draws) do
    drawnAt[draw.part] = index
  end

  luaunit.assertEquals(#list.frames[1].draws, #DEEP_FIGURE, "a part was left out")
  for _, part in ipairs(DEEP_FIGURE) do
    luaunit.assertNotNil(drawnAt[part.name], part.name .. " was never drawn")
    if part.parent then
      luaunit.assertTrue(
        drawnAt[part.parent] < drawnAt[part.name],
        part.name .. " is drawn before " .. part.parent .. ", which it hangs from"
      )
    end
  end
end

function TestDrawList:testTheOrderIsTheSameEveryTime()
  -- Determinism is a promise this project makes: the same parameters produce
  -- the same frames. An order that came from a hash table would not survive
  -- being asked twice in the same run, let alone twice on different machines.
  local built = parts.tree(DEEP_FIGURE)
  local function orderOf()
    local list = drawlist.fromPoses {
      tree = built,
      layer = "Puncher",
      frames = { { duration = 60, pose = {} } },
    }
    local names = {}
    for _, draw in ipairs(list.frames[1].draws) do
      names[#names + 1] = draw.part
    end
    return table.concat(names, ",")
  end

  local first = orderOf()
  for _ = 1, 20 do
    luaunit.assertEquals(orderOf(), first, "the drawing order changed between runs")
  end
end

function TestDrawList:testAnInstructionSaysWhereThePivotLandsAndHowFarItTurned()
  local list = drawlist.fromPoses {
    tree = tree(),
    layer = "Puncher",
    frames = { { duration = 60, pose = { arm = { rotation = 45 } } } },
  }
  local arm = list.frames[1].draws[2]
  luaunit.assertEquals(arm.angle, 45)
  luaunit.assertEquals(arm.pivot, { x = 3, y = 9 })
  luaunit.assertEquals(arm.layer, "Puncher")
end

function TestDrawList:testDurationsAndHoldsCarryThrough()
  local list = drawlist.fromPoses {
    tree = tree(),
    layer = "Puncher",
    frames = {
      { duration = 120, held = true, pose = {} },
      { duration = 30, held = false, pose = {} },
    },
  }
  luaunit.assertEquals(list.frames[1].duration, 120)
  luaunit.assertTrue(list.frames[1].held)
  luaunit.assertEquals(list.frames[2].duration, 30)
  luaunit.assertFalse(list.frames[2].held)
end

function TestDrawList:testTheLayersUsedAreReportedOnce()
  local list = drawlist.fromPoses {
    tree = tree(),
    layer = "Puncher",
    frames = { { duration = 60, pose = {} }, { duration = 60, pose = {} } },
  }
  luaunit.assertEquals(list.layers, { "Puncher" })
end

-- A motion path is the degenerate case: one part, pushed about, never turned.
-- This is how the animation the engine produced before parts existed keeps
-- being produced, through the same machinery as everything else.

function TestDrawList:testAMotionPathBecomesAListThatPushesOnePart()
  local whole = parts.tree(parts.fromWholeDrawing(rectangle(0, 0, 16, 24)))
  local list = drawlist.fromMotionPath {
    tree = whole,
    part = "body",
    layer = "Puncher Dash",
    path = {
      { x = 0, y = 0, duration = 100, held = true },
      { x = 5, y = -2, duration = 60, held = false },
    },
  }

  luaunit.assertEquals(#list.frames, 2)
  luaunit.assertEquals(list.frames[1].draws[1].angle, 0)
  -- The whole-drawing part pivots at the middle of its bottom edge.
  luaunit.assertEquals(list.frames[1].draws[1].pivot, { x = 8, y = 23 })
  luaunit.assertEquals(list.frames[2].draws[1].pivot, { x = 13, y = 21 })
  luaunit.assertEquals(list.frames[2].duration, 60)
end

-- The validator. Its job is to refuse, not to skip: an instruction that cannot
-- be drawn has to stop the run, because a frame quietly missing a limb is
-- the kind of fault that is noticed three tracks later.

local function valid()
  return {
    layers = { "Puncher" },
    frames = {
      {
        duration = 60,
        draws = { { part = "torso", angle = 0, pivot = { x = 1, y = 2 }, layer = "Puncher" } },
      },
    },
  }
end

function TestDrawList:testAWellFormedListPasses()
  luaunit.assertTrue(drawlist.validate(valid(), tree()))
end

function TestDrawList:testAnInstructionNamingAPartThatIsNotInTheRigIsRefused()
  local list = valid()
  list.frames[1].draws[1].part = "tail"
  luaunit.assertErrorMsgContains("tail", drawlist.validate, list, tree())
  luaunit.assertErrorMsgContains("frame 1", drawlist.validate, list, tree())
end

function TestDrawList:testAnInstructionWithNoAngleIsRefused()
  local list = valid()
  list.frames[1].draws[1].angle = nil
  luaunit.assertErrorMsgContains("angle", drawlist.validate, list, tree())
end

function TestDrawList:testAnInstructionWithNoPivotIsRefused()
  local list = valid()
  list.frames[1].draws[1].pivot = nil
  luaunit.assertErrorMsgContains("pivot", drawlist.validate, list, tree())
end

function TestDrawList:testAnInstructionWithNoLayerIsRefused()
  local list = valid()
  list.frames[1].draws[1].layer = nil
  luaunit.assertErrorMsgContains("layer", drawlist.validate, list, tree())
end

function TestDrawList:testAnInstructionDrawingOnALayerTheListNeverDeclaresIsRefused()
  -- The adapter creates exactly the layers the list declares and then looks
  -- each instruction's layer up among them. One that was never declared is
  -- not a drawing that lands somewhere unexpected; it is a drawing that lands
  -- nowhere, which is the failure this validator exists to catch.
  local list = valid()
  list.frames[1].draws[1].layer = "Puncher Effects"
  luaunit.assertErrorMsgContains("never declares", drawlist.validate, list, tree())
  luaunit.assertErrorMsgContains("Puncher Effects", drawlist.validate, list, tree())
end

function TestDrawList:testAListDeclaringNoLayerIsRefused()
  local list = valid()
  list.layers = {}
  luaunit.assertErrorMsgContains("no layer", drawlist.validate, list, tree())
end

function TestDrawList:testAFrameWithNoDurationIsRefused()
  local list = valid()
  list.frames[1].duration = nil
  luaunit.assertErrorMsgContains("duration", drawlist.validate, list, tree())
end

function TestDrawList:testAFrameWithANegativeDurationIsRefused()
  local list = valid()
  list.frames[1].duration = -1
  luaunit.assertErrorMsgContains("duration", drawlist.validate, list, tree())
end

function TestDrawList:testAListWithNoFramesIsRefusedRatherThanProducingNothing()
  local list = valid()
  list.frames = {}
  luaunit.assertErrorMsgContains("no frames", drawlist.validate, list, tree())
end

function TestDrawList:testAFrameThatDrawsNothingIsRefused()
  local list = valid()
  list.frames[1].draws = {}
  luaunit.assertErrorMsgContains("frame 1", drawlist.validate, list, tree())
end

function TestDrawList:testTheRefusalNamesWhichInstructionIsWrong()
  local list = valid()
  table.insert(list.frames[1].draws, { part = "arm", pivot = { x = 0, y = 0 }, layer = "Puncher" })
  luaunit.assertErrorMsgContains("instruction 2", drawlist.validate, list, tree())
end

function TestDrawList:testWhatTheProducerMakesAlwaysPassesTheValidator()
  local list = drawlist.fromPoses {
    tree = tree(),
    layer = "Puncher",
    frames = { { duration = 60, pose = { arm = { rotation = 12 } } } },
  }
  luaunit.assertTrue(drawlist.validate(list, tree()))
end

-- A swing laid over a motion: one part turning while the body travels. When
-- the rig has no part by that name nothing swings, which is what lets one
-- command serve a marked-up character and an unmarked one.

local SWING = { part = "arm", from = -20, to = 60, curve = "linear" }

local function dashWithSwing(rigTree, movingPart)
  return drawlist.fromMotionPath {
    tree = rigTree,
    part = movingPart,
    layer = "Puncher",
    swing = SWING,
    path = {
      { x = 0, y = 0, duration = 60, held = false, progress = 0 },
      { x = 10, y = 0, duration = 60, held = false, progress = 0.5 },
      { x = 20, y = 0, duration = 60, held = false, progress = 1 },
    },
  }
end

-- The swing above uses a straight curve, where easing and not easing produce
-- the same number, so it cannot tell whether the curve is consulted at all.
-- The preset that ships uses a shaped one, and a swing that ignored its curve
-- would sweep at a constant rate - which is the difference between a limb
-- thrown and a limb turned.

local function swungWith(curveName)
  return drawlist.fromMotionPath {
    tree = tree(),
    part = "torso",
    layer = "Puncher",
    swing = { part = "arm", from = -20, to = 60, curve = curveName },
    path = {
      { x = 0, y = 0, duration = 60, held = false, progress = 0 },
      { x = 10, y = 0, duration = 60, held = false, progress = 0.5 },
      { x = 20, y = 0, duration = 60, held = false, progress = 1 },
    },
  }
end

function TestDrawList:testASwingFollowsItsOwnCurveRatherThanASteadyRate()
  -- Fast out and settling: three quarters of the way round by halfway through
  -- rather than half. From -20 through 80 degrees, cubicOut puts the middle
  -- frame at -20 + 80 * 0.875, which is 50 and not 20.
  local list = swungWith("cubicOut")
  luaunit.assertAlmostEquals(list.frames[2].draws[2].angle, 50, 0.0001)
end

function TestDrawList:testTwoDifferentCurvesDoNotProduceTheSameSwing()
  local fastOut = swungWith("cubicOut")
  local slowOut = swungWith("cubicIn")
  luaunit.assertNotEquals(
    fastOut.frames[2].draws[2].angle,
    slowOut.frames[2].draws[2].angle,
    "the curve named made no difference to the swing"
  )
  -- And both still arrive at the same place, because a curve changes the
  -- timing of a swing and not its extent.
  luaunit.assertAlmostEquals(fastOut.frames[3].draws[2].angle, 60, 0.0001)
  luaunit.assertAlmostEquals(slowOut.frames[3].draws[2].angle, 60, 0.0001)
  luaunit.assertAlmostEquals(fastOut.frames[1].draws[2].angle, -20, 0.0001)
  luaunit.assertAlmostEquals(slowOut.frames[1].draws[2].angle, -20, 0.0001)
end

function TestDrawList:testASwingTurnsItsPartThroughTheAngleAsked()
  local list = dashWithSwing(tree(), "torso")
  luaunit.assertAlmostEquals(list.frames[1].draws[2].angle, -20, 0.0001)
  luaunit.assertAlmostEquals(list.frames[2].draws[2].angle, 20, 0.0001)
  luaunit.assertAlmostEquals(list.frames[3].draws[2].angle, 60, 0.0001)
end

function TestDrawList:testASwingLeavesTheTravellingPartUnturned()
  local list = dashWithSwing(tree(), "torso")
  for _, frame in ipairs(list.frames) do
    luaunit.assertEquals(frame.draws[1].angle, 0)
  end
end

function TestDrawList:testTheBodyStillTravelsWhileSomethingSwings()
  local list = dashWithSwing(tree(), "torso")
  luaunit.assertEquals(list.frames[1].draws[1].pivot.x, 8)
  luaunit.assertEquals(list.frames[3].draws[1].pivot.x, 28)
end

function TestDrawList:testNothingSwingsWhenTheRigHasNoSuchPart()
  local whole = parts.tree(parts.fromWholeDrawing(rectangle(0, 0, 16, 24)))
  local withSwing = drawlist.fromMotionPath {
    tree = whole,
    part = "body",
    layer = "Puncher",
    swing = SWING,
    path = { { x = 4, y = 0, duration = 60, held = false, progress = 1 } },
  }
  local without = drawlist.fromMotionPath {
    tree = whole,
    part = "body",
    layer = "Puncher",
    path = { { x = 4, y = 0, duration = 60, held = false, progress = 1 } },
  }
  luaunit.assertEquals(withSwing, without)
end

return { TestDrawList = TestDrawList }
