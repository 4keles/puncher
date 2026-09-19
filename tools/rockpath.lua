-- Finding the development packages.
--
-- The package manager installs into a tree under the user's home directory
-- that a non-interactive shell does not search, so a command run straight from
-- a terminal or from an automated check would otherwise fail to find the test
-- library. Every entry point needs the same few lines, which is exactly why
-- they live here once instead of being copied into each one.
--
-- The interpreter version is read from the interpreter rather than written
-- down. A copy that says 5.4 while running under something else silently
-- searches the wrong directory and reports a missing package.

local M = {}

-- Where the package manager installs when asked for a user-local tree.
M.TREE = "/.luarocks"

--- The interpreter's own version, as the package tree spells it.
-- @treturn string for example "5.4"
function M.version()
  return (_VERSION:match("(%d+%.%d+)"))
end

--- The search paths for a given home directory and interpreter version.
-- @tparam string home the user's home directory
-- @tparam string version the interpreter version, as `version` returns it
-- @treturn string entries for Lua modules
-- @treturn string entries for compiled modules
function M.paths(home, version)
  local tree = home .. M.TREE
  local lua = table.concat({
    ("%s/share/lua/%s/?.lua"):format(tree, version),
    ("%s/share/lua/%s/?/init.lua"):format(tree, version),
  }, ";")
  -- Distributions disagree on where 64-bit compiled modules land, so both
  -- spellings are offered rather than guessing one.
  local compiled = table.concat({
    ("%s/lib/lua/%s/?.so"):format(tree, version),
    ("%s/lib64/lua/%s/?.so"):format(tree, version),
  }, ";")
  return lua, compiled
end

--- Put the user-local package tree in front of the search paths.
-- Does nothing when there is no home directory to look in, which is the case
-- in some automated environments where the packages are installed system wide
-- and already findable.
function M.add()
  local home = os.getenv("HOME")
  if not home then
    return false
  end

  local lua, compiled = M.paths(home, M.version())
  package.path = lua .. ";" .. package.path
  package.cpath = compiled .. ";" .. package.cpath
  return true
end

return M
