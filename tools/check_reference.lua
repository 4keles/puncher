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

local REFERENCE_ROOT = app.fs.joinPath(root, "assets", "reference")

-- The same two samples the renderer produces, checked the same way. One has
-- its parts marked and one does not, which is the pair that proves a single
-- code path serves both.
local SAMPLES = {
  { name = "demo-dash", file = "sample-character.aseprite" },
  { name = "demo-swing", file = "sample-rigged.aseprite" },
}

local preset = dofile(app.fs.joinPath(root, "presets", "demo_dash.lua"))
local path = motion.linear(preset)

local complaints = {}

for _, sample in ipairs(SAMPLES) do
  local file = app.fs.joinPath(root, "assets", sample.file)
  local sprite = app.open(file)
  if not sprite then
    error("could not open " .. file)
  end

  local sourceCel = sprite.cels[1]
  local tree = parts.tree(rig.read(sprite, sourceCel))

  local instructions = drawlist.fromMotionPath {
    tree = tree,
    part = tree.roots[1],
    layer = "Puncher Dash",
    swing = preset.swing,
    path = path,
  }
  drawlist.validate(instructions, tree)
  frames.applyDrawList {
    sprite = sprite,
    cel = sourceCel,
    parts = tree.byName,
    drawList = instructions,
    tagName = "dash",
  }

  local directory = app.fs.joinPath(REFERENCE_ROOT, sample.name)
  local references = app.fs.listFiles(directory)
  table.sort(references)

  if #references == 0 then
    error("no reference frames in " .. directory)
  end

  if #references ~= #sprite.frames then
    complaints[#complaints + 1] = ("%s now has %d frames; there are %d reference frames"):format(
      sample.name,
      #sprite.frames,
      #references
    )
  else
    local differing = {}
    for index, name in ipairs(references) do
      local reference = Image { fromFile = app.fs.joinPath(directory, name) }
      local produced = Image(sprite.spec)
      produced:drawSprite(sprite, index)
      if not produced:isEqual(reference) then
        differing[#differing + 1] = name
      end
    end

    if #differing > 0 then
      complaints[#complaints + 1] = ("%s changed in %d frame(s): %s"):format(
        sample.name,
        #differing,
        table.concat(differing, ", ")
      )
    else
      print(("%s matches all %d reference frames"):format(sample.name, #references))
    end
  end

  sprite:close()
end

if #complaints > 0 then
  for _, complaint in ipairs(complaints) do
    io.stderr:write("  " .. complaint .. "\n")
  end
  io.stderr:write(
    "\nLook at it. If the change is wanted, render the demonstrations and copy\n"
      .. "their frames over the references in the same commit that caused them.\n"
  )
  error("a demonstration animation no longer matches its references")
end
