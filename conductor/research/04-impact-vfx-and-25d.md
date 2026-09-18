# Research 04 — Impact VFX Anatomy and 2.5D in Pixel Art

*Date: 2026-09-18 · Purpose: To determine the VFX primitive library and the
feasibility of the 2.5D tool.*

## A) Pixel Art Impact VFX

### 1. Anatomy and Timing

Impact effects are generally triggered on the impact frame (t=0) or 1 frame
before/after.

| Effect | Frame count | Trigger |
| --- | --- | --- |
| Hit spark | 3-6 | at the moment of impact; first frame is brightest/largest, quickly shrinks and fades |
| White / silhouette flash | 1 (2 on a heavy hit) | exact moment of impact |
| Shockwave ring | 4-8 | impact +0, expands while fading |
| Speed lines | 2-4 | start of the movement |
| Radial burst / debris | 6-10 | bursts at the moment of impact, particles fall under gravity |
| Dust puff | 4-6 | point of contact; rises and fades |
| Slash / sweep arc | 3-5 | synchronized with the weapon's motion |
| Teleport | 4-6 (dispersal) + 4-6 (gathering) | vertical scanline / noise |

**General rule:** keeping setup frames short (80-100 ms) and the impact frame
long (150-300 ms) creates a sense of weight — with uneven hold durations, 4
frames can be made to feel like 12 frames.

Sources: <https://www.sprite-ai.art/blog/sprite-animation-frames>,
<https://www.youtube.com/watch?v=qcI0mVFZd_U>

### 2. Procedural Mathematics

- **Shockwave ring:** `radius(t) = r0 + (r1-r0)·easeOutQuad(t)`,
  `alpha = 1 - t²`. Draw with a Bresenham circle, thickness fixed at 1-2 px.
- **Particle system:** `pos += vel·dt; vel.y += gravity·dt; life -= dt`.
  In pixel art, particle size is 1-3 px (mostly 1 px), count 6-16 (more than
  that becomes pixel soup). Lifetime ±20% jitter.
- **Radial line distribution:** N lines, `angle = i·(360/N) + random(-jitter,
  jitter)`, jitter 10-20°.
- **Bezier sweep arc:** quadratic Bezier with 3 control points; thickness
  thin at the start and thick at the end (or vice versa) + alpha gradient.
- **Teleport dispersal:** hide/show each pixel in random order using
  thresholded value/Perlin noise.

**Pixel art constraints:** all coordinates must be locked to the grid with
`math.floor`/round; anti-aliasing must not be used (a pixel either exists or
it doesn't); palette limited to 3-5 colors; lines must be single-pixel
thickness and biased toward 45°/vertical/horizontal (Bresenham deviation
stands out in pixel art).

### 3. Color and Palette

Typical VFX ramp: **white/light yellow core → orange/red → dark red/purple
outer edge**. Warm-cool contrast gives a sense of depth.

Additive blending: natively available in Aseprite —
`layer.blendMode = BlendMode.ADDITION`. If manual emulation is needed,
`max(src, dst)` or jumping to the next tone up in the color ramp.

**Silhouette flash:** painting all of the sprite's opaque pixels a single
color (usually white); 1 frame on the impact frame, 2 frames on heavy hits.

### 4. Game Feel Layer

- **Hitstop:** SFV light 8f / medium 12f / heavy 15f; Final Fight fixed at
  6f.
- **Screen shake** (Nijman, *The Art of Screenshake*): amplitude scales with
  attack strength, duration is short (a few hundred ms), decays to zero
  exponentially/linearly; a tiny shake on small attacks, camera jump +
  kickback on big attacks.

**Aseprite constraint:** the canvas is static, there is no real screen
shake. Options:

1. Embedding shake frames into the sheet by offsetting the sprite itself by
   a few pixels — limited benefit since the background doesn't shake.
2. **Exporting a separate `camera_shake` JSON/metadata file** (amplitude,
   frequency, duration, decay curve) to be consumed in the game engine
   (Godot/Unity) — the most practical and engine-agnostic solution. **This
   is the chosen path.**
3. Writing the "freeze frame count" value for hitstop into the same JSON.

Zoom punch and knockback can also be exported with the same metadata
approach (scale curve, displacement vector).

Sources: <https://www.ssbwiki.com/Hitlag>,
<https://www.youtube.com/watch?v=AJdEqssNZ-U>,
<http://notebook.maryrosecook.com/Theartofscreenshake,JanWillemNijman.html>

### 5. Reference Games and Tools

Nuclear Throne (intense hit-spark + knockback), Dead Cells (bright additive
VFX + 3D pipeline), Hyper Light Drifter (colorful slash arcs, short
hitstop), Street Fighter / KOF (classic hit spark design, yellow-orange-
white ramp), Vampire Survivors (simple but intense radial burst + screen
shake).

Tools: <https://github.com/audoraemon/vfxProve> (Godot procedural pixel
VFX), <https://halisavakis.com/my-take-on-shaders-shockwave-effect/>

## B) 2.5D in Pixel Art

### 6. Fake Depth

8-directional sets are produced at 45° intervals (generally 4 directions are
drawn and mirrored; up/down require separate drawings).

Isometric projection:

```
screenX = (x - y) · tileW/2
screenY = (x + y) · tileH/2 - z · heightScale
```

Y-sort: draw order `sortKey = worldY (+ z contribution)`; each sprite is
sorted by its own base point. 3/4 top-down (Zelda-style) is the most common
"2.5D" pixel art style.

Source:
<https://www.slynyrd.com/blog/2025/3/24/pixelblog-55-top-down-character-animation>

### 7. 3D → Pixel Art Pipeline

**Dead Cells model:** simple 3D model + skeleton, rendered at low resolution
(character ~50 px tall) with anti-aliasing off + cell shading, homebrew
rendering tool. Advantage: adapting one animation into dozens of variations
within minutes.

**Normal map / Sprite Lamp:** grayscale images shaded from 4 directions are
embedded into the RG channels to produce a normal map; provides dynamic
lighting in the engine.

**Applicability to Puncher:** Aseprite cannot do 3D rendering. The Blender
render + palette quantization step must remain **outside** the extension;
at most, the extension can offer a helper command that "imports rendered
frames by quantizing them to the palette." Full automation is not possible.

Sources:
<https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i->,
<https://www.gameanim.com/2018/01/31/dead-cells-3d-pipeline-2d-animation/>,
<https://arxiv.org/pdf/2212.09692>

### 8. Fake 3D Rotation

- **Horizontal squash:** scaling the width by `cos(angle)` to fake Y-axis
  rotation through silhouette change. Simple and common.
- **Column-based shear:** shifting vertical columns by different amounts
  (Mode-7-style warp). Works well on flat ground, creates distortion on
  character sprites.

**Limit:** these techniques are only convincing within a ±30-45° range; a
full 360° rotation requires real 3D rendering or hand-drawn frames. Since
scaling/shear causes pixel grid distortion, nearest-neighbor + palette snap
is mandatory.

## VFX Library Proposal (12 primitives)

| # | Primitive | Parameters | Algorithm |
| --- | --- | --- | --- |
| 1 | **HitSpark** | color ramp (3 tones), frame (3-6), size, direction angle | radial star/lines from the center; shrink + fade each frame |
| 2 | **ImpactFlash** | color (white), duration (1-2 frames) | fill the target sprite's opaque mask with a single color |
| 3 | **ShockwaveRing** | r0, r1, thickness, frame (4-8), color | Bresenham circle + easeOut radius + alpha/thickness reduction |
| 4 | **RadialBurstLines** | line (6-16), length, jitter (10-20°), frame | Bresenham line from the center; extend then fade |
| 5 | **DustPuff** | particle (6-12), rise speed, lifetime | random movement up/sideways + darkness reduction |
| 6 | **DebrisParticles** | count (8-16), speed range, gravity, lifetime, size (1-3px) | particle system with Euler integration |
| 7 | **SweepArc** | start/end angle, thickness curve, frame (3-5) | quadratic Bezier + thickness modulation + fade trail |
| 8 | **SpeedLines** | line count, length, direction, frame (2-4) | short lines parallel to the movement vector, behind the sprite |
| 9 | **TeleportDisperse / Gather** | noise threshold curve, scanline direction, frame (4-6 + 4-6) | progressively hide/show the pixel mask based on the noise threshold |
| 10 | **KnockbackDisplacement** *(metadata)* | vector, duration, easing | compute position offset → JSON |
| 11 | **CameraShakeMetadata** *(metadata)* | amplitude, frequency, duration, decay | sine / random-walk offset sequence → JSON |
| 12 | **HitstopMarker** *(metadata)* | frame count (3-15f based on power) | freeze meta-tag on the animation (tag / user data) |

1-9 are implemented directly as procedural pixel drawing via the Lua `Image`
API. 10-12 don't draw pixels; due to Aseprite's canvas limitation, they are
designed as a metadata / export layer.
