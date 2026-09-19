# Research 08 — The Medium Around a Fast Body

*Date: 2026-09-19 · Purpose: what actually happens in the air around a fast
body, and how to turn that into pixels and into metadata. Extends research 04,
which surveyed effect anatomy; this pass supplies the physics underneath it.*

Tags as in research 06: **[MEASURED]**, **[CONVENTION]**, **[INFERENCE]**.

## 1. Pressure, shock, and the thing people actually mean by "sonic boom"

Below Mach 1 there is **no shock discontinuity**. The flow is continuous: air
compresses and decelerates toward a stagnation point ahead of the body
(pressure rise of about `0.5 * rho * v^2`, from Bernoulli), and separates
behind it into a recirculating low-pressure wake with reverse flow toward the
body. Trailing turbulence belongs there; a shock ring does not. **[MEASURED]**

A true shock exists only once local flow exceeds Mach 1. For a supersonic
body, a curved detached bow shock forms ahead of a blunt nose and a conical
oblique shock from a slender one. The Mach cone half-angle is:

```
mu = arcsin(1 / M)
```

narrowing as speed rises. A sonic boom is that cone's pressure discontinuity
sweeping across an observer, with an N-shaped pressure-time signature — a
sharp rise, a decay through zero, a sharp return — not a single pulse.
**[MEASURED]**

**The vapour cone photographed around transonic aircraft is a different
phenomenon** and is what most people picture when they say sonic boom. Local
flow over curved surfaces accelerates past Mach 1; the accompanying pressure
and temperature drop pushes humid air below its dew point and condenses a
visible cloud. It needs humidity and occurs only in a narrow band around Mach
0.9 to 1.1. The commonly repeated "Prandtl-Glauert singularity" explanation is
a popularised misnomer — that term names an artefact of a linearised
transformation that is invalid near Mach 1, not the cause of the cloud.
**[MEASURED]**

### What this means for this product

Character dash and punch speeds are nowhere near Mach 1, so Mach cone geometry
is physically inapplicable to ordinary attacks. Games draw a ring for any
strong impact because audiences pattern-match to the vapour cone photograph,
not because the depicted body is supersonic. **[CONVENTION]**

**The physically correct analogy at these speeds is a miniature blast wave,
not a Mach cone.** True cone geometry is worth keeping, but only for a move
that is *declared* supersonic, where the Mach number is an authored design
parameter feeding the real formula rather than something inferred from a dash.
**[INFERENCE]**

## 2. The expanding ring

The Sedov-Taylor point-explosion solution gives the shock radius:

```
R(t) = xi * (E0 / rho0)^(1/5) * t^(2/5)        xi ~ 1.15 for gamma = 5/3
dR/dt ~ t^(-3/5)
```

**The front decelerates continuously. Radius grows as `t^0.4` — not linearly,
not as a square root.** Most of the ring's travel happens early; growth
visibly flattens well before the ring's life ends. **[MEASURED]**

Overpressure at a fixed point as the front passes follows a Friedlander
waveform:

```
P(t) = P0 * (1 - t/td) * exp(-b * t/td)
```

a rapid rise, a linear-times-exponential decay, then a negative suction phase.
For weak far-field blasts peak overpressure falls roughly as `1/r`; the strong
near-field falls faster. **[MEASURED]**

### The cheap approximation

At sprite-scale radii of 8 to 40 pixels, a literal `1/r` or steeper falloff
makes the ring vanish almost immediately and read as nothing. For a handful of
frames: **[INFERENCE]**

- `radius(frame) = R_max * t_norm^0.4`, with `t_norm = frame / total_frames` —
  this captures the deceleration without solving anything.
- Ring thickness held constant at 2 to 4 pixels; real shell thickening
  relative to radius is slow enough to ignore at this scale.
- Brightness and opacity faded with a plain ease-out such as `1 - t_norm^2`
  rather than the real decay law. This is a deliberate legibility departure
  from physics and is recorded as such, not presented as a physical claim.

## 3. Displaced ground

Without drag, a 45-degree launch maximises range. With realistic quadratic
drag the optimum shifts to about 35-38 degrees and range drops by roughly 40
percent for typical particle sizes. Small, light particles are pushed toward
higher ejection angles — up to about 15 degrees above the nominal cone near
the contact point — because their drag-to-mass ratio scales unfavourably.
**[MEASURED]**

Particles cluster near the contact point because the driving impulse is
concentrated there and because ejecta density falls off with radius from it.
An emitter should bias particle count inversely with launch radius rather than
sampling uniformly in an annulus. **[INFERENCE]**

No closed-form trajectory exists under quadratic drag. Over ten to twenty
frames of hang time the visible effect of drag is minor next to gravity, so an
undamped parabola integrated per frame is an acceptable simplification; add
drag only when hang time needs visibly shortening. **[INFERENCE]**

The large particle counts quoted in general effects material describe
continuous camera-facing systems at high resolution. A pixel art dust puff
reads with **4 to 8 discrete chunks** plus one or two persistent smoke blobs.
More than that muddies a low-resolution silhouette rather than reading as more
dust. **[INFERENCE]**

## 4. Directional against radial

This follows directly from bow wave against wake. Compression exists only on
the leading face; the low-pressure separated wake trails behind. So a **dash**
effect must be **asymmetric** about the direction of travel: compression and
streak lines only on the leading edge, afterimage and wake dust trailing and
lagging, oriented along the velocity vector. **[MEASURED physics, INFERENCE
for the visual mapping]**

An **impact** deposits energy effectively at a point with no preferred
direction once thermalised — which is the actual justification for the
spherical symmetry in the Sedov-Taylor solution — so impacts stay radially
symmetric and are never elongated. **[MEASURED]**

For a body-anchored effect, the anchor offset must come from the body's actual
per-frame velocity, taken as the difference between sampled positions, not
from static sprite facing. Under eased motion the trailing offset should lag
more during fast segments and less during slow ones, and only the real
per-frame displacement gives that. **[INFERENCE]**

## 5. Timing, and deriving it from the motion

Representative figures: **[MEASURED / CONVENTION]**

| Element | Figure |
| --- | --- |
| Hitstop, light attack | about 9 frames at 60 fps (~150 ms) |
| Hitstop, medium | about 11 frames (~183 ms) |
| Hitstop, heavy | 13-15 frames (~217-250 ms) |
| Broader game-feel guidance | a 60-120 ms band; longer reads as lag, not impact |
| Flash | about 60 ms |
| Camera field-of-view punch | plus 4-8 degrees, decaying with a ~200 ms time constant |

Screen shake, following Eiserloh's GDC treatment: a scalar *trauma* in the
range zero to one; shake magnitude is `trauma^2` or `trauma^3`, so trauma of
0.3, 0.6 and 0.9 gives roughly 3, 22 and 73 percent of maximum shake; trauma
decays linearly; the offsets are driven by Perlin noise per axis rather than
raw randomness, so the motion stays smooth and composes correctly with hitstop
and slow motion because it is sampled by simulation time. **[MEASURED]**

### The canonical ordering at a contact frame

1. Flash and particle spawn fire on the exact contact frame.
2. Hitstop begins the same frame, held for a duration scaled to hit weight.
3. Shake trauma is injected at hitstop start, so the decaying shake plays
   through and past the unfreeze.
4. Knockback is applied only once the freeze ends, so the freeze reads as the
   impact being absorbed before the body moves.
5. Recovery and settle over the following 100-300 ms.

**[CONVENTION]**

### The coupling that makes this a model rather than a table

None of these numbers should be authored per animation. Peak velocity and
acceleration at contact — already computable from the sampler — should scale
hitstop duration, shake trauma, flash intensity, and the blast energy that
sets the ring's maximum radius through the Sedov-Taylor relation. This is the
mechanism by which effects come out of what is physically happening instead of
out of a lookup table. **[INFERENCE, and the central architectural point of
this research]**

## 6. Drawing it without alpha

The midpoint circle algorithm, a generalisation of Bresenham's, is
integer-only, plots one octant and mirrors it eight ways, and applies no
anti-aliasing. It is the correct primitive here. **[MEASURED]**

Naive point-plotting for a thick ring — running the algorithm at three radii
and unioning the points — leaves gaps at small radii, because octant symmetry
breaks down when adjacent radii round to the same or skipped pixels. More
reliable at sprite scale: rasterise two **filled** disks and take the pixel-set
difference. This gives a gap-free ring of exact thickness at any radius.
**[INFERENCE, practical]**

Ordered (Bayer matrix) dithering is temporally stable because its threshold
pattern is fixed in screen space: a given opacity always dithers to the same
spatial pattern frame after frame. Error diffusion propagates quantisation
error spatially and is sensitive to tiny inter-frame differences, producing
visible crawl in motion. Ordered dithering is the standard choice specifically
for animation stability, at the cost of needing a small uniform palette —
which a sprite's palette already is. **[MEASURED]** This confirms the choice
already recorded in the stack document.

Ordered dithering is therefore the substitute for alpha on an indexed ring or
flash: map the desired opacity through the threshold map to decide per pixel
whether to draw the effect colour or leave the background. A fading ring
without ever creating a colour outside the existing palette. Every emitted
pixel must be an index already present, ideally reusing the character's own
highlight and shading ramp — never a computed blend, which an indexed cel
cannot represent anyway and which reads as a foreign overlay. **[INFERENCE]**

## 7. What must never be drawn

Screen shake, hitstop duration, camera punch, knockback impulse and haptic
triggers are camera and simulation-layer effects, not sprite-layer effects.
Baking them into pixels is wrong for any consumer whose camera or physics
differ from those assumed at generation time — a shake tuned for one viewport
is wrong for another. **This is a hard split, not a style preference.**

They ship as per-frame events:

```
{frame: 6, type: "hitstop",  duration_ms: 90}
{frame: 6, type: "shake",    trauma: 0.6}
{frame: 6, type: "knockback", impulse: {x, y}}
{frame: 6, type: "flash",    color, duration_ms: 60}
```

Two shipping formats are viable: a sidecar file, or — native to this editor —
per-cel and per-tag user data embedded directly in the sprite file, which
keeps the metadata beside the frames it describes without a second file. The
second is worth preferring where it fits. **[INFERENCE]**

## 8. What this means for a procedural engine

| Parameter | Derived automatically, or set by hand |
| --- | --- |
| Blast energy, which sets ring radius and brightness | **Auto** from peak contact velocity and relative momentum |
| Ring radius-over-time exponent | **Fixed constant** at 0.4, from Sedov-Taylor; never per effect |
| Ring thickness | Manual preset, 2-4 pixels, constant across the animation |
| Ring opacity falloff | Manual shape (ease-out); its duration **auto**-scaled to energy and hitstop |
| Dash asymmetry, leading against trailing | **Auto** from the velocity direction; never symmetric |
| Dust particle count | Manual preset of 4-8; launch angle spread **auto** from the impulse direction |
| Effect anchor offset per frame | **Auto** from the sampler's per-frame displacement; never a static rig point |
| Hitstop duration | **Auto** from peak acceleration, clamped to a manual 60-120 ms band |
| Screen shake trauma | **Auto** from the same severity scalar that sets blast energy; the exponent is a manual preset |
| Flash duration and intensity | **Auto**-scaled, clamped to a manual band around 60 ms |
| Knockback impulse | **Auto** from momentum, applied only after hitstop |
| Mach cone geometry | Only for an explicitly supersonic move; the Mach number is then authored, never inferred |
| Palette indices used by effects | Manual — a fixed subset of the sprite's existing ramp, never synthesised |
| Dithering method | Fixed constant: ordered, never error diffusion |

## Sources

Sedov-Taylor blast wave and Friedlander waveform references; standard
compressible flow and Mach cone geometry; transonic vapour cone and the
Prandtl-Glauert misnomer; impact ejecta launch-angle studies under quadratic
drag; Squirrel Eiserloh, "Juicing Your Cameras With Math" (GDC); fighting-game
hitstop frame data; midpoint circle algorithm references; ordered against
error-diffusion dithering in animation.
