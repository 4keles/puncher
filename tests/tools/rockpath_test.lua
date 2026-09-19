local luaunit = require("luaunit")
local rockpath = require("tools.rockpath")

local TestRockPath = {}

function TestRockPath:testTheVersionComesFromTheInterpreterItself()
  luaunit.assertEquals(rockpath.version(), _VERSION:match("(%d+%.%d+)"))
end

function TestRockPath:testTheVersionIsMajorAndMinorOnly()
  luaunit.assertStrMatches(rockpath.version(), "%d+%.%d+")
end

function TestRockPath:testModulePathsSitUnderTheHomeDirectory()
  local lua = rockpath.paths("/somewhere", "5.4")
  luaunit.assertStrContains(lua, "/somewhere/.luarocks/share/lua/5.4/?.lua")
  luaunit.assertStrContains(lua, "/somewhere/.luarocks/share/lua/5.4/?/init.lua")
end

function TestRockPath:testBothCompiledModuleSpellingsAreOffered()
  local _, compiled = rockpath.paths("/somewhere", "5.4")
  luaunit.assertStrContains(compiled, "/somewhere/.luarocks/lib/lua/5.4/?.so")
  luaunit.assertStrContains(compiled, "/somewhere/.luarocks/lib64/lua/5.4/?.so")
end

function TestRockPath:testTheVersionIsSubstitutedRatherThanFixed()
  local lua, compiled = rockpath.paths("/somewhere", "9.9")
  luaunit.assertStrContains(lua, "/share/lua/9.9/")
  luaunit.assertStrContains(compiled, "/lib/lua/9.9/")
end

function TestRockPath:testAddingPutsTheTreeInFrontOfWhatWasThereBefore()
  local before = package.path
  local restore = { path = package.path, cpath = package.cpath }
  rockpath.add()
  luaunit.assertStrContains(package.path, "/.luarocks/share/lua/")
  luaunit.assertStrContains(package.path, before)
  package.path = restore.path
  package.cpath = restore.cpath
end

return TestRockPath
