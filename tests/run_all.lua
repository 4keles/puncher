-- Core test runner.
--
-- Runs under a plain Lua interpreter, with no application involved. It
-- discovers every file named `*_test.lua` under `tests/core`, loads it, and
-- hands the collected test tables to the test library.
--
-- Exit status is what continuous integration reads: zero when everything
-- passed, non-zero otherwise.

local TEST_DIRS = { "tests/core", "tests/tools" }
local TEST_SUFFIX = "_test.lua"

-- Project modules are addressed from the repository root, so `core.easing`
-- means the file `core/easing.lua` no matter where the runner was started
-- from.
local function addProjectRoot()
  local invoked = arg and arg[0] or "tests/run_all.lua"
  local root = invoked:match("^(.*)tests[/\\]run_all%.lua$") or "./"
  if root == "" then
    root = "./"
  end

  package.path = table.concat({
    root .. "?.lua",
    root .. "?/init.lua",
    package.path,
  }, ";")

  return root
end

local root = addProjectRoot()
require("tools.rockpath").add()

local lfs = require("lfs")
local luaunit = require("luaunit")

local function collectTestFiles(directory)
  local files = {}
  for entry in lfs.dir(directory) do
    if entry:sub(-#TEST_SUFFIX) == TEST_SUFFIX then
      files[#files + 1] = entry
    end
  end
  table.sort(files)
  return files
end

local discovered = 0

for _, directory in ipairs(TEST_DIRS) do
  local path = root .. directory
  if lfs.attributes(path, "mode") ~= "directory" then
    io.stderr:write("No test directory at " .. path .. "\n")
    os.exit(1)
  end

  for _, file in ipairs(collectTestFiles(path)) do
    local moduleName = directory:gsub("[/\\]", ".") .. "." .. file:sub(1, -#".lua" - 1)
    local module = require(moduleName)
    discovered = discovered + 1

    -- A test file returns its test tables; anything it returns is registered
    -- under its own name so failures point at the file they came from.
    if type(module) == "table" then
      for name, value in pairs(module) do
        _G[name] = value
      end
    end
  end
end

print(("Discovered %d test file(s)"):format(discovered))

os.exit(luaunit.LuaUnit.run("--verbose"))
