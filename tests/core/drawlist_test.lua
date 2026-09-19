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

return { TestDrawList = TestDrawList }
