# Research 03 — Animation Math and Motion Engine Design

*Date: 2026-09-18 · Purpose: establish the mathematical foundation of the
`core/` layer.*

## 1. Easing and Timing

Penner easing families: sine, quad, cubic, quart, quint, expo, circ, back,
elastic, bounce — each in in / out / in-out form. Fundamental identity:

```
easeOut(t) = 1 - easeIn(1 - t)
```

They can be approximately mapped with a cubic Bezier (CSS
`cubic-bezier(x1,y1,x2,y2)`); even back/elastic, which include overshoot,
can be modeled with control points.

**At low frame counts (6-12 frames)** a continuous curve is not simply
sampled. Two techniques are used together:

- **Non-uniform frame duration:** frame durations aren't equal; frames
  become denser when speed is low (hold/duplicate on the last frames in
  ease-out).
- Position sampling: `t_i = easeFn(i / (N-1))`, `pos_i = lerp(start, end,
  t_i)`.
- **Moving hold:** 1-3 frame repeat at the extremes (first/last frame).

Sources: <https://easings.net>, the joshondesign.com easing article, zz85
cubic-bezier approximations.

## 2. Formulating the 12 Principles

| Principle | Formula / rule |
| --- | --- |
| Anticipation | A small offset in the opposite direction before the motion: `-0.15 * displacement`, 2-3 frames |
| Squash & Stretch | Volume preservation: `s_x * s_y ≈ 1`. In practice: `s_y = 1+k`, `s_x = 1/(1+k)`; `k` depends on speed/momentum |
| Overshoot / follow-through | Damped harmonic oscillator: `x(t) = target + A·e^(-ζωt)·cos(ωt)`; in practice 1-2 overshoot + 1 settle frame |
| Arcs | Quadratic Bezier: `B(t) = (1-t)²P0 + 2(1-t)t·P1 + t²P2`; `P1` determines the apex of the arc |
| Exaggeration | A single "juice" coefficient applied to all offset/scale multipliers |

The volume-preserving general form of 3D squash & stretch (Houdini):
`L'·D'·H' = ((L - L')·Vp + L')·D·H`, `Vp ∈ [0,1]`.

## 3. Fighting / Action Frame Structure

The **Startup / Active / Recovery** triad is universal:

- startup: the frames before the hit connects
- active: the window in which damage can be dealt
- recovery: the vulnerable return

According to Dustloop/SF6 wiki data, normal attacks are typically in the
range of 3-7 startup / 2-4 active / 8-20 recovery. At 60 FPS a dash is
roughly 10-16 frames (2-4 startup, 6-10 travel, 2-4 recovery).

**Hitstop / hitlag:** both characters freeze at the moment of the hit. Real
examples: Street Fighter V light 8f, medium 12f, heavy 15f; Final Fight
(1989) a fixed 6f; in Smash Bros, up to half a second on powerful attacks.

Sources: <https://dustloop.com>, <https://www.ssbwiki.com/Hitlag>,
<http://shoryuken.com/2016/06/07/hitstop-in-street-fighter-v-kens-not-so-little-secret/>

## 4. Smear Frame Types

- **Stretched/elongated smear:** a single stretched frame between extremes.
- **Multiple/ghost smear:** several copies of the same pose with decreasing
  alpha.
- **Hybrid:** a mix of the two.

In pixel art (the classic Castlevania whip example), a silhouette sweep with
few pixels is enough. Procedural generation: stretch the sprite along a
single axis with scale + shear along the motion vector, apply an alpha
gradient, then pixel-snap.

Sources: <https://en.wikipedia.org/wiki/Smear_frame>, rebusfarm.net,
animschool.edu

## 5. Afterimage / Motion Trail

2-5 "echo" frames, exponentially decreasing alpha: `alpha_i = alpha_0 ·
decay^i`, `decay ≈ 0.5-0.7`. Optional color shift (hue shift or moving toward
white/blue).

## 6. 2D Deformation

- **Affine:** a 2x2 matrix + translate (rotate/scale/skew).
- **Cutout / skeletal** (Spine2D, DragonBones): split the character into
  parts (head/torso/arm/leg), assign a pivot to each part, FK/IK via bone
  hierarchy.
- **ARAP** (as-rigid-as-possible) mesh deformation: soft deformation that
  preserves local rigidity.

**The low-risk / high-payoff choice for Puncher:** cutting the sheet into
parts (head/torso/arm/leg) and applying a separate `Image` + pivot + affine
transform to each part. Full mesh warping is not required.

## 7. The Pixel Art Rotation Problem

Naive rotation/scaling produces jaggies and color blurring.

**RotSprite** (Xenowhirl, 2007): first upscale with Scale2x, rotate the
upscaled copy, then resample back down — the original palette is preserved,
edges stay clean. The hqx / Scale2x / Eagle families recognize edge direction
and assign new pixels according to neighborhood rules.

Three rules required for the engine:

1. At small angles (<15°), a RotSprite-style upscale → rotate → downscale.
   *(Correction, 2026-09-19: this was recorded as being native. It is not.
   See the note at the end of this section.)*
2. **Pixel-grid snapping** after every frame is generated (round the
   position to a whole pixel).
3. **Sub-pixel accumulator:** carry the rounding remainder to the next
   frame, otherwise round-off error accumulates.

### Correction, 2026-09-19: the application cannot rotate from a script

Checked against the application's own source before track 2 was planned,
because the whole part-based deformation approach rests on it.

| What exists | What it does | Usable for a limb |
| --- | --- | --- |
| `Image:resize{ method='rotsprite' }` | Scaling. The RotSprite name refers to the filter used while resampling, not to rotation. | No |
| `app.command.Rotate{ angle = ... }` | Quarter turns only - the command handles 90, -90 and 180 and nothing else. Acts on the whole sprite or on the selection, and changes the sprite's dimensions. | No |
| `doc::algorithm::rotate_image(..., double angle)` | Arbitrary angle, and it is what the interactive transform tool uses. Lives in the application's C++ and is not exposed to scripts. | Not reachable |

So arbitrary-angle rotation has to be written in the core layer, over a plain
pixel matrix read out of and written back into a cel in bulk. That is not a
setback: it puts rotation where it can be unit tested without the application
running at all, and it means the algorithm is ours to choose rather than
inherited.

Research 07 carries the algorithm: an edge-aware doubling filter applied
repeatedly to enlarge, a nearest-neighbour rotation by inverse mapping at the
enlarged size, then a reduction that picks rather than blends so no colour is
invented. It also carries the reason the enlargement factor matters more here
than in the sources: the published default was tuned on sprites several times
larger than a limb at this scale.

## 8. References

Steve Swink — *Game Feel*; Jan Willem Nijman — *The Art of Screenshake*
(Vlambeer, INDIGO 2013); Dustloop Wiki "Using Frame Data"; SmashWiki
"Hitlag"; <https://easings.net>; the original RotSprite forum thread (Sonic
Retro); Spine2D / DragonBones documentation.

## Motion Engine Design Proposal

Parameters taken by each preset function:

| Parameter | Type | Description |
| --- | --- | --- |
| `frameCount` | int | dash≈8, punch≈6, jump≈12 |
| `speed` | 0-2 | time scale (low = heavy, high = snappy) |
| `weight` | 0-2 | momentum / overshoot / squash intensity |
| `exaggeration` | 0-2 | overall coefficient applied to all offset and scale multipliers |
| `distance` | px | target displacement relative to the pivot |
| `easingType` | enum | easeOutCubic, easeOutBack, easeInExpo... |
| `anticipationFrames` / `overshootFrames` / `holdFrames` | int | can be overridden per preset |
| `smearEnabled`, `trailEnabled` (`echoCount`, `decay`) | bool/param | |

**Forward dash example — generation steps:**

1. Normalized time sequence for the main motion frames:
   `t_i = easingType(i / (frameCount - anticipationFrames -
   overshootFrames - 1))`
2. Reverse offset on the first `anticipationFrames` frames:
   `offset = -0.15 * distance * exaggeration`; apply squash (`s_y = 0.85`,
   `s_x = 1/0.85`).
3. On the main frames, `pos_i = pivot + distance * t_i`. For jump, a
   parabolic arc: `y = -4h·t·(1-t)`.
4. Stretch on the middle frames where speed is highest:
   `s_x = 1 + weight·0.3·|v_i|`, `s_y = 1/s_x`; aligned to the motion axis,
   with pixel integrity preserved via an affine transform and a rotation
   implemented in the core layer.
5. In presets like punch, set the hitbox flag on `active` frames; at the
   moment of the hit, freeze the motion for
   `hitstopFrames = round(3 + 5·weight)` (position fixed, increase squash).
6. Damped oscillation on the final `overshootFrames` frames:
   `x(t) = target + A·e^(-ζωt)·cos(ωt)`; `A` and `ζ` depend on `weight`.
7. After each frame, round the position to the pixel grid, carrying the
   fractional remainder to the next frame via the accumulator.
8. If `smearEnabled`, a stretch smear on the fastest frame, or
   alpha-decreasing copies of the previous 2-3 frames; if `trailEnabled`,
   `echoCount` copies in a separate layer, `alpha_i = 0.5·decay^i`.
9. Write the frames to cels as separate `Image` objects; assign non-uniform
   duration (hold frames 2x, fast transitions 1x).

Thanks to this parametric structure, 10-20 presets are derived from the same
core functions (easing sampler, arc generator, squash&stretch, smear/trail
compositor, pixel-snap); presets differ only by their parameter sets.
