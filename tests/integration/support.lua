-- Assertions for tests that run inside the application.
--
-- The unit test library is not used here: it lives in the package manager's
-- tree, which the application's interpreter does not search, and dragging it
-- in would trade a dozen lines for a dependency. A failure raises an error,
-- which the application reports and turns into a non-zero exit status - the
-- signal the automated checks read.

local M = {}

M.checks = 0

local function fail(message)
  error(message, 3)
end

function M.assertTrue(value, message)
  M.checks = M.checks + 1
  if not value then
    fail(message or "expected a true value")
  end
end

function M.assertEquals(actual, expected, message)
  M.checks = M.checks + 1
  if actual ~= expected then
    fail(
      (message or "values differ")
        .. ": expected "
        .. tostring(expected)
        .. ", got "
        .. tostring(actual)
    )
  end
end

function M.assertNotNil(value, message)
  M.checks = M.checks + 1
  if value == nil then
    fail(message or "expected a value, got nothing")
  end
end

--- Find the repository root from the path of the running script.
function M.projectRoot(scriptSource)
  local path = scriptSource:gsub("^@", "")
  local root = path:match("^(.*)tests[/\\]integration[/\\]")
  return root or "./"
end

--- Make project modules loadable from inside the application.
function M.addProjectToPath(root)
  package.path = table.concat({
    root .. "?.lua",
    root .. "?/init.lua",
    package.path,
  }, ";")
end

return M
