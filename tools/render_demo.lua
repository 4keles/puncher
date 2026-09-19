-- Renders the demonstration so the motion can be watched.
--
--     "$ASEPRITE_BIN" --batch --script tools/render_demo.lua
--
-- Runs the same path the menu command runs, on both bundled samples, and
-- writes each result out as an animation and as numbered frames. Looking at
-- those frames is how the motion gets checked without depending on a desktop
-- session holding keyboard focus.
--
-- Both samples go through one code path on purpose. The character with its
-- parts marked gets an arm thrown out ahead of it; the one with nothing marked
-- gets the plain dash it always got. Nothing chooses between them except what
-- the document itself declares.

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

local OUTPUT_DIR = app.fs.joinPath(root, "build")

local SAMPLES = {
  { name = "demo-dash", file = "sample-character.aseprite" },
  { name = "demo-swing", file = "sample-rigged.aseprite" },
}

local preset = dofile(app.fs.joinPath(root, "presets", "demo_dash.lua"))
local path = motion.linear(preset)

if not app.fs.isDirectory(OUTPUT_DIR) then
  app.fs.makeDirectory(OUTPUT_DIR)
end

for _, sample in ipairs(SAMPLES) do
  local file = app.fs.joinPath(root, "assets", sample.file)
  local sprite = app.open(file)
  if not sprite then
    error("could not open " .. file)
  end

  local sourceCel = sprite.cels[1]
  local list, source = rig.read(sprite, sourceCel)
  local tree = parts.tree(list)

  local instructions = drawlist.fromMotionPath {
    tree = tree,
    part = tree.roots[1],
    layer = "Puncher Dash",
    swing = preset.swing,
    path = path,
  }
  drawlist.validate(instructions, tree)

  local result = frames.applyDrawList {
    sprite = sprite,
    cel = sourceCel,
    parts = tree.byName,
    drawList = instructions,
    tagName = "dash",
  }

  -- Widen only if the motion would genuinely run off, measuring where the
  -- drawing ends rather than where its cel ends: a cel covering the whole
  -- canvas would otherwise make every dash look as if it overflowed.
  local drawn = sourceCel.image:shrinkBounds()
  local needed = sourceCel.position.x + drawn.x + drawn.width + math.abs(preset.distance)
  if needed > sprite.width then
    sprite:crop(0, 0, needed, sprite.height)
  end

  sprite:saveCopyAs(app.fs.joinPath(OUTPUT_DIR, sample.name .. ".gif"))
  sprite:saveCopyAs(app.fs.joinPath(OUTPUT_DIR, sample.name .. "-sheet.png"))

  print(
    ("%s: %d frames from %d part(s), read from the %s"):format(
      sample.name,
      result.lastFrame - result.firstFrame + 1,
      #tree.order,
      source
    )
  )
  sprite:close()
end
