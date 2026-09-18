# Research 01 — Aseprite Lua API: Capabilities and Limits

*Date: 2026-09-18 · Purpose: ground the architecture decision (pure Lua vs.
external helper) in evidence.*

## 1. API Surface

All of the `Sprite`, `Image`, `Layer`, `Cel`, `Frame`, `Tag`, `Palette`,
`Slice`, `Selection`, `Color`, `GraphicsContext`, `Timer`, `WebSocket` classes
are available.

- `Image:getPixel(x, y)` → integer color value.
- `Image:putPixel` is **deprecated**; use `drawPixel` instead (does not
  generate an undo record).
- `image:pixels([rect])` iterator: `it()` reads, `it(val)` writes, `it.x` /
  `it.y` gives position.
- `drawImage()` composites with blend mode + opacity; `drawSprite()` renders a
  specific frame.

Source: <https://github.com/aseprite/api/blob/main/api/image.md>

## 2. Performance

A per-pixel Lua loop works but is slow. Community measurements are
inconsistent (e.g., processing all pixels can come out faster than selective
processing — a JIT / undo-tracking artifact). At a scale of 64x64 × 20 frames,
`getPixel/drawPixel` is probably acceptable, but it's not guaranteed.

**Speedup path:** taking the raw byte buffer as a string via `Image.bytes` +
`Image.rowStride` (API v15, Aseprite v1.2.30+), processing it, and writing it
back in one shot — near-C speed.

Since `putPixel` generates undo information on every call, `drawPixel` should
be used on performance-critical paths.

Sources: <https://github.com/haloflooder/Aseprite-Scripts/wiki>,
<https://github.com/aseprite/api/blob/main/api/image.md>

## 3. Dialog API and Live Preview

Widget set: `canvas`, `slider`, `combobox`, `color`, `file`, `shades`, `entry`,
`button`, `check`, `radio`, `separator`, `tab`.

The `canvas` widget supports live preview:

- `onpaint(ev)` → drawing via `ev.context` (GraphicsContext)
- `onmousemove` / `onmousedown` / `onmouseup` / `onwheel` / `onkeydown`
- redraw is triggered with `dlg:repaint()`

**Limit:** no official FPS guarantee is documented. Real-time animation
examples exist in the community, but performance under a continuous-repaint
scenario must be verified experimentally. The `canvas` widget is available
from API v26 / Aseprite v1.3-rc7 onward.

Sources: <https://github.com/aseprite/api/blob/main/api/dialog.md>,
<https://community.aseprite.org>

## 4. Transforms

- `Image:resize()` supports bilinear **and the `'rotsprite'`** method — there
  is native access to the RotSprite algorithm, so we don't need our own
  implementation.
- `flip()` horizontal/vertical.
- dozens of built-in commands such as `app.command.Rotate{angle=...}`,
  `app.command.SpriteSize`, `app.command.CanvasSize`,
  `app.command.FlattenLayers` can be called with the
  `app.command.X{param=...}` syntax; state can be checked with `.enabled`.
- for undocumented command parameters, you need to look at `gui.xml` / the
  source code.

## 5. Undo / Transaction

`app.transaction(function() ... end, "label")` groups multiple changes into a
single undo step. If `error()` is thrown inside it, the changes are
automatically rolled back. This is the fundamental building block of a
non-destructive workflow.

Source: <https://github.com/aseprite/api/blob/main/api/app.md>

## 6. Sandbox and Outside-World Access

- The script environment is sandboxed; some standard Lua functions (`os.exit`
  etc.) are not available.
- `os.execute` / `io.open` / `io.popen` **require user permission** (the "Give
  Script Full Access" approval).
- `app.fs` provides file/directory listing and path operations, but **does
  not include an arbitrary file-write function** (writing requires raw
  `io.open(path, "w")` + permission).
- **Important risk:** Aseprite merged PR #5965 (September 14, 2026, beta),
  which thoroughly revises the permission system: a move from ini-based
  permissions to `permissions.json` + BLAKE3 integrity checking + a separate
  "debug" permission tier. The UX of calling external binaries may become
  more friction-heavy in the near future.

Sources: <https://community.aseprite.org>,
<https://github.com/aseprite/aseprite/pull/5965>

## 7. JSON, HTTP, Library Loading

- **Native `json.encode` / `json.decode`** are available as a global `json`
  namespace as of API v25 (v1.3-rc5) — no external library needed.
- There is no native function for HTTP; however, there is a **native
  `WebSocket` class** (API v15, v1.2.30+) — a more "permission-friendly"
  channel than `os.execute` for communicating with an external process over a
  local socket (see PR #2980).
- `require()` is available from API v23 (v1.3-rc3+) onward; in practice the
  community finds the `dofile('./lib.lua')` approach more reliable.

Sources: <https://github.com/aseprite/api/blob/main/api/json.md>,
<https://github.com/aseprite/aseprite/pull/2980>

## 8. Extension Packaging and Distribution

`.aseprite-extension` = a zip; it contains at minimum a `package.json` (name,
displayName, version, author, categories, contributes). Script registration:
`contributes.scripts: [{ path: "./script.lua" }]`. There are also separate
contributes fields for palettes, themes, languages, keys.

Distribution: itch.io (common; you can set your own license), GitHub
Releases. There is **no** centralized official extension store; sharing
happens via community.aseprite.org. The Aseprite EULA only prohibits
redistribution of Aseprite itself, and does not affect extensions.

Sources: <https://aseprite.org/docs/extensions>,
<https://github.com/aseprite/aseprite/blob/main/EULA.txt>

## 9. Version Thresholds

| API | Aseprite | Feature added |
| --- | --- | --- |
| v14 | v1.2.28 | tilemap |
| v15 | v1.2.30 | **Image.bytes + rowStride, WebSocket** |
| v23 | v1.3-rc3 | Editor, `require()` |
| v25 | v1.3-rc5 | **native json** |
| v26 | v1.3-rc7 | **canvas widget** |
| v30-31 | v1.3.11 | GraphicsContext on Image |

**Recommended minimum: v1.3-rc7+; ideal: v1.3 stable / v1.3.11+.**

Source: <https://aseprite.org/api/Changes>

## Architectural Conclusion

1. **Pure Lua is sufficient.** All the primitive operations needed for pixel
   art conversion, procedural animation, and the VFX layer are natively
   available.
2. **The wall we'll hit is per-pixel loop performance.** Mandatory
   optimization: write performance-critical algorithms over the raw
   `Image.bytes` buffer, and write it back in one shot.
3. **Live preview is possible but without an FPS guarantee.** Should be
   measured with an early prototype in Phase 1.
4. **No need for an external binary, and it should even be avoided:** the
   permission dialog, cross-platform build overhead, distribution
   complexity, and the tightening permission system.
5. **Recommended architecture:** native `rotsprite` + custom
   quantization/dither over the bytes-buffer; a pure-Lua mathematical motion
   engine; a single undo step per preset via `app.transaction`; VFX in
   separate layers via `drawImage` + blend mode; preview via `Dialog` +
   `canvas`.
