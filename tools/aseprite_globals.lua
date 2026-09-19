-- The names the application injects into every script it runs.
--
-- This is one fact with two consumers. The linter needs it so it stops
-- reporting these as undefined; the layer boundary check needs it so it knows
-- what the mathematical core is forbidden to touch. Held in two places it
-- drifts, and it already did once - a name was added to one list and not the
-- other, opening a hole that neither check would have reported.
--
-- Keep it sorted, and add a name here only after confirming the application
-- really does inject it.

return {
  "app",
  "json",
  "BlendMode",
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
}
