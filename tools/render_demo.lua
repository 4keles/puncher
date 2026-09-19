-- Renders the demonstration so the motion can be watched.
--
--     "$ASEPRITE_BIN" --batch --script tools/render_demo.lua
--
-- Runs the same path the menu command runs, then writes the result out as an
-- animation and as a single sheet with every frame side by side. Looking at
-- that sheet is how the motion gets checked without depending on a desktop
-- session holding keyboard focus.

local root = app.fs.filePath(app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", "")))
package.path = table.concat({
  app.fs.joinPath(root, "?.lua"),
  app.fs.joinPath(root, "?", "init.lua"),
  package.path,
}, ";")

local motion = require("core.motion")
local frames = require("adapter.frames")

local OUTPUT_DIR = app.fs.joinPath(root, "build")
local SAMPLE = app.fs.joinPath(root, "assets", "sample-character.aseprite")

local sprite = app.open(SAMPLE)
if not sprite then
  error("could not open the sample character at " .. SAMPLE)
end

local preset = dofile(app.fs.joinPath(root, "presets", "demo_dash.lua"))
local path = motion.linear(preset)

local sourceCel = sprite.cels[1]
local result = frames.applyMotion {
  sprite = sprite,
  cel = sourceCel,
  path = path,
  layerName = "Puncher Dash",
  tagName = "dash",
}

-- The sample canvas already has room for the dash. Widen it only if a preset
-- asks for more travel than fits, so the motion is never judged from frames
-- where the character has simply left the picture. What matters is where the
-- drawing ends, not where its cel ends: a cel covering the whole canvas would
-- otherwise make every dash look as if it overflowed.
local drawn = sourceCel.image:shrinkBounds()
local needed = sourceCel.position.x + drawn.x + drawn.width + math.abs(preset.distance)
if needed > sprite.width then
  sprite:crop(0, 0, needed, sprite.height)
end

if not app.fs.isDirectory(OUTPUT_DIR) then
  app.fs.makeDirectory(OUTPUT_DIR)
end

sprite:saveCopyAs(app.fs.joinPath(OUTPUT_DIR, "demo-dash.gif"))
sprite:saveCopyAs(app.fs.joinPath(OUTPUT_DIR, "demo-dash-sheet.png"))

print(("produced %d frames, tagged '%s'"):format(result.lastFrame - result.firstFrame + 1, "dash"))
print("wrote " .. app.fs.joinPath(OUTPUT_DIR, "demo-dash.gif"))
