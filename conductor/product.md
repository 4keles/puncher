# Puncher — Aseprite Procedural Action Animation Extension

## Vision

An Aseprite extension that lets pixel art artists produce fast-paced action
animations (dash, impact, teleport, jump) in seconds using **mathematically
parameterized ready-made motion templates**, instead of drawing them frame by
frame by hand.

## Problem

The most time-consuming parts of action animation are, in fact, largely
mathematical: in-between generation, easing/timing curves, smear frames,
squash & stretch, anticipation/overshoot, afterimage, and impact VFX. While
the artist spends time on this repetitive mechanical work, they can't focus
on the character's personality. The "feel of the hit" (game feel) often
stays weak due to a lack of technical knowledge.

## Product Summary

Two tools running inside Aseprite, built on a shared mathematical motion
core:

1. **2D Tool** — For classic side-view/front-view characters.
2. **2.5D Tool** — For characters with fake depth support (perspective
   offset, scale, 8 directions, faux-3D rotation).

Flow: **Load character sheet → (normalize according to the defined
sheet/anchor structure) → algorithmic pixel art transformation → apply
motion → select animation preset → add impact VFX layer → output as
editable Aseprite layers.**

## Target User

The general pixel art community: indie game developers, pixel artists, game
jam participants. Especially those working in fast-paced genres like
platformer, beat'em up, hack & slash.

## Core Capabilities

1. **Sheet Ingest & Normalization** — Defined sprite sheet structure: grid,
   pivot/anchor points, skeleton markers, direction labels.
2. **Pixel Art Converter** — Algorithmic: color quantization, palette
   mapping, dithering, edge cleanup/outline, downscale.
3. **Motion Engine (mathematical core)** — Easing curves, motion arcs,
   anticipation/overshoot, squash & stretch, smear interpolation, motion
   trail, frame timing (hold/ease frames).
4. **Animation Library** — 10-20 parametric presets: jump, forward dash,
   back dash, punch/hit, teleport, landing, hurt/knockback, dodge roll,
   wind-up, slam, etc.
5. **VFX / Impact Layer (the heart of the product)** — Hit spark, impact
   ring, speed lines, afterimage/echo, flash, dust puff, screen shake data,
   chromatic tear.
6. **2.5D Mode** — Perspective offset, scale, y-sort, 8-directional
   variants.

## Success Criteria

- After loading a character sheet, a working "dash + impact" animation can
  be produced in **under 1 minute**.
- Output is **non-destructive**: it comes as editable Aseprite layers and
  frames.
- Presets are parametric: speed, weight, exaggeration, frame count, VFX
  intensity.
- Can be packaged as an Aseprite Extension and shared with the community.

## Out of Scope (for now)

Real 3D render/rigging, sound, game engine runtime integration (export
formats only), generating character design/art.

## Roadmap

- **Phase 0 — Research (priority):** Aseprite Lua API limits, pixel art
  conversion algorithms, animation math, VFX techniques, existing extension
  ecosystem, MCP/external tool integrations. The MVP scope will become
  clear from this phase's output.
- **Phase 1:** Motion core + 2D tool + sheet ingest.
- **Phase 2:** Expansion of the animation preset library.
- **Phase 3:** VFX/impact layer.
- **Phase 4:** 2.5D tool.
- **Phase 5:** Packaging and community distribution.
