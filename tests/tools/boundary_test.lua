local luaunit = require("luaunit")
local boundary = require("tools.boundary")

local TestBoundary = {}

function TestBoundary:testCleanSourceReportsNothing()
  local source = [[
local M = {}
function M.double(value)
  return value * 2
end
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/clean.lua", source), 0)
end

function TestBoundary:testAnApplicationGlobalIsReported()
  local source = [[
local M = {}
function M.draw()
  app.alert("nope")
end
return M
]]
  local findings = boundary.scanSource("core/dirty.lua", source)
  luaunit.assertEquals(#findings, 1)
  luaunit.assertEquals(findings[1].line, 3)
  luaunit.assertEquals(findings[1].name, "app")
end

function TestBoundary:testEveryForbiddenNameIsCaught()
  for _, name in ipairs { "app", "Image", "Sprite", "Dialog", "json", "Color" } do
    local findings = boundary.scanSource("core/x.lua", "local value = " .. name .. ".thing")
    luaunit.assertEquals(#findings, 1, name .. " went unnoticed")
  end
end

function TestBoundary:testProseInCommentsIsNotAViolation()
  -- The word "application" contains "app", and every one of these modules has
  -- comments talking about the application. A checker that trips over its own
  -- documentation would be turned off within a day.
  local source = [[
-- This module never touches the application, not even Image or Sprite.
local M = {}
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/commented.lua", source), 0)
end

function TestBoundary:testTextInsideStringsIsNotAViolation()
  local source = [[
local M = {}
M.message = "run this from the app menu"
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/message.lua", source), 0)
end

function TestBoundary:testALocalOfTheSameNameIsNotAViolation()
  local source = [[
local M = {}
function M.run(app)
  return app
end
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/shadow.lua", source), 0)
end

function TestBoundary:testAFieldNamedLikeAGlobalIsNotAViolation()
  local source = [[
local M = {}
function M.read(config)
  return config.app
end
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/field.lua", source), 0)
end

function TestBoundary:testTheRealCoreDirectoryIsClean()
  local findings = boundary.scanDirectory("core")
  local names = {}
  for _, finding in ipairs(findings) do
    names[#names + 1] = finding.file .. ":" .. finding.line .. " " .. finding.name
  end
  luaunit.assertEquals(
    #findings,
    0,
    "core layer touches the application: " .. table.concat(names, ", ")
  )
end

-- Scope. The check is only worth having if a name borrowed in one place
-- cannot excuse a genuine breach somewhere else in the same file.

function TestBoundary:testAShadowInOneFunctionDoesNotHideAViolationInAnother()
  local source = [[
local M = {}

function M.shadow(app)
  return app.thing
end

function M.violation()
  return app.transaction("oops", function() end)
end

return M
]]
  local findings = boundary.scanSource("core/mixed.lua", source)
  luaunit.assertEquals(#findings, 1)
  luaunit.assertEquals(findings[1].name, "app")
  luaunit.assertEquals(findings[1].line, 8)
end

function TestBoundary:testAShadowStillProtectsItsOwnFunction()
  local source = [[
local M = {}
function M.borrow(app)
  return app.thing
end
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/borrow.lua", source), 0)
end

function TestBoundary:testAFileLevelLocalShadowsEverythingAfterIt()
  local source = [[
local Image = {}
local M = {}
function M.one()
  return Image.width
end
function M.two()
  return Image.height
end
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/filelevel.lua", source), 0)
end

function TestBoundary:testANameUsedBeforeItIsDeclaredIsStillTheApplications()
  local source = [[
local function early()
  return app.version
end
local app = {}
return app
]]
  local findings = boundary.scanSource("core/ordering.lua", source)
  luaunit.assertEquals(#findings, 1)
  luaunit.assertEquals(findings[1].line, 2)
end

function TestBoundary:testAShadowInsideABlockDoesNotEscapeIt()
  local source = [[
local M = {}
function M.one()
  if true then
    local Color = 1
    return Color
  end
  return 0
end
function M.two()
  return Color.rgb
end
return M
]]
  local findings = boundary.scanSource("core/block.lua", source)
  luaunit.assertEquals(#findings, 1)
  luaunit.assertEquals(findings[1].name, "Color")
  luaunit.assertEquals(findings[1].line, 10)
end

function TestBoundary:testLoopAndRepeatBlocksBalanceSoScopesDoNotLeak()
  local source = [[
local M = {}
function M.one()
  for index = 1, 3 do
    local Sprite = index
    print(Sprite)
  end
  while true do
    local Layer = 1
    print(Layer)
    break
  end
  repeat
    local Tag = 1
    print(Tag)
  until true
end
function M.two()
  return Sprite, Layer, Tag
end
return M
]]
  local findings = boundary.scanSource("core/blocks.lua", source)
  luaunit.assertEquals(#findings, 3)
  for _, finding in ipairs(findings) do
    luaunit.assertEquals(finding.line, 18)
  end
end

function TestBoundary:testSeveralNamesOnOneLocalLineAreAllDeclared()
  local source = [[
local M = {}
function M.one()
  local Point, Size = 1, 2
  return Point + Size
end
return M
]]
  luaunit.assertEquals(#boundary.scanSource("core/multi.lua", source), 0)
end

-- The list of names the application injects is one fact. The linter needs it
-- too, and a copy of a fact is a copy that drifts.

function TestBoundary:testTheForbiddenListIsTheOneTheLinterUses()
  -- Read the linter's configuration the way the linter does: run it, with a
  -- fresh table to collect what it sets, still able to reach the standard
  -- library it uses to load the shared list.
  -- The linter hands its configuration a table for per-path overrides; the
  -- file expects to find it already there.
  local config = setmetatable({ files = {} }, { __index = _G })
  local chunk = assert(loadfile(".luacheckrc", "t", config))
  chunk()

  local declared = {}
  for _, name in ipairs(config.read_globals or {}) do
    declared[name] = true
  end

  local forbidden = {}
  for _, name in ipairs(boundary.FORBIDDEN) do
    forbidden[name] = true
  end

  for name in pairs(declared) do
    luaunit.assertTrue(forbidden[name], "the linter knows '" .. name .. "' but the check does not")
  end
  for name in pairs(forbidden) do
    luaunit.assertTrue(declared[name], "the check knows '" .. name .. "' but the linter does not")
  end
end

return { TestBoundary = TestBoundary }
