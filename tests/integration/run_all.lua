-- Integration test runner. Executed by the application in batch mode:
--     "$ASEPRITE_BIN" --batch --script tests/integration/run_all.lua
--
-- These tests are the only proof that the extension works where it actually
-- runs. A failure raises an error, which the application turns into a non-zero
-- exit status.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local support = dofile(app.fs.joinPath(here, "support.lua"))

local SUFFIX = "_test.lua"

local files = {}
for _, entry in ipairs(app.fs.listFiles(here)) do
  if entry:sub(-#SUFFIX) == SUFFIX then
    files[#files + 1] = entry
  end
end
table.sort(files)

if #files == 0 then
  error("no integration tests found in " .. here)
end

local failures = {}

for _, file in ipairs(files) do
  local module = dofile(app.fs.joinPath(here, file))
  -- The runner owns the one support instance, so the check count it reports is
  -- the number of checks that actually ran rather than a per-file copy that
  -- always reads zero.
  local ok, err = pcall(module.run, support)
  if ok then
    print(("  %-28s ok"):format(file))
  else
    print(("  %-28s FAILED"):format(file))
    failures[#failures + 1] = file .. ": " .. tostring(err)
  end
end

print(("%d file(s), %d checks, %d failure(s)"):format(#files, support.checks, #failures))

if #failures > 0 then
  for _, failure in ipairs(failures) do
    print("  " .. failure)
  end
  error("integration tests failed")
end
