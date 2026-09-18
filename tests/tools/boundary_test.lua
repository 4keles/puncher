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

return { TestBoundary = TestBoundary }
