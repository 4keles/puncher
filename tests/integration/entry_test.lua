-- Runs inside the application. Proves the extension's entry point works.
--
-- This is the one file nothing else here touches. Every other check loads the
-- modules directly, which is not how the artist gets them: the application
-- calls init with a plugin object, and that function finds the modules, loads
-- the command and registers the menu. If it raised, the application would
-- carry on without the extension and every other check here would still pass.
--
-- What this cannot do is see the menu. Extensions are not loaded at all in a
-- batch run, so init is called here with a stand-in for the plugin object
-- rather than by the application. That means the registration arguments are
-- recorded rather than acted on, and a menu that the application would reject
-- would pass here. What it does prove is everything up to that point: the
-- entry point loads, it puts its own modules within reach, the command it
-- names is really there, and it asks for a menu group and commands that carry
-- the identifiers and titles the artist is meant to see.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local bootstrap = dofile(app.fs.joinPath(here, "support.lua"))
local projectRoot = bootstrap.projectRoot(debug.getinfo(1, "S").source)
bootstrap.addProjectToPath(projectRoot)

local M = {}

--- A stand-in for what the application hands the entry point.
local function standInPlugin(root)
  return {
    path = root,
    groups = {},
    commands = {},
    newMenuGroup = function(self, spec)
      self.groups[#self.groups + 1] = spec
    end,
    newCommand = function(self, spec)
      self.commands[#self.commands + 1] = spec
    end,
  }
end

function M.run(support)
  local pathBefore = package.path

  -- The entry point defines a global, which is how the application finds it.
  local chunk = loadfile(app.fs.joinPath(projectRoot, "main.lua"))
  support.assertNotNil(chunk, "the entry point does not load")
  chunk()
  support.assertEquals(type(init), "function", "the entry point defines no init")

  local plugin = standInPlugin(projectRoot)
  local ok, err = pcall(init, plugin)
  support.assertTrue(ok, "the entry point raised: " .. tostring(err))

  -- It has to put its own modules within reach, or a command asking for one
  -- finds nothing.
  support.assertTrue(
    package.path ~= pathBefore,
    "the entry point did not add its own modules to the search path"
  )

  -- One menu group, so uninstalling removes one thing.
  support.assertEquals(#plugin.groups, 1, "the extension did not ask for exactly one menu group")
  support.assertEquals(plugin.groups[1].title, "Puncher", "the menu group is not named")

  -- Every command must carry an identifier, a title and the group, and sit in
  -- that group rather than loose in the application's menus.
  support.assertTrue(#plugin.commands > 0, "the extension registered no commands")
  for _, command in ipairs(plugin.commands) do
    support.assertTrue(
      type(command.id) == "string" and #command.id > 0,
      "a command has no identifier"
    )
    support.assertTrue(
      type(command.title) == "string" and #command.title > 0,
      "command '" .. tostring(command.id) .. "' has no title"
    )
    support.assertEquals(
      command.group,
      plugin.groups[1].id,
      "command '" .. tostring(command.id) .. "' is not in the extension's own group"
    )
    support.assertEquals(
      type(command.onclick),
      "function",
      "command '" .. tostring(command.id) .. "' does nothing when chosen"
    )
  end

  package.path = pathBefore
end

return M
