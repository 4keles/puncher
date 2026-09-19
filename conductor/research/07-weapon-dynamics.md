# Research 07 — Weapons in the Air

*Date: 2026-09-19 · Purpose: the mathematics of a thrown or swung weapon, the
region its blade carves out between frames, and how that becomes pixels.*

Tags as in research 06: **[MEASURED]**, **[CONVENTION]**, **[INFERENCE]**.

## 1. Rotational kinematics

### The decomposition

Any rigid body's motion splits into translation of its centre of mass plus
rotation about that centre. For a thrown axe: **[MEASURED, standard
mechanics]**

```
r_com(t) = r0 + v0*t + (1/2)*g*t^2      -- ballistic parabola
theta(t) = theta0 + omega*t             -- near-constant angular velocity
```

The parabola is exact rather than approximate, because gravity acts uniformly
and therefore exerts no net torque about the centre of mass.

**The decoupling fact that matters:** `omega` is set at release and does not
change with translational speed. A thrown axe's spin rate is independent of
how hard it was thrown. Only the *number* of rotations completed depends on
flight time.

### Choosing a spin rate

Competitive axe throwing tunes the rotation count to the distance by changing
grip position, aiming for an integer or half-integer number of full rotations
so the edge rather than the flat meets the target. **[MEASURED, sport
practice]**

This maps directly onto a procedural rule, and it is the inverse of the naive
approach: **fix the readable rotation count first, then derive the angular
velocity from the flight time.**

```
omega = (rotations * 2*pi) / flight_time
```

One rotation reads as a controlled throw; three or more reads as a wild
tumble. Flight time itself falls out of the ballistic equation once launch
speed and angle are fixed. **[CONVENTION]**

### Why an axe and a sword look different in flight

A one-handed sword's point of balance sits 5-10 cm forward of the hilt — mass
is deliberately kept near the hand for handling speed. An axe's balance point
sits just below the head, far out along the shaft — mass kept far from the
hand for chopping power. **[MEASURED, cutlery and bladesmithing sources]**

The visual consequence: a thrown axe's centre of mass is near the head, so the
haft whips around a point close to one end and the spin reads as head-heavy
and lopsided. A thrown sword rotates about a point near its own middle and
reads as a smoother, more balanced tumble. "The axe spins, the sword tumbles"
is a real distinction worth encoding, not flavour text. **[INFERENCE from the
measured balance points]**

### Moment of inertia, and what it buys

```
point mass at radius r  : I = m*r^2
thin rod about centre   : I = (1/12)*M*L^2
thin rod about one end  : I = (1/3)*M*L^2
composite (haft + head) : I = I_rod + m_head*d^2   (parallel axis)
```

**[MEASURED, standard tables]**

Since `torque = I * angular_acceleration`, a heavy head far from the pivot
inflates inertia quadratically in distance, so the same wind-up torque
produces far less angular acceleration. This is the mechanical reason a
heavy-headed weapon reads as needing a longer wind-up and a lower peak spin
than a light, evenly balanced one.

For this engine that is a lookup, not a live simulation: tag each weapon
archetype with a relative effective-inertia scalar that scales wind-up
duration and caps peak angular speed. **[INFERENCE]**

### Tip speed

```
v_tip = omega * r
```

The eye tracks the tip and the edge, not the pivot, so tip speed rather than
angular speed is what reads as fast. A long weapon at moderate angular speed
has a fast tip. Trail length and speed-line intensity should be driven by
`v_tip`. **[MEASURED identity + CONVENTION for the consequence]**

### The profile of a swing

A swing is not constant angular velocity. **[CONVENTION, animation practice]**

1. **Wind-up**: angular velocity near zero or negative, the weapon drawn back
   past its rest position.
2. **Acceleration**: angular velocity ramps up sharply, over-cranked past what
   muscle torque alone would give, because a linear ramp reads as weak.
3. **Peak at or just before impact.** Contact should happen at or fractionally
   after the speed maximum, never after it has begun decaying — hitting with a
   decelerating weapon reads as staged.
4. **Follow-through**: angular velocity continues past the nominal stop angle,
   overshoots, then eases back.

This is an asymmetric easing curve with the impact frame pinned near the
velocity maximum — which the existing easing and Bezier tooling already
expresses.

## 2. The swept region

Between one frame and the next a blade point at radius `r` sweeps from
`theta(t)` to `theta(t+dt)`. The region the whole blade carves out, from its
pivot-side edge at `r_min` to its tip at `r_max`, is an **annular sector**.

```
Area = (1/2) * d_theta * (r_max^2 - r_min^2)
```

**[MEASURED, standard geometry]**

This is exactly what a trail or a smear represents visually: the trail is a
rendering of the swept sector, not of the blade's own shape. A trail whose
width does not scale with `r_max^2 - r_min^2` misrepresents the swept area and
looks wrong on long weapons. **[INFERENCE]**

For a **translating** weapon the swept region is not a sector but the union of
the silhouette at both times plus the strip connecting corresponding edge
points — a Minkowski-sum strip along the translation vector. The practical
simplification is a capsule of length `|v|*dt` and width equal to the
silhouette extent perpendicular to the velocity. **[INFERENCE]**

## 3. How games draw weapon trails

**Ribbon trails (3D).** A trail component records the emitter's world
positions over the last N *seconds* and builds a camera-facing quad strip with
per-vertex width and a colour gradient sampled along its length. Because the
window is time-based rather than distance-based, length scales with speed for
free — which matches the swept-sector fact above without computing it.
**[MEASURED, engine documentation]**

**Hand-drawn arc sweeps (2D and pixel art).** The trail is a separate authored
crescent sprite, placed and rotated to match the swing and shown for one to
three frames at or just after the peak-speed frame. This is the dominant
technique in pixel art action games, because it gives control over the
crescent shape and colour banding that pixel art wants. **[CONVENTION]**

**Ghost afterimages.** Copies of the sprite at the last few positions, each
faded and often tinted, spawned at a fixed interval during fast motion and
fading on their own clock. Standard for dashes and fast swings alike.
**[CONVENTION]**

**Single stretched smear.** For one decisive hit, one or two in-between frames
are replaced by a smear shape covering the swept path. Cheaper than a trail
system and reads better for a single strike than for a sustained spin.
**[CONVENTION]**

**Speed lines and crescents.** Slashes are drawn as crescents, narrower at the
trailing end than at the leading tip, often with radiating straight lines
behind and a brief flash at the plane of impact. **[CONVENTION, anime-derived]**

What artists actually tune, converged across sources: trail lifetime in
seconds, start and end width, a colour gradient with a distinct leading-edge
colour, alpha over life, afterimage spawn interval and per-ghost fade, and for
hand-drawn arcs the crescent's opening angle and thickness taper.

## 4. Rotating a small sprite

### Why the naive approach fails

Standard rotation either interpolates and invents colours — fatal for a
palette-locked sprite — or, with nearest-neighbour sampling, produces jagged
edges with gaps, because a source pixel maps to a fractional destination and
neighbouring source pixels can land non-adjacently. Clean one and two-pixel
linework that reads fine at quarter turns falls apart at arbitrary angles.
**[MEASURED, community and issue-tracker testimony]**

### RotSprite

Xenowhirl, around 2007, written for Sonic sprite work; implemented in
Aseprite's own source at `src/doc/algorithm/rotsprite.cpp`. Three stages:
**[MEASURED]**

1. Upscale the source eightfold with a modified Scale2x/Scale3x edge-detecting
   filter that treats *similar* rather than only identical colours as matches
   — the key deviation from stock Scale2x, and what lets it handle
   anti-aliased or dithered pixel art.
2. Rotate the enlarged image with ordinary nearest-neighbour sampling, safe
   now because the rotation error is sub-pixel relative to the final
   reduction.
3. Reduce back to the original size with nearest-neighbour sampling, applying
   the rotation's translation at the same time; optionally a final pass
   restores single-pixel details by comparing against the untouched source.

It introduces no new colours, which is the property pixel art actually needs.

### Safe angles and the pre-baked set

Graphics tooling conventionally works in 15-degree subdivisions; multiples of
15 align cleanly to the upscale and reduce grid. Angles between them still
work but are where residual artefacts show, especially below 16 pixels where a
couple of misplaced pixels are a large fraction of the silhouette.
**[CONVENTION]**

**The universal industry answer is to avoid arbitrary runtime angles
entirely:** pre-rotate the sprite once into a fixed set of directions — eight
is the common minimum, sixteen is ample for most cases, twenty-four or
thirty-two only for large, fast-rotating assets where the step would otherwise
be visible — and pick the nearest at runtime. This removes both the cost and
the artefacts, at the price of authoring and storage per step. **[CONVENTION]**

### Where snapping belongs in the pipeline

Rotation must be resolved to a discrete frame in the sprite's own unscaled
grid *before* the result is placed into the scene. Rotating a sub-pixel
accumulated position and then snapping the already-rotated pixels
re-introduces exactly the jaggedness the algorithm exists to avoid. The
correct order is: pick or generate the rotated frame at a fixed angle step,
run translation through the sub-pixel accumulator, then snap only the
placement position at composite time. Angle snapping and position snapping are
separate concerns and must not be merged into one interpolation.
**[INFERENCE, consistent with the existing accumulator design]**

## 5. Air and medium

Drag torque opposing spin scales with the square of angular velocity, because
the local speed varies with radius:

```
tau_drag ~ -(1/2) * C_d * rho * A * v_tip^2 * r     (integrated along the blade)
```

**[MEASURED, standard aerodynamics]**

So spin decay is front-loaded: fast early loss, slower bleed afterwards, not a
linear ramp. Over a throw lasting half a second to a second the real effect is
small; this is an optional refinement, not a requirement. **[INFERENCE]**

Visual conventions for cutting the air: **[CONVENTION]**

- **Speed lines**: straight, radiating, placed *behind* the moving tip and
  roughly parallel to travel, never overlapping the leading edge.
- **Crescent slashes**: the arc trail itself, thickness and opacity
  concentrated at the leading tip and tapering at the trailing end.
- **Wake lines**: thinner and curved, hugging the tip's actual traced path
  rather than radiating independently, implying air rushing into the void the
  blade left. Used for heavier, more powerful-reading swings.

All three key off the tip's traced path — the same curve sampled for the trail
— rather than off the weapon's body, and appear at or after peak speed, fading
over two to four frames.

## 6. What this means for a procedural engine

**Per weapon archetype**

- `pivot_offset` — distance from the grip to the weapon's centre of mass; this
  is what encodes the axe-against-sword difference.
- `effective_inertia` — a relative scalar scaling wind-up duration and capping
  peak angular speed. A table entry per archetype, not a live computation.
- `blade_length` (`r_max`) and `r_min` — needed for both tip speed and the
  swept-sector area.

**Per throw**

- `target_rotation_count` (1.0, 1.5, 2.0 revolutions) — the designer-facing
  control. Angular velocity is derived from it and the flight time, never set
  directly.
- Launch speed and angle, which the existing arc tooling already covers.

**Per swing**

- An asymmetric easing curve: wind-up duration, the position of peak angular
  velocity relative to the impact frame (at or just before, never after),
  overshoot angle, and follow-through decay.

**Trail and effects**

- `trail_lifetime` in seconds, so length scales with speed automatically.
- Start and end width, derivable from `r_max - r_min` rather than set
  arbitrarily.
- Colour gradient and alpha over life.
- A rendering mode switch per weapon or per move: sampled-tip ribbon,
  authored crescent sequence, or single smear swap. Pixel art prefers the
  authored crescent, so this is not one-size-fits-all.
- Afterimage spawn interval and per-ghost fade, if ghosts are used for dashes
  separately from the blade trail.
- Speed and wake line count, length, offset from the tip path and fade, gated
  on a tip-speed threshold so slow moves are not cluttered.

**Rotation pipeline, a hard constraint**

- Display rotation should use a fixed pre-computed angle-step set generated by
  a RotSprite-equivalent pipeline, not arbitrary live rotation.
- Angle-step selection happens *before* the sub-pixel translation accumulator
  runs. The two snapping steps must stay separate.

## Sources

Lehman, "Rigid Body: Translation and Rotational Motion Kinematics"; MIT
8.01SC, "Two Dimensional Rotational Kinematics"; Wikipedia, "List of moments
of inertia"; HyperPhysics, "Moment of Inertia: Rod"; Wikipedia, "RotSprite"
and "Pixel-art scaling algorithms"; `aseprite/src/doc/algorithm/rotsprite.cpp`;
Xenowhirl's original RotSprite release (Internet Archive); Aseprite
documentation, "Rotate"; Aseprite issue 121; Everest Forge, "Understanding
Sword Balance"; Wikipedia, "Throwing axe"; Unity scripting and manual
documentation for `TrailRenderer`; Stride3D, "Ribbons and trails"; Wikipedia,
"Smear frame"; TV Tropes, "Sword Lines"; jasontomlee, "Slash Shape
Fundamentals"; assorted afterimage implementation write-ups; annulus sector
geometry references.
