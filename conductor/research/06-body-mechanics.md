# Research 06 — Body Mechanics for Procedural Action Animation

*Date: 2026-09-19 · Purpose: the model behind a body that throws itself
forward, and what survives of it at pixel art resolutions.*

Every claim carries a tag: **[MEASURED]** a numeric value from the
literature, **[CONVENTION]** animation industry practice rather than a
physical measurement, **[INFERENCE]** synthesis where no source gave a
number. Where something could not be verified, it says so instead of
reading as fact.

## 1. Biomechanics of explosive movement

### 1.1 Countermovement and coil

- The countermovement jump's force-time curve has named sub-phases:
  **unweighting** (ground reaction force drops below body weight as the body
  starts to drop), **braking/eccentric** (force rises back above body weight
  while the joints keep flexing, decelerating the downward centre of mass),
  then **propulsion/concentric** (force above body weight while the joints
  extend) to take-off. **[MEASURED]** — McMahon et al., "Understanding the Key
  Phases of the CMJ Force-Time Curve"; JSCR, "Phase Characteristics of the
  CMJ".
- Knee flexion depth: 70 degrees produced significantly greater jump
  performance than 90 degrees, with different muscle groups dominant at each
  depth (quadriceps-dominant shallower, hip and glute-dominant deeper).
  **[MEASURED]**
- Countermovement depth is normalised in the literature to trochanteric
  displacement over femur length — depth scales with **leg segment length**,
  not with a fixed fraction of standing height. Self-selected squat depth
  correlates strongly with jump height (r = 0.72). **[MEASURED]**
- No source gave a clean "the coil lasts X milliseconds" figure. General
  countermovement literature puts unweighting plus braking around 300-500 ms,
  but that was not verified in this pass. **[INFERENCE, flagged]**

The takeaway for an engine: the coil is knee *and* hip flexion together, its
depth scales with leg length rather than body height, and it gets shorter and
shallower the more urgent the action — the opposite of an unhurried squat.

### 1.2 Push-off

- The proximal-to-distal sequence is confirmed by electromyography and by the
  timing of peak angular velocities: hip extensors fire first, knee extensors
  next, ankle plantar flexors last. **[MEASURED]**
- In sprint starts, peak joint power follows the same order, and the front
  leg's ankle and knee power window occurs *after* the rear foot has left the
  block. Segments hand off; they do not extend together. **[MEASURED]**
- Better starts correlate with force that is both higher and more
  horizontally directed early in the push, not merely larger. **[MEASURED]** —
  Colyer et al.

### 1.3 Travel

- Torso lean during the acceleration phase is roughly 40-50 degrees from
  vertical in the first steps, rising toward upright as maximum velocity is
  reached. **[MEASURED]**
- The timing of the transition from leaning to upright predicts acceleration
  quality on its own, not just the final angle. **[MEASURED]**
- In steady-state running, extra lean beyond natural posture (up to about 8
  degrees) worsens running economy by about 8 percent. Large sustained lean is
  specific to acceleration; it is not a travel pose. **[MEASURED]**
- Gait proportions: walking is about 60 percent stance and 40 percent swing
  per leg; running inverts this to roughly 40 and 60. **[MEASURED]**

### 1.4 Landing and arrest

- The first 100 ms after contact is the critical energy-absorption window.
  **[MEASURED]**
- Knee flexion in the first 50 ms sets the absorption strategy. By 95-200 ms,
  reduced knee flexion correlates with less absorption capacity, forcing ankle
  plantarflexion to compensate. **[MEASURED]**
- Absorption is either knee-dominant (softer, more knee travel) or
  hip and ankle-dominant (stiffer) — two legitimate landing voices. One study
  measured about 69 percent more knee energy absorption and about 36 percent
  less hip stiffness in one strategy against the other. **[MEASURED]**
- No source gave overshoot and settle frame counts for a landing; the general
  animation convention in section 2 stands in for it.

### 1.5 Striking

- The canonical sequence is weight shift (rear foot pivot), hip rotation,
  shoulder and torso rotation, arm extension, fist. Each segment's peak
  velocity follows the previous segment's — the summation of speed principle:
  mass decreases and velocity increases at each link. **[MEASURED]**
- Timing: in one kinematic study the upper-body chain began after 80 percent
  of the total punch duration. The lower body occupies the first four fifths;
  the arm's distinct contribution is compressed into the final fifth. This is
  the measured basis for the long wind-up and instant snap that fighting games
  use by convention. **[MEASURED]**
- Novices rely on local shoulder muscle for up to about 29 percent of a cross
  against about 15.6 percent for elite athletes. A weak or telegraphed punch
  reads as arm-only; a trained one reads as hip-first. **[MEASURED]**
- Elite fighters show pronounced pelvis-leads-thorax separation before the
  shoulders release. **[MEASURED]**
- Retraction is trained to be faster than extension — the common coaching
  heuristic is about twice the throw speed — and the retraction path is not
  the mirror of the strike path. **[CONVENTION]**

## 2. What animators do instead of simulating

- The three-beat structure is **anticipation, key pose, follow through**
  (Williams, *The Animator's Survival Kit*), reframed in games as **startup,
  active, recovery** and treated as gameplay-critical: startup is the only
  signal that a hit is coming, recovery the only signal that the character is
  vulnerable again. **[CONVENTION]**
- Do not tween linearly into or out of a recovery or idle pose. Hold the
  extreme as long as affordable, then cut fast. Smooth interpolation across a
  state boundary reads as an ambiguous state. **[CONVENTION]**
- Strong keys carry an animation more than frame count does; fewer,
  better-chosen transition frames read as more powerful than smooth
  interpolation. Smears extend a fast part's silhouette across its swept path
  rather than being true motion blur. Attributed to Mariel Cartwright's
  Skullgirls talks; only summaries were reachable in this pass, so this is
  recap-sourced rather than quoted. **[CONVENTION]**
- Overshoot and settle after a fast stop is a decaying oscillation: arrive,
  overshoot, settle, each bounce smaller and faster-decaying — a damped
  spring. **[CONVENTION]**
- Squash and stretch is a volume-conserving scale pair. The practical extreme
  ratio cited is about 2:1 on the long axis against the short; engines default
  to no deformation and opt in per pose. Traces to Lasseter, "Principles of
  Traditional Animation Applied to 3D Computer Animation" (1987).
  **[CONVENTION]**
- Anticipation amount has no fixed number anywhere. It is described
  functionally — long enough to telegraph, short enough not to stall — so it
  is per-project tuning, not a constant. **[CONVENTION, unquantified]**

## 3. Part-based rigs

- Spine and DragonBones build a bone hierarchy in which a child's world
  transform is the parent's transform composed with its local bind-pose
  transform, and attach flat images to bones rather than simulating a
  skeleton. **[MEASURED, tool documentation]**
- The standard decomposition is head, torso, hip or pelvis (often separate
  from the torso so it can rotate independently), upper arm, forearm with
  hand, thigh, shin with foot. Each part's pivot sits at its proximal joint so
  a parent's rotation carries the chain. **[CONVENTION]**

### Closed-form two-link inverse kinematics

Given an upper segment of length `a`, a lower segment of length `b`, and a
target at distance `c` from the root, with `c` clamped to
`|a - b| <= c <= a + b` so a solution exists:

```
theta_elbow  = acos((a^2 + b^2 - c^2) / (2*a*b))
theta_offset = acos((a^2 + c^2 - b^2) / (2*a*c))
root_angle   = atan2(target.y - root.y, target.x - root.x) +/- theta_offset
```

The sign on `theta_offset` selects elbow-forward against elbow-back — the
pole vector choice every two-bone solver exposes as an explicit parameter.
This is the same solution Unity, Spine, DragonBones and Blender's two-bone
constraint all reduce to. **[MEASURED, standard result]**

What breaks below about 30 pixels of segment length: the bend-direction
choice becomes visually ambiguous, because the silhouette difference between
the two solutions can be one or two pixels and is erased by pixel snapping.
The closed-form solver carries no joint limits, so it must be clamped
externally or it will bend a knee backwards. **[INFERENCE]**

## 4. What survives at 32 to 64 pixels

- At 32 by 32, a full walk cycle conventionally runs 4-6 frames — "four works,
  six is luxurious". That caps how many distinct intermediate poses a
  procedural system can usefully spend. **[CONVENTION]**
- Most pixels do not move between frames. The workflow is to duplicate the
  base frame and redraw only what changed — which is cutout-rig thinking even
  in hand-drawn work. **[CONVENTION]**
- **Rotation is the failure case.** Rotating a small region by a non-square
  angle produces jagged results even with nearest-neighbour sampling. The
  standard mitigation, an eightfold upscale, rotate and requantise, is
  expensive for full runtime use. Below some size threshold practitioners
  state plainly that a rotated limb cannot be produced without ruining the art
  and must be redrawn by hand. **[MEASURED practitioner testimony +
  CONVENTION]**
- Transformations that survive pixel snapping: integer translation, mirroring,
  quarter-turn rotation, integer-factor scaling, and shear only when expressed
  as a per-row or per-column integer offset table rather than a true affine
  shear. **[INFERENCE, synthesised — no source gave this as a checklist, but
  it follows from why rotation fails.]**
- Transformations that do not survive: small-angle rotation below a few dozen
  pixels, and non-integer scaling. Both introduce sub-pixel interpolation,
  which is incompatible with hard-edged palettes. **[INFERENCE]**

### The consequence that matters most for this project

At 32 pixels of character height, thigh and shin are roughly 8-14 pixels each.
A biomechanically scaled knee-flexion coil would drop the hip by **one to
three pixels**. That is why pixel artists conventionally exaggerate coil depth
far past anatomical proportion, or fake it with a whole-torso silhouette
change — widening the stance and tucking down as one rigid unit — rather than
articulating angles that resolve to sub-pixel motion. **[INFERENCE]**

At 64 by 64 the segments roughly double to 16-28 pixels, which is near where
the small-angle rotation problem begins to ease. Still marginal, not
comfortable. **[INFERENCE]**

## 5. Motion catalogue

Sixty frames per second. Every frame count is a starting default synthesised
from the phase order above, not a physical constant; no source gives a
universal table. **[CONVENTION / INFERENCE]**

| Motion | Phases and frames |
| --- | --- |
| Forward dash | coil 3-5 (weight sinks back, knee and hip flex, slight backward lean); launch 2-4 (proximal-to-distal extension, torso snaps to forward lean); travel (duration-driven; trailing leg tucks, lean reduces, arms drag); arrest 3-6 (landing-style absorption, settle with overshoot) |
| Back dash | mirrors the forward dash with shorter travel and no forward-lean state; the character stays facing the threat, reading as retreat rather than a turned sprint |
| Jump | coil 3-6; takeoff 2-3; ascent (variable, legs may tuck); apex 1-2 held slightly longer than the physical time at apex for readability; descent (variable); landing impact plus 3-6 absorption plus settle |
| Punch | anticipation 2-4 (weight and hip shift); strike 1-2 (hip, shoulder, arm staggered even inside one or two frames); optional smear 0-1 at full extension; retraction 1-2, roughly twice the strike speed; recovery 2-4 |
| Teleport | optional anticipation 2-4; vanish 1-3 collapsing inward rather than fading uniformly; transit gap with effects only; reappear 1-3 rushing inward in mirrored language; settle 2-3 |
| Hurt and knockback | impact 1, no anticipation (the hit is the anticipation); knockback travel (variable; body rigid and arched away, often one held pose translated rather than re-articulated); arrest as for a landing; recovery, often deliberately long for gameplay reasons independent of the visual settle |
| Dodge roll | startup 2-4, still vulnerable; active (variable, tucked low; literal rotation survives only in quarter-turn steps, so most sprite rolls fake it with squash and tuck); recovery 2-4 |
| Landing | impact, absorption dip of about 100 ms, overshoot and settle |
| Wind-up | longer than a normal anticipation, and a moving hold rather than a static freeze so it does not read as frozen |
| Slam | the inverse of a jump: optional ascent and hang, fast proximal-to-distal downward extension with the weapon or arm leading, a single smeared impact pose, then a recovery longer than a punch's |

## 6. What this means for a procedural engine

1. **Segment lengths as fractions of character height**, never hardcoded
   pixels; coil depth and inverse kinematics targets key off leg and torso
   ratios.
2. **Independent per-phase durations.** Every source treats these as
   separately tunable rather than derived from one constant.
3. **A proximal-to-distal stagger parameter** — a per-joint onset delay so the
   hip extends before the knee before the ankle, instead of one shared easing
   curve driving every joint together. This is the single parameter that most
   separates a body throwing itself from an image sliding.
4. **Coil depth as a knee and hip angle pair plus a proportional centre-of-mass
   drop**, with an exaggeration multiplier and a minimum-readable-pixel floor,
   because literal scaling resolves to one to three pixels at this resolution.
5. **A two-bone closed-form solver** taking segment lengths, a target and an
   explicit bend-direction sign — never inferred, because at these sizes the
   two solutions look nearly identical.
6. **Joint limits enforced after the solve**, since the closed form has none.
7. **A snap gate on every rotation**, routing through a quarter-turn table, a
   pre-baked rotated asset, or a hand-drawn fallback, with continuous
   small-angle rotation disallowed below a configurable segment size.
8. **Volume-conserving squash and stretch** with a configurable ceiling around
   2:1, applied at pose keys rather than continuously.
9. **A retraction speed multiplier** independent of and faster than extension,
   defaulting to about twice, rather than a mirrored ease.
10. **A generic overshoot and settle state** — amplitude and decay rate —
    applicable after any hard stop rather than hand-tuned per motion.
11. **Phase-dependent torso lean**, large during coil and launch, near upright
    during steady travel.
12. **A named phase state machine per motion** as the top-level authoring
    structure. Every source organises actions this way and none as a single
    continuous curve. This is the structural gap between what exists today and
    what a body doing an action requires.

## What this pass could not establish

- An exact duration for the coil phase; only a flagged inference.
- The Skullgirls talks were reachable only as summaries, not transcripts.
- No measured threshold exists for a "minimum readable silhouette change" in
  pixels; section 4's guidance is inference from the walk-cycle convention.
- No universal frame-count table exists for section 5; every number there is a
  starting parameter.
