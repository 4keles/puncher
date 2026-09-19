-- Reading the coverage report.
--
-- The coverage tool prints a report and always exits zero, so on its own it
-- measures without deciding anything. This module turns that report into a
-- number and a verdict, which is what an automated check needs: a run whose
-- core coverage has quietly fallen must fail, not scroll past.
--
-- It refuses a report it cannot understand instead of treating it as a pass.
-- A missing summary usually means the test run died before the report was
-- written, and calling that full coverage would be the worst possible answer.

local M = {}

-- The share of the mathematical core that must be exercised by the tests.
-- Stated in the process document; override it from the command line when a
-- one-off run needs a different bar.
M.DEFAULT_TARGET_PERCENT = 80

-- The report's summary table: a name, hit and missed line counts, a percentage.
local ROW_PATTERN = "^(%S+)%s+(%d+)%s+(%d+)%s+([%d%.]+)%%"

-- The line the coverage tool writes for the whole measured set.
local TOTAL_ROW_NAME = "Total"

-- The heading that opens the summary table.
local SUMMARY_HEADING = "Summary"

--- Turn a coverage report into per-file figures and an overall percentage.
-- @tparam string text the full report as the coverage tool wrote it
-- @treturn ?table `{files = {{name, hits, missed, percent}, ...}, total = number}`
-- @treturn ?string why the report could not be read, when it could not
function M.parseReport(text)
  if type(text) ~= "string" or text == "" then
    return nil, "the coverage report is empty; the test run probably never finished"
  end

  local summaryStart = text:find(SUMMARY_HEADING, 1, true)
  if not summaryStart then
    return nil, "the coverage report has no summary section"
  end

  local files = {}
  local total = nil

  for line in text:sub(summaryStart):gmatch("[^\n]+") do
    local name, hits, missed, percent = line:match(ROW_PATTERN)
    if name then
      local row = {
        name = name,
        hits = tonumber(hits),
        missed = tonumber(missed),
        percent = tonumber(percent),
      }
      if name == TOTAL_ROW_NAME then
        total = row.percent
      else
        files[#files + 1] = row
      end
    end
  end

  if not total then
    return nil, "the coverage report's summary has no total line"
  end

  return { files = files, total = total }
end

--- The measured file with the least coverage, so a failure can name a place.
-- @tparam table measured the result of `parseReport`
-- @treturn ?table the weakest row, or nil when nothing was measured
function M.weakest(measured)
  local worst = nil
  for _, row in ipairs(measured.files) do
    if not worst or row.percent < worst.percent then
      worst = row
    end
  end
  return worst
end

--- Whether a measured percentage clears the target.
-- @tparam number measured the percentage the report stated
-- @tparam number target the percentage that must be reached
-- @treturn boolean
function M.meetsTarget(measured, target)
  return measured >= target
end

return M
