# Track 2 — Rig and Draw List

## Closing Condition

> On a character whose parts are marked, the arm rotates about its shoulder
> while the body translates, and the produced animation is watched frame by
> frame. The same code path, run on a character with no parts marked, produces
> the existing single-part dash unchanged. The rotation method is chosen by
> measuring three candidates against each other, and the decision is written
> down with the evidence that produced it.

Source: set by the operator. A partly-met closing condition is not closure.

## Overview

Track 1 proved the chain from a menu command to real frames. What it moves is
one unchanged image along an axis, so the character reads as a paper cut-out
sliding across a table — which is exactly what it is.

This track gives the engine a body. A character becomes a tree of named parts
with pivots; a pose becomes a transform per part; and the contract between the
core and the application stops being a list of offsets and becomes a
declarative draw list that can express deformation, procedural pixels and
layer placement.

No motion model ships here. Phase timelines, springs, inverse kinematics and
squash and stretch belong to the track that follows. What ships is the
structure they will all be expressed in, plus the one capability that
structure is useless without: the ability to rotate a small sprite without
destroying it.

## Two findings this track is built on

**The application cannot rotate an image from a script.** Verified against its
source before this track was planned. The resize method whose name mentions
RotSprite is a scaling filter; the rotate command reachable from a script
handles quarter turns only and acts on the whole sprite; the arbitrary-angle
routine exists in C++ and is not exposed. Rotation is therefore written in the
core layer, which is where it can be tested with no application running.
Recorded in `conductor/tech-stack.md` and in the correction note in
`conductor/research/03-motion-math.md`.

**A rig has a native home.** A slice carries a name, a rectangle and a pivot,
and namespaced properties. A body part is exactly that. So the rig is not a
new file format and not hidden state: the artist marks parts with the editor's
own tools and the extension reads them, which is what
`conductor/product-guidelines.md` requires of every step.

## Functional Requirements

1. **A pixel matrix.** A plain structure of width, height and pixel values,
   with read, write, blit and bounds-shrinking. This is the currency between
   the core and the adapter; the adapter fills it from a cel and writes it
   back in bulk rather than pixel by pixel.

2. **Raster transforms, all pure.** Translation, mirroring, shear expressed as
   integer per-row offsets, rotation by inverse mapping, and an edge-aware
   enlargement. **No transform may invent a colour**: every output pixel is a
   value that was already present in the input.

3. **The rotation decision, measured.** Three candidates rendered on the same
   part at the same angles and compared by looking at them: enlarge-rotate-
   reduce, quarter-turns-and-mirrors only, and a pre-computed fixed angle set.
   The winner and the evidence are written into the stack document.

4. **A part provider contract.** One shape consumed by everything downstream:
   a list of parts, each with a name, a rectangle, a pivot, a parent and a
   role. Two suppliers in this track: the artist's slices, and a fallback that
   returns one part covering the whole drawing. A third supplier working the
   parts out from the silhouette is a later track and must need no change
   above this line.

5. **A part tree with forward kinematics.** A parent's transform composes into
   its children, so rotating a shoulder carries the arm with it. Cycles and
   missing parents are rejected with a message naming the part.

6. **A draw list.** Per frame: a duration, and a list of instructions saying
   which source rectangle is drawn, under which transform, onto which layer.
   A validator refuses an instruction it cannot draw rather than skipping it
   silently.

7. **The adapter as an interpreter.** It stops taking offsets and executes a
   draw list, keeping both guarantees unchanged: the artist's artwork is never
   modified, and one undo removes the whole result.

8. **The existing motion, unchanged.** A path becomes a one-part draw list, so
   the demonstration dash is produced through the new machinery and proven
   identical to what it produced before.

9. **A rigged sample character.** Generated deterministically like the current
   one, with parts marked and pivots set, small enough to stay a fixture.

## Non-Functional Requirements

- **Determinism.** The same inputs produce the same pixels, every time.
- **Palette integrity.** No transform emits a colour that was not in its
  input. This is stricter than "looks right" and is testable.
- **Non-destructive.** Everything produced is removed by a single undo; source
  cels are never written to.
- **Pixel integrity.** Positions are whole numbers; the sub-pixel accumulator
  keeps displacement from drifting.
- **The core stays pure.** Rotation, rasterisation and the part tree all live
  where the boundary check can see them.
- **Speed.** Producing a short animation on a character of a few thousand
  pixels finishes fast enough to sit behind a menu command without a progress
  bar.

## Acceptance Criteria

1. A character with marked parts produces an animation in which the arm
   rotates about its shoulder while the body translates, watched in full.
2. A character with no marked parts produces the existing dash, proven
   identical to the frames the previous implementation produced.
3. The rotation comparison exists as a rendered sheet, and the stack document
   records which candidate won and why.
4. Every transform is proven to emit only colours present in its input.
5. A malformed rig — a missing parent, a cycle, a pivot outside its rectangle
   — is refused with a message naming the part, not drawn incorrectly.
6. The adapter's single-transaction and single-undo guarantees still hold,
   proven by the suite that runs inside the application.
7. Lint, format, core tests, coverage and the boundary check are green locally
   and on the remote.

## Out of Scope

Phase timelines, springs, inverse kinematics, squash and stretch, smears,
trails, weapons, effects of any kind, the metadata export, parameter dialogs,
working the parts out from the silhouette automatically, and the pixel art
converter.

## Dependencies and Risks

- **Whether extension properties survive a save is unverified.** The API
  documentation does not say. If they do not, the parent and role move into
  the slice's own text field as a short encoded string. Checked in the first
  phase that touches slices, not assumed.
- **Rotation may fail at this scale for every candidate.** A limb is six to
  eight pixels; the research says practitioners redraw rather than rotate
  below a threshold. If the measurement rejects all three, the fallback is the
  artist supplying two or three extreme poses to interpolate between, which
  costs the load-and-press promise and is therefore a decision to bring back
  to the operator rather than to take quietly.
- **Pure-Lua rotation has unmeasured cost.** An enlargement of sixteen turns
  an eight-pixel limb into a canvas of a few thousand pixels per frame per
  part. Measured in the phase that builds it, with a recorded figure.
