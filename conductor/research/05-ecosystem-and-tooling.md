# Research 05 — Ecosystem, Competition, and Tool Selection

*Date: 2026-09-18 · Purpose: positioning, reference projects, dependency and
test strategy.*

## 1. Existing Aseprite Script/Extension Ecosystem

| Project | URL | Value for us |
| --- | --- | --- |
| **thkwznk/aseprite-scripts** | <https://github.com/thkwznk/aseprite-scripts> | The best-known general collection: advanced scaling, "Add Inbetween Frames" (tween), Analyze Colors. Primary reference for clean Lua structure and dialog/GUI patterns. |
| **PKGaspi/AsepriteScripts** | <https://github.com/PKGaspi/AsepriteScripts> | Export tools + **PathAnimator** (path-based multi-layer animation). Direct reference for path-based movement. |
| **projectitis/aseprite-community-script-collection** | <https://github.com/projectitis/aseprite-community-script-collection> | Tween, "Ghost Images" (onion-skin-like), Palettize. Community contribution format. |
| **sandord/aseprite-scripts** | <https://github.com/sandord/aseprite-scripts> | General examples. |
| **aseprite/extensions** (official) | <https://github.com/aseprite/extensions> | Official distribution reference. |
| **aseprite/Aseprite-Script-Examples** | <https://github.com/aseprite/Aseprite-Script-Examples> | Official API examples. |
| **Tween Machine** | <https://carbscode.itch.io/the-tween-machine> | Keyframe interpolation toolbar. |
| **Asepritely** | <https://iivii.itch.io/asepritely> | Pay-what-you-want script library. |
| **Pozac FX series** | <https://pozac.itch.io> | **Closest competitor** — see below. |
| **JanBremec — Tiny Impact & Motion** | <https://janbremec.itch.io/tiny-impact-motion-pixel-fx> | 18 ready-made hit/dash/landing FX (PNG + .aseprite). Not procedural, a static asset pack. |

## 2. Gap Analysis — Honest Assessment

**There is a direct competitor.** Pozac (<https://pozac.itch.io>) runs an
Aseprite procedural FX studio:

- **Impact/Explosion FX** ($4.99) — flash, shockwave, debris, smoke, bolt;
  seeded RNG, gravity/drag/turbulence/vortex
- **Spin Motion FX** ($1.99) — rotation/scale/orbit/bounce/shake; squash &
  stretch, recommended for impact animation
- Also Magic Spell FX, Smoke Flow FX, Wave Motion FX, Path Animator FX

In other words, the "procedural impact VFX generation" gap is **closed**.

**However**, these tools are generic transform/particle generators: they
are blind to the character and the sheet, taking a cel/selection as input
and rotating or fragmenting it. No tool was found that **reads the
character sheet** (silhouette, bbox, anchor points) and automatically
generates dash/punch/jump/teleport poses accordingly.

**Our difference:** the combination of *character-aware* procedural action
+ synchronized impact VFX — not just a VFX layer.

## 3. Tools Outside Aseprite

| Tool | Price | Note |
| --- | --- | --- |
| **PixelOver** (<https://pixelover.io>) | $19-30 | Godot-based; bone rig + IK, non-destructive dithering/indexation, 3D import. Closest commercial product, but a separate editor, not integrated into Aseprite. |
| **Juice FX** (CodeManu) | ~$15 | In-engine "juice" (flash/shake/wobble); has spritesheet export, doesn't run in Aseprite. |
| **Pixelorama** | MIT, free | Maturing rapidly; no procedural VFX. |
| **LibreSprite / Piskel** | free | No procedural VFX; Piskel is dormant. |

## 4. External Dependency Assessment

- There is a precedent for FFmpeg bundling (webm export; requires ffmpeg on
  PATH) — a precedent exists.
- However, GitHub Issue #5162: embedding a binary inside an extension is
  risky — extensionless executables get converted to the "Aseprite.app
  Document" format on install and become non-functional; the workaround
  requires a file extension.
- No known Aseprite extension using Python/Pillow/ImageMagick **was
  found**; the ecosystem is almost entirely pure Lua.
- The distribution cost (cross-platform binary, security permission
  prompts, installation friction) is high.

**Decision: avoid external dependencies.**

## 5. MCP and AI Integration

Several Aseprite-specific MCP servers exist:

- <https://github.com/MalloyTheDev/aseprite-mcp> (96 tools, via headless
  batch)
- <https://github.com/willibrandon/pixel-mcp>
- <https://github.com/vchopDev/libresprite-mcp>
- npm: `@iborymagic/aseprite-mcp`

These are not directly our development tool, but the **architecture of
"managing Aseprite in headless/batch mode by generating scripts"** is a
ready-made reference for our test harness design. Blender MCP is a separate
domain, not directly relevant.

## 6. License and Distribution

- The Aseprite EULA only prohibits redistribution of the **Aseprite binary
  itself**; selling your own script/extension is permitted (Pozac's entire
  store confirms this).
- **MIT** is the most common choice for open source (thkwznk).
- A mixed paid + free model (itch.io) has become normalized in the
  ecosystem.

## 7. Test Infrastructure

- `aseprite --batch --script` runs headless, suitable for CI.
- Building from source with GitHub Actions is common and endorsed by the
  owner (setup-aseprite-cli-action, aseprite-auto-build). The Steam binary
  is closed to automation; per the EULA, the compiled binary must not be
  shared as a public artifact.
- **LuaUnit** and **busted** are general Lua test frameworks that exist,
  but no example was found that integrates directly with the Aseprite-Lua
  runtime (special globals like app/Sprite).

**Conclusion:** separate the logic into pure Lua modules and test it in
isolation with LuaUnit; test the Aseprite-dependent part with a batch-mode
script + exit code assertion.

## Strategic Takeaway

1. **Competition:** Pozac fills the procedural FX space. A "just a VFX
   generator" positioning is weak. The difference: reading the character
   sheet and generating action poses specific to it + synchronized VFX —
   the *character-aware* emphasis must come to the fore.
2. **Lessons to learn:** dialog/GUI code structure from thkwznk, path-based
   movement logic from Gaspi's PathAnimator, procedural VFX parameter
   design from Pozac (seeded RNG, preset structure, layer separation).
3. **External dependency:** Avoid — stay in pure Lua. The only
   justification for reconsidering would be a need for advanced
   dithering/quantization.
4. **MCP/tools:** not needed for Aseprite-specific development; the
   `MalloyTheDev/aseprite-mcp` architecture should be studied for test
   harness design.
5. **Test strategy:** logic layer in pure Lua + LuaUnit (isolated);
   Aseprite-dependent layer integration-tested with `--batch --script`.
