# Tech Stack — Puncher

> This stack is based on the findings of the five research reports under
> `conductor/research/`. Changes must be documented here **before**
> implementation (see `workflow.md` → Guiding Principles).

## Core Decision: Pure Lua

The extension runs **entirely within Aseprite's embedded Lua environment**.
There is **no** dependency on an external binary, Python interpreter, or any
other runtime.

Rationale:

- All the primitive operations we need are natively available in the API
  (see table below).
- `os.execute` / `io.popen` trigger the "Give Script Full Access" permission
  dialog for the user; this is significant setup friction for an extension
  distributed to the community.
- Aseprite made a revision tightening the permission system (PR #5965,
  September 14, 2026: `permissions.json` + BLAKE3 integrity check) — the
  path to invoking external processes is narrowing.
- The ecosystem norm is pure Lua; no known Aseprite extension using
  Python/ImageMagick was found. Cross-platform binary packaging also leads
  to a known problem (GitHub Issue #5162: extensionless executables get
  corrupted during installation).

## Platform and Version Target

| Item | Decision |
| --- | --- |
| Language | Lua 5.4 (Aseprite embedded) |
| Minimum Aseprite | **v1.3-rc7** (API v26 — the `canvas` widget arrived in this version) |
| Targeted | **v1.3.11+** (stable; includes `GraphicsContext` on `Image`) |
| Runtime dependency | None |

Rationale for the version threshold: the `canvas` widget (API v26 /
v1.3-rc7), native `json` (API v25 / v1.3-rc5), and `Image.bytes` (API v15 /
v1.2.30) — all three together are only guaranteed from v1.3-rc7 onward.

### Development Environment (verified as of 2026-09-18)

| Item | Value |
| --- | --- |
| Binary | Built from source at tag `v1.3.18.5`. Its location is machine-specific and is read from the `ASEPRITE_BIN` environment variable, never hardcoded in tests or scripts. |
| Version | `1.3.18.5-dev`, **API v41** |
| Skia | `aseprite-m124` prebuilt package, as the upstream build instructions require |

Headless operation (`--batch --script`) has been verified: it runs without a
display → an integration test strategy is viable. The following API
capabilities were tested live and work: `Image:resize{method='rotsprite'}`
(a scaling method, not a rotation), global `json`, `Image.bytes`.

Between v1.3.15.3 and v1.3.18.5, the scripting API went from v36 to v41.
Behavior changes that concern us: `properties` changes made outside a
transaction no longer generate an undo step (#4568) — our cross-command
metadata contract will not pollute the undo history; layer flag changes made
inside a transaction, on the other hand, correctly enter the undo history
(#2991). Also, support for imageless cels (#1303) can be used to represent
freeze/hitstop frames.

## API Surfaces to Use

| Need | API | Note |
| --- | --- | --- |
| Fast pixel processing | `Image.bytes`, `Image.rowStride` | Get the raw buffer as a string, process it, write it back in one shot. This is the performance-critical path. |
| Pixel read/write (simple) | `image:pixels()`, `Image:getPixel` | Only for small regions. |
| Pixel write | `Image:drawPixel` | `putPixel` **will not be used** — deprecated and generates an undo record on every call. |
| Composition | `Image:drawImage(img, pos, opacity, blendMode)` | Combining VFX layers. |
| Pixel-art-safe scaling | `Image:resize{ method='rotsprite' }` | The RotSprite *scaling* method is available. It is not a rotation: see the rotation row below. |
| Built-in commands | `app.command.X{...}` | `Rotate`, `SpriteSize`, `CanvasSize`, etc. |
| Non-destructive operation | `app.transaction(fn, "label")` | Each command is a single transaction; `error()` inside it → automatic rollback. |
| Interface | `Dialog` + `canvas` widget | `onpaint(ev)` → `ev.context` (GraphicsContext); `onmousemove`, `dlg:repaint()`. For live preview. |
| Metadata | native `json`, `sprite.properties`, `layer.properties`, user data | Cross-command contract + exported game-feel data. |
| Anchor/pivot | `Slice` (+ pivot field) | Storing character anchor points. |
| File system | `app.fs` | Path operations and directory listing (`io.open` for writing, export flow only). |

**Known risk:** There is no official FPS guarantee for the `canvas` widget.
Live preview performance will be measured with an early prototype in Phase 1;
if insufficient, the preview will be downgraded to a single frame / lower
resolution (see `product-guidelines.md` item 4).

## Code Architecture

```
core/        Pure Lua. ZERO references to the Aseprite API.
             easing, curves, arcs, squash&stretch, particle sim,
             color (OKLab), quantize, dither, geometry, rng.
             → Tested headless with LuaUnit, coverage target >80%.
adapter/     Aseprite API wrapper. Converts the pure data produced by core
             (pixel matrix, transform list) into Image/Cel/Layer/Tag.
commands/    Menu commands and Dialogs (Ingest Sheet, Pixelate,
             Apply Motion, Add VFX, Export). Exempt from the coverage target.
presets/     Data: animation preset parameters, VFX parameters, palettes.
assets/      Sample characters, test fixtures, reference (golden) outputs.
```

This separation is non-negotiable: the `core/` layer's independence from
Aseprite is a precondition for both the test strategy and the coverage
target.

## Algorithmic Decisions

| Area | Choice | Rejected |
| --- | --- | --- |
| Color quantization | Wu / median-cut + k-means refinement (libimagequant model), on `Image.bytes` | Gerstner et al. joint superpixel+palette optimization (NPAR 2012) — highest quality but iterative and on the order of seconds → **v2** |
| Color distance | **OKLab** Euclidean distance | RGB (perceptually incorrect), CIELAB (hue shift in the blue region) |
| Dithering | **Bayer (ordered)** 4x4/8x8, default **off** | Floyd-Steinberg — "shifting" noise between frames creates flicker in animation |
| Rotation | Pure Lua over a pixel matrix: exact for quarter turns, otherwise enlarge eightfold with an edge-aware filter, turn there, vote back down | Relying on the application to rotate (it cannot, from a script); turning on the native grid; snapping to exact angles only; enlarging sixteenfold. See the measurement below. |
| Deformation | Part-based affine (head/torso/arm/leg cut from the sheet + pivot) | Full mesh warping / ARAP — unnecessary complexity |
| Pixelization (AI) | None | GAN/diffusion pixelization — palette and grid inconsistency between frames, GPU dependency → **v2 option** |
| Screen shake / hitstop | Exported as JSON metadata | Real screen shake is not possible within the Aseprite canvas |

### The rotation route, decided by measurement (2026-09-19)

Four candidates were rendered on the same subjects at the same angles and
scored against a much finer turn standing in for the truth. Subjects were the
two sizes that matter: a limb of five by twelve pixels, and a whole figure of
sixteen by twenty-four. Angles were ten, twenty, thirty, forty-five, sixty and
seventy-five degrees.

| Route | Worst agreement, limb | Worst agreement, figure | Cost per turn, figure |
| --- | --- | --- | --- |
| Turn on the native grid | 93.9% | 94.3% | 0.2 ms |
| **Enlarge eightfold, turn, reduce** | **97.9%** | **98.6%** | **37 ms** |
| Enlarge sixteenfold, turn, reduce | 100% | 99.3% | 149 ms |
| Snap to the nearest quarter turn | 20.3% | 35.6% | 0.1 ms |

Chosen: eightfold, with quarter turns going through the exact path instead
since they are free and lose nothing.

Why not the others. Turning on the native grid loses about one pixel in
twenty, which is not an abstraction - it is the chewed outline visible in the
comparison sheet at exactly the small angles a limb needs. Sixteenfold buys
under a percentage point on a figure for four times the cost. Snapping does
not rotate at all: a limb stays upright until the angle passes forty-five
degrees and then falls flat, which the score reflects honestly.

Two earlier attempts to measure the damage are recorded because they failed
and the failures are instructive. Counting holes surrounded on four sides
found none under any route. Counting how many separate pieces the drawing
broke into also found none - every route leaves it in one piece. The visible
damage is edge quality, not topology, and only a comparison against a finer
turn captured it. The impression that a bad turn "breaks the legs off" was
wrong, and the numbers said so.

Reproduce with `"$ASEPRITE_BIN" --batch --script tools/compare_rotation.lua`.

#### What that measurement could not see (2026-09-20)

The agreement score above is computed against a thirty-two-fold detour, which
is the same enlarge, turn and vote pipeline as the candidate it is judging,
only finer. That makes it a fair measure of angular precision - a finer grid
really does resolve an angle better - and an unfair one for the reduction
rule, because the standard shares the candidate's rule. It is also blind to
detail by construction: agreement counts every pixel alike, and the pixels
that carry a face are three out of two hundred.

Measured again with a standard that shares nothing with any candidate. A turn
preserves area, so the count of each colour should survive it. On a figure
with detail drawn into it, averaged over the same six angles:

| Route | Large regions | A line one pixel wide | Single pixels |
| --- | --- | --- | --- |
| Turn on the native grid | 99-103% | 109% | 67% and 83% |
| Enlarge eightfold, turn, vote | 99-103% | 94% | 42% and 33% |
| Enlarge eightfold, turn, sample the centre | 99-101% | 85% | 58% and 50% |
| Enlarge sixteenfold, turn, vote | 99-103% | 94% | 42% and 33% |

So the chosen route is the best of these at edges and at thin limbs, and the
worst at single pixels: it loses around three fifths of them. Sixteenfold
recovers none of that, which places the cause in the vote rather than in the
grid - a block the body merely outnumbers goes to the body, and an eye is
always outnumbered.

The route is not being changed, because no candidate measured here is better
overall and sampling the centre trades a worse thin limb for a still-poor eye.
What this is instead is a stated limit: a detail one pixel across is not
reliably carried through a turn by any route measured so far. Recorded as a
backlog row, because the fix is a reduction that knows a small feature from
noise, which is a piece of research rather than a repair.

Reproduce with `lua tools/measure_detail.lua`, which needs no editor.

## Test and Quality Infrastructure

| Layer | Tool | Note |
| --- | --- | --- |
| Core unit tests | **LuaUnit** (with system Lua 5.4) | Runs directly in CI since `core/` has no dependency on Aseprite. |
| Integration tests | `"$ASEPRITE_BIN" --batch --script tests/integration/run_all.lua` | Headless; based on exit code + assert. |
| Visual regression | Golden PNG comparison | Reference outputs are under `assets/`; intentional changes are noted in the commit message. |
| Lint | `luacheck` | |
| Format | `stylua` | |
| CI | GitHub Actions | Core tests + lint run in CI. Integration tests that require Aseprite run locally; per the EULA, the compiled Aseprite binary is not shared as a public artifact. |

## Packaging and Distribution

- Format: `.aseprite-extension` (`package.json` + Lua sources inside a zip).
- `package.json` → `contributes.scripts: [{ path: "./..." }]`.
- License: **MIT** (ecosystem norm; thkwznk and other major collections are
  MIT).
- Channels: GitHub Releases + itch.io. There is no central official
  extension store.
- The Aseprite EULA only prohibits redistribution of the Aseprite binary;
  selling/distributing third-party extensions is unrestricted.

## Positioning Note (competition)

`pozac.itch.io` sells procedural Aseprite FX tools (Impact/Explosion FX,
Spin Motion FX, etc.) — the "procedural VFX generator" space is not empty.
However, these tools are character-blind: they take a cel/selection and
apply a generic transform or particle effect. Puncher's difference is being
**character-aware**: it reads the character sheet (silhouette, bbox,
anchor), generates action poses specific to it, and synchronizes VFX to this
motion. This distinction drives both the technical design and the product's
positioning.

## Reference Projects

| Project | For what |
| --- | --- |
| `thkwznk/aseprite-scripts` | Dialog/GUI code structure, tween ("Add Inbetween Frames") approach |
| `PKGaspi/AsepriteScripts` (PathAnimator) | Path-based multi-layer motion logic |
| `aseprite/Aseprite-Script-Examples` | Official API examples |
| Pozac FX series | Procedural VFX parameter design (seeded RNG, preset structure, layer separation) |
| `MalloyTheDev/aseprite-mcp` | Headless batch architecture — inspiration for test harness design |
