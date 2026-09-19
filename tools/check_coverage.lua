-- Fails if the mathematical core is not exercised enough by the tests.
--
-- Run it after producing a coverage report:
--     lua -lluacov tests/run_all.lua && luacov && lua tools/check_coverage.lua
--
-- An optional first argument overrides the target percentage for one run.

require("tools.rockpath").add()

local coverage = require("tools.coverage")

-- Where the coverage tool writes its report, per its own configuration.
local REPORT_PATH = "luacov.report.out"

local function fail(message)
  io.stderr:write(message .. "\n")
  os.exit(1)
end

local target = tonumber(arg and arg[1]) or coverage.DEFAULT_TARGET_PERCENT

-- How to produce the report, repeated in the failure message because that is
-- where someone reads it.
local HOW_TO_PRODUCE = "lua -lluacov tests/run_all.lua && luacov"

local file = io.open(REPORT_PATH, "r")
if not file then
  fail(("no coverage report at '%s'. Produce one first: %s"):format(REPORT_PATH, HOW_TO_PRODUCE))
end

local text = file:read("a")
file:close()

local measured, reason = coverage.parseReport(text)
if not measured then
  fail("cannot read the coverage report: " .. reason)
end

if #measured.files == 0 then
  fail("the coverage report measured no files at all, so it proves nothing")
end

if not coverage.meetsTarget(measured.total, target) then
  local weakest = coverage.weakest(measured)
  fail(
    ("core coverage is %.2f%%, below the %d%% target. Least covered: %s at %.2f%%"):format(
      measured.total,
      target,
      weakest.name,
      weakest.percent
    )
  )
end

print(
  ("core coverage is %.2f%% across %d files, at or above the %d%% target"):format(
    measured.total,
    #measured.files,
    target
  )
)
