-- Linter configuration.
--
-- The application injects its own globals into every script it runs. They are
-- declared read-only here so the linter stops reporting them as undefined
-- while still catching a genuine typo.

std = "lua54"
max_line_length = 100

-- Defined by us, consumed by the application: an extension's entry point is
-- found by name, so these are globals on purpose.
globals = {
  "init",
  "exit",
}

read_globals = {
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
  "MouseButton",
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

exclude_files = {
  ".luarocks/**",
}
