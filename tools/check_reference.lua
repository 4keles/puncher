-- Fails if the demonstration animation has changed.
--
--     "$ASEPRITE_BIN" --batch --script tools/check_reference.lua
--
-- The reference frames beside it were produced before the engine was rebuilt
-- around parts and a draw list, and they came out of the rebuild identical.
-- That equality is the only thing standing between "the machinery changed" and
-- "the animation changed", so it is kept as a check rather than as a memory.
--
-- A change here is not automatically a fault. It is a change that has to be
-- looked at and then deliberately recorded, by rendering the demonstration and
-- copying its frames over the references in the same commit that caused them.

local root = app.fs.filePath(app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", "")))
package.path = table.concat({
  app.fs.joinPath(root, "?.lua"),
  app.fs.joinPath(root, "?", "init.lua"),
  package.path,
}, ";")

local motion = require("core.motion")
local parts = require("core.parts")
local drawlist = require("core.drawlist")
local rig = require("adapter.rig")
local frames = require("adapter.frames")

local REFERENCE_DIR = app.fs.joinPath(root, "assets", "reference", "demo-dash")
local SAMPLE = app.fs.joinPath(root, "assets", "sample-character.aseprite")

local sprite = app.open(SAMPLE)
if not sprite then
  error("could not open the sample character at " .. SAMPLE)
end

local sourceCel = sprite.cels[1]
local preset = dofile(app.fs.joinPath(root, "presets", "demo_dash.lua"))
local tree = parts.tree(rig.read(sprite, sourceCel))

local drawn = drawlist.fromMotionPath {
  tree = tree,
  part = tree.roots[1],
  layer = "Puncher Dash",
  path = motion.linear(preset),
}
drawlist.validate(drawn, tree)
frames.applyDrawList {
  sprite = sprite,
  cel = sourceCel,
  parts = tree.byName,
  drawList = drawn,
  tagName = "dash",
}

local references = app.fs.listFiles(REFERENCE_DIR)
table.sort(references)

if #references == 0 then
  error("no reference frames in " .. REFERENCE_DIR)
end

if #references ~= #sprite.frames then
  error(
    ("the animation now has %d frames; there are %d reference frames"):format(
      #sprite.frames,
      #references
    )
  )
end

local differing = {}

for index, name in ipairs(references) do
  local reference = Image { fromFile = app.fs.joinPath(REFERENCE_DIR, name) }
  local produced = Image(sprite.spec)
  produced:drawSprite(sprite, index)

  if not produced:isEqual(reference) then
    differing[#differing + 1] = name
  end
end

if #differing > 0 then
  io.stderr:write(("the demonstration animation changed in %d frame(s):\n"):format(#differing))
  for _, name in ipairs(differing) do
    io.stderr:write("  " .. name .. "\n")
  end
  io.stderr:write(
    "\nLook at it. If the change is wanted, render the demonstration and copy\n"
      .. "its frames over the references in the same commit that caused them.\n"
  )
  error("the demonstration animation no longer matches its references")
end

print(("the demonstration animation matches all %d reference frames"):format(#references))
