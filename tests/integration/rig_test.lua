-- Runs inside the application. Proves a rig written into a document comes back
-- out of it, including across a save, which the documentation does not promise.

local here = app.fs.filePath(debug.getinfo(1, "S").source:gsub("^@", ""))
local bootstrap = dofile(app.fs.joinPath(here, "support.lua"))
bootstrap.addProjectToPath(bootstrap.projectRoot(debug.getinfo(1, "S").source))

local rig = require("adapter.rig")
local parts = require("core.parts")

local M = {}

local function newFigure()
  local sprite = Sprite(24, 24)
  local image = sprite.cels[1].image
  local colour = Color { r = 200, g = 90, b = 90, a = 255 }
  for y = 4, 19 do
    for x = 8, 15 do
      image:drawPixel(x, y, colour)
    end
  end
  return sprite
end

function M.run(support)
  -- A document nobody has marked up still yields a rig.
  local plain = newFigure()
  local list, source = rig.read(plain)
  support.assertEquals(source, "whole drawing")
  support.assertEquals(#list, 1)
  support.assertEquals(list[1].name, "body")
  support.assertEquals(list[1].rect.width, 8, "the whole-drawing part hugs the drawing")
  support.assertEquals(list[1].rect.height, 16, "the whole-drawing part hugs the drawing")
  plain:close()

  -- A document with parts marked yields those instead.
  local sprite = newFigure()
  rig.mark(sprite, {
    name = "torso",
    role = "torso",
    rect = { x = 8, y = 10, width = 8, height = 10 },
    pivot = { x = 4, y = 9 },
  })
  rig.mark(sprite, {
    name = "head",
    role = "head",
    parent = "torso",
    rect = { x = 8, y = 4, width = 8, height = 6 },
    pivot = { x = 4, y = 5 },
  })

  local marked, markedSource = rig.read(sprite)
  support.assertEquals(markedSource, "slices")
  support.assertEquals(#marked, 2)

  local tree = parts.tree(marked)
  support.assertEquals(#tree.roots, 1)
  support.assertEquals(tree.roots[1], "torso")
  support.assertEquals(tree.childrenOf["torso"][1], "head")

  -- The part of this that no document promised: that it survives a save.
  local path = app.fs.joinPath(app.fs.tempPath, "puncher-rig-test.aseprite")
  sprite:saveAs(path)
  sprite:close()

  local reopened = app.open(path)
  local afterSaving = rig.read(reopened)
  support.assertEquals(#afterSaving, 2, "the parts survived a save")

  local byName = {}
  for _, part in ipairs(afterSaving) do
    byName[part.name] = part
  end

  support.assertNotNil(byName["head"], "the head survived a save")
  support.assertEquals(byName["head"].parent, "torso", "the parent link survived a save")
  support.assertEquals(byName["head"].role, "head", "the role survived a save")
  support.assertEquals(byName["head"].pivot.x, 4, "the pivot survived a save")
  support.assertEquals(byName["head"].pivot.y, 5, "the pivot survived a save")
  support.assertEquals(byName["torso"].rect.width, 8, "the rectangle survived a save")

  -- And that a rig read back out actually poses.
  local placed = parts.solve(parts.tree(afterSaving), { torso = { rotation = 90 } })
  support.assertEquals(placed["head"].angle, 90, "the head follows the torso")

  reopened:close()
  os.remove(path)
end

return M
