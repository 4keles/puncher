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

-- The character starts in the middle of a small canvas, so widen it enough
-- that the whole dash stays visible instead of running off the edge.
local travel = math.abs(preset.distance)
sprite:crop(0, 0, sprite.width + travel, sprite.height)

if not app.fs.isDirectory(OUTPUT_DIR) then
  app.fs.makeDirectory(OUTPUT_DIR)
end

sprite:saveCopyAs(app.fs.joinPath(OUTPUT_DIR, "demo-dash.gif"))
sprite:saveCopyAs(app.fs.joinPath(OUTPUT_DIR, "demo-dash-sheet.png"))

print(("produced %d frames, tagged '%s'"):format(result.lastFrame - result.firstFrame + 1, "dash"))
print("wrote " .. app.fs.joinPath(OUTPUT_DIR, "demo-dash.gif"))
