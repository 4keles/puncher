-- Puncher extension entry point.
--
-- Everything the extension adds to the application lives under one menu group,
-- so the artist finds it in one place and uninstalling removes one thing.
--
-- This file deliberately contains no logic beyond registration. Commands stay
-- in their own modules; mathematics never comes near this layer.

local MENU_GROUP = "puncher_menu"

--- Make the extension's own modules loadable.
-- The application does not add an extension's directory to the search path, so
-- a command asking for a core module would otherwise fail to find it.
local function addExtensionToPath(root)
  package.path = table.concat({
    app.fs.joinPath(root, "?.lua"),
    app.fs.joinPath(root, "?", "init.lua"),
    package.path,
  }, ";")
end

function init(plugin)
  addExtensionToPath(plugin.path)

  local demoMotion = dofile(app.fs.joinPath(plugin.path, "commands", "demo_motion.lua"))
  demoMotion.root = plugin.path

  plugin:newMenuGroup {
    id = MENU_GROUP,
    title = "Puncher",
    group = "file_scripts",
  }

  plugin:newCommand {
    id = "puncher_demo_dash",
    title = "Demo Dash",
    group = MENU_GROUP,
    onclick = function()
      demoMotion.run()
    end,
  }

  plugin:newCommand {
    id = "puncher_about",
    title = "About Puncher",
    group = MENU_GROUP,
    onclick = function()
      app.alert {
        title = "Puncher",
        text = {
          "Procedural action animation for pixel art characters.",
          "Tools appear under File > Puncher.",
        },
      }
    end,
  }
end
