local luaunit = require("luaunit")
local easing = require("core.easing")

local EPSILON = 1e-9

-- Curves that must stay inside the unit range. Overshoot curves are tested
-- separately, because exceeding the target is exactly what they are for.
local BOUNDED = {
  "linear",
  "quadIn",
  "quadOut",
  "quadInOut",
  "cubicIn",
  "cubicOut",
  "cubicInOut",
  "expoIn",
  "expoOut",
}

local TestEasing = {}

function TestEasing:testEveryCurveStartsAtZeroAndEndsAtOne()
  for name, curve in pairs(easing.curves) do
    luaunit.assertAlmostEquals(curve(0), 0, EPSILON, name .. " must start at zero")
    luaunit.assertAlmostEquals(curve(1), 1, EPSILON, name .. " must end at one")
  end
end

function TestEasing:testBoundedCurvesStayInsideTheUnitRange()
  for _, name in ipairs(BOUNDED) do
    local curve = easing.curves[name]
    for step = 0, 100 do
      local value = curve(step / 100)
      luaunit.assertTrue(value >= -EPSILON, name .. " dipped below zero")
      luaunit.assertTrue(value <= 1 + EPSILON, name .. " rose above one")
    end
  end
end

function TestEasing:testOutFormMirrorsTheInForm()
  local pairsToCheck = {
    { "quadIn", "quadOut" },
    { "cubicIn", "cubicOut" },
    { "expoIn", "expoOut" },
  }

  for _, entry in ipairs(pairsToCheck) do
    local easeIn = easing.curves[entry[1]]
    local easeOut = easing.curves[entry[2]]
    for step = 0, 20 do
      local t = step / 20
      luaunit.assertAlmostEquals(easeOut(t), 1 - easeIn(1 - t), EPSILON, entry[2] .. " mirror")
    end
  end
end

function TestEasing:testCurvesAreMonotonic()
  for _, name in ipairs(BOUNDED) do
    local curve = easing.curves[name]
    local previous = curve(0)
    for step = 1, 100 do
      local value = curve(step / 100)
      luaunit.assertTrue(value >= previous - EPSILON, name .. " went backwards at " .. step)
      previous = value
    end
  end
end

function TestEasing:testOvershootCurveExceedsItsTarget()
  local curve = easing.curves.backOut
  local maximum = 0
  for step = 0, 100 do
    maximum = math.max(maximum, curve(step / 100))
  end
  luaunit.assertTrue(maximum > 1, "backOut must overshoot before settling")
end

function TestEasing:testInputIsClampedToTheUnitRange()
  luaunit.assertAlmostEquals(easing.curves.quadIn(-0.5), 0, EPSILON)
  luaunit.assertAlmostEquals(easing.curves.quadIn(1.5), 1, EPSILON)
end

function TestEasing:testLookupByNameReturnsTheCurve()
  luaunit.assertIs(easing.byName("cubicOut"), easing.curves.cubicOut)
end

function TestEasing:testLookupByUnknownNameFails()
  luaunit.assertErrorMsgContains("unknown easing curve", easing.byName, "noSuchCurve")
end

return { TestEasing = TestEasing }
