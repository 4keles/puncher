-- The layer boundary check.
--
-- The mathematical core is testable outside the application only because it
-- never touches it. That rule is easy to state and easy to break by accident,
-- usually while debugging, so a machine enforces it.
--
-- The check has to be precise or it will be ignored. Every one of these modules
-- has comments that mention the application, and a checker that trips over its
-- own documentation gets switched off within a day. So comments, strings and
-- fields of the same name are all left alone.
--
-- Shadowing is handled by scope rather than by file. An earlier version
-- collected every name the file declared anywhere and excused all of them
-- everywhere, which meant one function naming a parameter after an application
-- global silently pardoned a genuine breach in a different function. A check
-- that can be switched off from a distance by an unrelated line is worse than
-- no check, because it still reports success.

local M = {}

-- One list, two consumers. The linter needs the same names, so neither holds
-- its own copy.
M.FORBIDDEN = dofile("tools/aseprite_globals.lua")

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

-- Keywords that open a block, and the ones that close it. A loop's `do` is
-- what opens it, so `for` and `while` are deliberately absent: counting them
-- as well would open two scopes where the language opens one.
local BLOCK_OPENERS = {
  ["function"] = true,
  ["if"] = true,
  ["do"] = true,
  ["repeat"] = true,
}

local BLOCK_CLOSERS = {
  ["end"] = true,
  ["until"] = true,
}

--- Find application names used by a piece of source.
-- Walks the file in order, carrying a stack of open scopes. A name counts as
-- the file's own only while a scope that declared it is still open, so a
-- borrowed name protects the function that borrowed it and nothing else.
-- @param file string  path reported with each finding
-- @param source string  the file's contents
-- @return table  list of { file = string, line = number, name = string }
function M.scanSource(file, source)
  local cleaned = blankOutCommentsAndStrings(source)
  local forbidden = {}
  for _, name in ipairs(M.FORBIDDEN) do
    forbidden[name] = true
  end

  local findings = {}
  local scopes = { {} }
  local line = 1
  local index = 1
  local length = #cleaned

  local function declare(name)
    scopes[#scopes][name] = true
  end

  local function isVisible(name)
    for depth = #scopes, 1, -1 do
      if scopes[depth][name] then
        return true
      end
    end
    return false
  end

  -- Everything a `local` statement brings into the current scope. The names
  -- run from the keyword to the first assignment, or to the end of the line
  -- when there is none. `local function name` declares just the one name; its
  -- parameters belong to the scope the function itself opens.
  local function declareLocals(after)
    local statement = cleaned:match("^([^\n]*)", after)
    local assignment = statement:find("=", 1, true)
    if assignment then
      statement = statement:sub(1, assignment - 1)
    end

    local firstWord = statement:match("^%s*([%a_][%w_]*)")
    if firstWord == "function" then
      local name = statement:match("^%s*function%s+([%a_][%w_]*)")
      if name then
        declare(name)
      end
      return
    end

    for name in statement:gmatch("[%a_][%w_]*") do
      declare(name)
    end
  end

  -- A function's parameters belong to the scope it just opened. The list is
  -- read without consuming it, so the walk still visits those names normally
  -- and finds them already declared.
  local function declareParameters(after)
    local parameters = cleaned:match("^[%s%w_%.:]*%(([^)]*)%)", after)
    if not parameters then
      return
    end
    for name in parameters:gmatch("[%a_][%w_]*") do
      declare(name)
    end
  end

  while index <= length do
    local character = cleaned:sub(index, index)

    if character == "\n" then
      line = line + 1
      index = index + 1
    elseif character:match("[%a_]") then
      local word = cleaned:match("^[%a_][%w_]*", index)
      local after = index + #word

      if word == "local" then
        declareLocals(after)
      elseif word == "function" then
        scopes[#scopes + 1] = {}
        declareParameters(after)
      elseif BLOCK_OPENERS[word] then
        scopes[#scopes + 1] = {}
      elseif BLOCK_CLOSERS[word] then
        if #scopes > 1 then
          scopes[#scopes] = nil
        end
      elseif forbidden[word] and not isVisible(word) then
        local access = cleaned:sub(1, index - 1):match("([%.:])%s*$")
        if not access then
          findings[#findings + 1] = { file = file, line = line, name = word }
        end
      end

      index = after
    else
      index = index + 1
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
