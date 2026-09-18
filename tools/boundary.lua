-- The layer boundary check.
--
-- The mathematical core is testable outside the application only because it
-- never touches it. That rule is easy to state and easy to break by accident,
-- usually while debugging, so a machine enforces it.
--
-- The check has to be precise or it will be ignored. Every one of these modules
-- has comments that mention the application, and a checker that trips over its
-- own documentation gets switched off within a day. So comments, strings,
-- locals of the same name and fields of the same name are all left alone.

local M = {}

-- The names the application injects. A module in the core layer must not use
-- any of them.
M.FORBIDDEN = {
  "app",
  "json",
  "Brush",
  "Cel",
  "Color",
  "ColorMode",
  "ColorSpace",
  "Dialog",
  "Frame",
  "GraphicsContext",
  "Image",
  "ImageSpec",
  "Layer",
  "Palette",
  "Plugin",
  "Point",
  "Range",
  "Rectangle",
  "Selection",
  "Site",
  "Size",
  "Slice",
  "Sprite",
  "Tag",
  "Tileset",
  "Tilemap",
  "Timer",
  "Version",
  "WebSocket",
  "BlendMode",
}

--- Replace comments and string contents with blanks, keeping every newline so
-- reported line numbers still match the file on disk.
local function blankOutCommentsAndStrings(source)
  local out = {}
  local index = 1
  local length = #source

  local function peek(offset)
    return source:sub(index + offset, index + offset)
  end

  local function longBracketLevel(at)
    if source:sub(at, at) ~= "[" then
      return nil
    end
    local equals = source:match("^=*", at + 1)
    if source:sub(at + 1 + #equals, at + 1 + #equals) == "[" then
      return #equals
    end
    return nil
  end

  local function skipTo(target)
    while index <= length do
      local character = source:sub(index, index)
      out[#out + 1] = (character == "\n") and "\n" or " "
      index = index + 1
      if source:sub(index - #target, index - 1) == target then
        return
      end
    end
  end

  while index <= length do
    local character = source:sub(index, index)

    if character == "-" and peek(1) == "-" then
      local level = longBracketLevel(index + 2)
      out[#out + 1] = "  "
      index = index + 2
      if level then
        skipTo("]" .. string.rep("=", level) .. "]")
      else
        while index <= length and source:sub(index, index) ~= "\n" do
          out[#out + 1] = " "
          index = index + 1
        end
      end
    elseif character == '"' or character == "'" then
      local quote = character
      out[#out + 1] = " "
      index = index + 1
      while index <= length do
        local inner = source:sub(index, index)
        out[#out + 1] = (inner == "\n") and "\n" or " "
        index = index + 1
        if inner == "\\" then
          out[#out + 1] = " "
          index = index + 1
        elseif inner == quote then
          break
        end
      end
    else
      local level = longBracketLevel(index)
      if level then
        out[#out + 1] = " "
        index = index + 2 + level
        skipTo("]" .. string.rep("=", level) .. "]")
      else
        out[#out + 1] = character
        index = index + 1
      end
    end
  end

  return table.concat(out)
end

--- Names the file declares itself, which may legitimately shadow an
-- application name.
local function declaredNames(source)
  local names = {}

  for declaration in source:gmatch("local%s+([%a_][%w_,%s]*)") do
    for name in declaration:gmatch("[%a_][%w_]*") do
      names[name] = true
    end
  end

  for parameters in source:gmatch("function[^\n(]*%(([^)]*)%)") do
    for name in parameters:gmatch("[%a_][%w_]*") do
      names[name] = true
    end
  end

  return names
end

--- Find application names used by a piece of source.
-- @param file string  path reported with each finding
-- @param source string  the file's contents
-- @return table  list of { file = string, line = number, name = string }
function M.scanSource(file, source)
  local cleaned = blankOutCommentsAndStrings(source)
  local declared = declaredNames(cleaned)
  local findings = {}

  local lineNumber = 0
  for line in (cleaned .. "\n"):gmatch("([^\n]*)\n") do
    lineNumber = lineNumber + 1
    for _, name in ipairs(M.FORBIDDEN) do
      if not declared[name] then
        local pattern = "%f[%w_]" .. name .. "%f[^%w_]"
        local at = line:find(pattern)
        while at do
          local before = line:sub(1, at - 1):match("([%.:])%s*$")
          if not before then
            findings[#findings + 1] = { file = file, line = lineNumber, name = name }
            break
          end
          at = line:find(pattern, at + 1)
        end
      end
    end
  end

  return findings
end

--- Scan every Lua file in a directory.
function M.scanDirectory(directory)
  local lfs = require("lfs")
  local findings = {}

  for entry in lfs.dir(directory) do
    if entry:sub(-4) == ".lua" then
      local path = directory .. "/" .. entry
      local file = io.open(path, "r")
      if file then
        local contents = file:read("a")
        file:close()
        for _, finding in ipairs(M.scanSource(path, contents)) do
          findings[#findings + 1] = finding
        end
      end
    end
  end

  return findings
end

return M
