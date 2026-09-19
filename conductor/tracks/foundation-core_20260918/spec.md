# Track 1 — Foundation and Mathematical Core

## Closing Condition

> From a clean checkout, a single command runs the mathematical core's tests to
> a passing report. The same checkout, installed into Aseprite, shows the
> extension's menu entry, and a batch script drives one core function inside the
> real Aseprite runtime and exits zero. Finally, when the extension is run on
> the bundled sample character, the motion produced by the core math can be
> watched as a multi-frame animation — the motion is seen, not inferred from
> test output.

Source: set by the operator. A partly-met closing condition is not closure.

## Overview

This track establishes the project skeleton, the pure mathematical core, and
the two-path proof mechanism every later track depends on: the same mathematics
runs once under a plain Lua interpreter for fast feedback, and once inside the
real Aseprite runtime to prove it actually works there.

No product capability ships here. What ships is the ability to prove that a
capability works.

The demonstration motion is deliberately the simplest one that exercises the
whole chain: the character accelerates and decelerates along a single axis
following an easing curve. Anticipation, squash and stretch, overshoot, smear
and trails belong to the motion engine track that follows.

## Functional Requirements

1. **Extension skeleton.** An extension manifest that registers a single menu
   entry and installs into Aseprite.

2. **Core layer with zero Aseprite references.** Pure Lua modules that never
   touch an Aseprite global:
   - easing curves (a Penner subset covering linear, quadratic, cubic, an
     overshoot curve and an exponential curve, each in in/out/in-out form where
     meaningful),
   - a sampler that turns a curve into per-frame normalized positions and
     non-uniform frame durations, including repeated hold frames at the
     extremes,
   - quadratic Bezier evaluation and a parabolic arc helper,
   - affine transform composition with pixel-grid snapping and a sub-pixel
     accumulator that carries rounding remainder forward,
   - a seeded, deterministic random source for later procedural work.

3. **Motion path producer.** Given a frame count, a displacement and a curve,
   returns per-frame integer offsets and durations as plain data, with no
   Aseprite involvement.

4. **Adapter.** Turns that data into frames, cels and a tag inside a single
   transaction, leaving the source layer untouched and undoable in one step.

5. **Demonstration.** A menu command that runs the producer and the adapter on
   the active sprite, plus a script that generates the bundled sample character
   so the demonstration does not depend on any external artwork.

6. **Test harness.** Unit tests for every core module under a plain Lua
   interpreter with coverage measurement, and an integration path executed by
   the real Aseprite binary, whose location is read from the `ASEPRITE_BIN`
   environment variable and never hardcoded.

7. **Layer boundary check.** An automated check that fails if the core layer
   references an Aseprite global, plus a test proving the check actually fails
   when a violation is introduced.

8. **Continuous integration.** A workflow on the public remote running lint,
   format check, core tests, coverage and the boundary check. Aseprite is not
   built in CI; runtime-dependent tests run locally.

9. **Tooling configuration.** Linter configuration declaring the Aseprite
   globals, and formatter configuration, both committed and both clean on the
   whole tree.

## Non-Functional Requirements

- **Determinism.** The same parameters produce the same frames; randomness is
  seeded and reproducible.
- **Non-destructive.** Everything the demonstration produces is removed by a
  single undo, and the source layer is never modified.
- **Pixel integrity.** Positions are integers on the pixel grid; the sub-pixel
  accumulator prevents accumulated rounding drift across frames.
- **No machine-specific values.** No absolute paths anywhere in the repository.
- **Language and style.** English throughout, no emojis, no hardcoded tunables.

## Acceptance Criteria

1. One documented command runs the core test suite green and reports coverage
   for the core above the target stated in the process document.
2. Lint, format check and the layer boundary check all pass on the whole tree.
3. The extension installs into Aseprite and its menu entry is visible.
4. A batch script drives a core function inside the real Aseprite runtime and
   exits zero.
5. Running the demonstration on the generated sample character produces a
   multi-frame animation that can be watched; the source layer is unchanged; a
   single undo removes the entire result.
6. The CI workflow is green on the public remote for the fast checks.
7. A search of the repository finds no absolute machine paths.

## Out of Scope

Pixel art conversion, the VFX layer, the preset library beyond the single
demonstration motion, the 2.5D tool, the sheet and anchor contract, packaging
and release, live canvas preview.

## Dependencies and Risks

- **The sheet contract belongs to the next track.** This track must not invent
  a sheet, anchor or metadata schema beyond what the demonstration strictly
  needs; doing so would pre-empt a decision the next track owns.
- **Coverage tooling must be confirmed to exist** for this Lua environment. If
  a working coverage tool cannot be installed, the target reverts to "every
  core module has tests" and the process document is amended in the same task,
  as the process document itself requires for deviations.
- **Live preview performance is unmeasured.** It is deliberately absent from
  this track; the risk it carries belongs to the track that introduces a dialog.
