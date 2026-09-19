local luaunit = require("luaunit")
local coverage = require("tools.coverage")

local TestCoverage = {}

-- A report shaped exactly like the one the coverage tool writes, kept short.
local function report(totalPercent, filePercent)
  return table.concat({
    "    1 return M",
    "",
    "==============================================================================",
    "Summary",
    "==============================================================================",
    "",
    "File               Hits Missed Coverage",
    "---------------------------------------",
    ("core/arc.lua       20   0      %s%%"):format(filePercent or totalPercent),
    "core/easing.lua    57   0      100.00%",
    "---------------------------------------",
    ("Total              247  0      %s%%"):format(totalPercent),
    "",
  }, "\n")
end

function TestCoverage:testTheTotalIsRead()
  local measured = coverage.parseReport(report("93.25"))
  luaunit.assertNotNil(measured)
  luaunit.assertAlmostEquals(measured.total, 93.25, 0.001)
end

function TestCoverage:testEveryMeasuredFileIsListed()
  local measured = coverage.parseReport(report("100.00"))
  luaunit.assertEquals(#measured.files, 2)
  luaunit.assertEquals(measured.files[1].name, "core/arc.lua")
  luaunit.assertAlmostEquals(measured.files[1].percent, 100.0, 0.001)
end

function TestCoverage:testTheWeakestFileIsIdentified()
  local measured = coverage.parseReport(report("80.00", "61.50"))
  local weakest = coverage.weakest(measured)
  luaunit.assertEquals(weakest.name, "core/arc.lua")
  luaunit.assertAlmostEquals(weakest.percent, 61.5, 0.001)
end

function TestCoverage:testAReportWithNoSummaryIsRefused()
  local measured, reason = coverage.parseReport("    1 return M\n")
  luaunit.assertNil(measured)
  luaunit.assertStrContains(reason, "summary")
end

function TestCoverage:testASummaryWithNoTotalIsRefused()
  local text = table.concat({
    "Summary",
    "File               Hits Missed Coverage",
    "---------------------------------------",
    "core/arc.lua       20   0      100.00%",
    "",
  }, "\n")
  local measured, reason = coverage.parseReport(text)
  luaunit.assertNil(measured)
  luaunit.assertStrContains(reason, "total")
end

function TestCoverage:testAnEmptyReportIsRefusedRatherThanCountedAsPassing()
  local measured, reason = coverage.parseReport("")
  luaunit.assertNil(measured)
  luaunit.assertNotNil(reason)
end

function TestCoverage:testCoverageAtTheTargetPasses()
  luaunit.assertTrue(coverage.meetsTarget(80.0, 80))
end

function TestCoverage:testCoverageBelowTheTargetFails()
  luaunit.assertFalse(coverage.meetsTarget(79.99, 80))
end

function TestCoverage:testTheDefaultTargetIsTheOneTheProcessDocumentStates()
  luaunit.assertEquals(coverage.DEFAULT_TARGET_PERCENT, 80)
end

return TestCoverage
