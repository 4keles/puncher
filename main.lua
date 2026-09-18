-- Puncher extension entry point.
--
-- Everything the extension adds to the application lives under one menu group,
-- so the artist finds it in one place and uninstalling removes one thing.
--
-- This file deliberately contains no logic beyond registration. Commands stay
-- in their own modules; mathematics never comes near this layer.

local MENU_GROUP = "puncher_menu"

function init(plugin)
  plugin:newMenuGroup{
    id = MENU_GROUP,
    title = "Puncher",
    group = "file_scripts",
  }

  plugin:newCommand{
    id = "puncher_about",
    title = "About Puncher",
    group = MENU_GROUP,
    onclick = function()
      app.alert{
        title = "Puncher",
        text = {
          "Procedural action animation for pixel art characters.",
          "Tools appear under File > Scripts > Puncher.",
        },
      }
    end,
  }
end
