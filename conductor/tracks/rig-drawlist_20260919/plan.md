# Implementation Plan — Track 2: Rig and Draw List

Every task follows the lifecycle in `conductor/workflow.md`: mark in progress,
write a failing test, implement the minimum to pass, refactor, verify
coverage, commit, attach the task summary as a git note, record the commit,
commit the plan update.

Every step below is a single action with an observable result.

## Phase 1 — The Pixel Matrix and the Transforms That Are Safe

- [x] Task: Pixel matrix `fca65c7`
  - [x] Write failing tests: a new matrix is uniformly the transparent value;
        reading outside the bounds returns the transparent value rather than
        failing; writing outside the bounds is ignored rather than growing the
        matrix; blitting one matrix into another lands at the offset asked
        for; shrinking to content returns the smallest rectangle holding a
        non-transparent pixel, and returns nothing for an empty matrix
  - [x] Implement the matrix
  - [x] Refactor and re-run

- [x] Task: Translation and mirroring `fca65c7`
  - [x] Write failing tests: translating by whole numbers moves every pixel
        and invents none; mirroring twice returns the original exactly;
        mirroring preserves the set of colours used
  - [x] Implement both
  - [x] Refactor and re-run

- [x] Task: Shear as integer row offsets `fca65c7`
  - [x] Write failing tests: each row is displaced by a whole number of
        pixels; no row is resampled, so the set of colours is unchanged; a
        shear of zero is the identity
  - [x] Implement the shear
  - [x] Refactor and re-run

- [x] Task: Colour conservation as a shared property test `fca65c7`
  - [x] Write a check, used by every transform's tests, that the output's set
        of colours is a subset of the input's
  - [x] Apply it to every transform written so far

- [x] Correction: A lean lost the rows that travelled furthest `1f3014f`
  - [x] Cause: the result kept the source's size, so at any lean worth having
        the rows furthest from the pivot ran off the edge and were dropped
        without a word
  - [x] Found by rendering the transforms inside the real runtime on the real
        sample and looking at them; the unit tests use pictures too small to
        run out of room
  - [x] Grow the frame and report where its left edge moved to

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `1f3014f`
  - [x] Visual verification: the transforms were rendered in the real runtime
        and the sheet was looked at

## Phase 1 complete [checkpoint: 1f3014f]

## Phase 2 — Rotation, Decided by Measurement

- [x] Task: Rotation by inverse mapping `580c902`
  - [x] Write failing tests: rotating by a quarter turn matches the exact
        expected pixels; rotating by zero is the identity; four quarter turns
        return the original; the rotated bounds are computed from the corners
        rather than assumed square; no colour is invented
  - [x] Implement the rotation
  - [x] Refactor and re-run

- [x] Task: Edge-aware enlargement `580c902`
  - [x] Write failing tests: every output pixel is copied from the source
        neighbourhood and never blended; a flat region enlarges unchanged; a
        diagonal edge gains the expected stepped corner; applying it twice
        gives four times the size
  - [x] Implement the doubling filter, applied repeatedly to reach a factor
  - [x] Refactor and re-run

- [x] Task: Reduction that picks rather than blends `580c902`
  - [x] Write failing tests: each output pixel is one of the values in the
        block it came from; ties resolve the same way every run, so the whole
        pipeline stays deterministic; a uniform block reduces to its own value
  - [x] Implement the reduction
  - [x] Refactor and re-run

- [x] Task: The rotation comparison `580c902`
  - [x] Build the three candidates over the same part: enlarge-rotate-reduce,
        quarter turns and mirrors only, and a pre-computed fixed angle set
  - [x] Render all three at the same angles, at a limb's real size, into one
        sheet
  - [x] Look at the sheet and decide
  - [x] Measure how long each takes for one part and record the figure
  - [x] Write the decision and its evidence into the stack document
  - [x] If every candidate is rejected, stop and bring the fallback back to
        the operator rather than choosing quietly (not needed: two candidates
        cleared the bar and one was chosen on cost)

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `580c902`
  - [x] Visual verification: the comparison sheet is looked at, not inferred

## Phase 2 complete [checkpoint: 580c902]

## Phase 3 — Parts, the Tree and Forward Kinematics

- [x] Task: The part contract and the whole-drawing supplier `89bafd0`
  - [x] Write failing tests: a drawing with nothing marked yields one part
        covering it, with the pivot at a documented place; the shape of a part
        is exactly what everything downstream expects
  - [x] Implement the fallback supplier
  - [x] Refactor and re-run

- [x] Task: Reading parts from the artist's slices `89bafd0`
  - [x] Confirm inside the running application whether extension properties
        survive a save (they do, including integer values, so the fallback to
        the slice's own text field was not needed)
  - [x] Write a runtime test that marks parts on a sprite, saves, reopens and
        reads them back
  - [x] Implement the reader
  - [x] Refactor and re-run

- [x] Task: The part tree `89bafd0`
  - [x] Write failing tests: children resolve under their parent; a missing
        parent is refused with the part named; a cycle is refused with the
        part named; a pivot outside its rectangle is refused
  - [x] Implement the tree
  - [x] Refactor and re-run

- [x] Task: Forward kinematics `89bafd0`
  - [x] Write failing tests: a parent's rotation carries its children; a
        child's own transform composes after its parent's; a two-level chain
        matches the transform computed by hand; the identity pose leaves every
        part where the artist drew it
  - [x] Implement the composition on the existing transform helpers
  - [x] Refactor and re-run

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `89bafd0`

## Phase 3 complete [checkpoint: 89bafd0]

## Phase 4 — The Draw List and the Adapter as Interpreter

- [x] Task: The draw list and its validator `9e2d2ef`
  - [x] Write failing tests: a well-formed list passes; an instruction naming
        a part that does not exist is refused; an instruction with no
        transform is refused; a frame with no duration is refused; the
        refusal names the frame and the instruction
  - [x] Implement the structure and the validator
  - [x] Refactor and re-run

- [x] Task: A path becomes a one-part draw list `9e2d2ef`
  - [x] Write failing tests: the translation produces exactly the offsets the
        path carried, with durations and holds preserved
  - [x] Implement the translation
  - [x] Refactor and re-run

- [x] Task: The adapter interprets a draw list `9e2d2ef`
  - [x] Write a failing runtime test expecting parts drawn under their own
        transforms onto the layers named, the source cel untouched, and one
        undo removing everything
  - [x] Implement the interpreter, keeping the single transaction
  - [x] Confirm reading a cel into a matrix and writing it back in bulk
        round-trips exactly

- [x] Task: The old demonstration, through the new machinery `9e2d2ef`
  - [x] Render the dash before and after and prove the frames are identical
  - [x] Keep that comparison as a regression check

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `9e2d2ef`

## Phase 4 complete [checkpoint: 9e2d2ef]

## Phase 5 — The Rigged Sample and the Closing Demonstration

- [x] Task: A rigged sample character `f7d539c`
  - [x] Extend the generator to draw a figure whose parts are separable and to
        mark them with pivots
  - [x] Confirm the file stays small and its palette known

- [x] Task: The demonstration command `f7d539c`
  - [x] Wire a motion that rotates one part while the body translates
  - [x] Run it on the rigged sample and watch every frame
  - [x] Run it on an unmarked character and confirm the old dash comes out

- [x] Task: Closing condition demonstration `f7d539c`
  - [x] Show the three proofs end to end: the arm rotating while the body
        travels, the unmarked character producing the old dash unchanged, and
        the rotation comparison with its recorded decision
  - [x] Present the result to the operator for the closure decision

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `f7d539c`
  - [x] Visual verification: the animation is watched in full

## Phase 5 complete [checkpoint: 8c3051d]

## Closure — Review Findings

The mandatory code review ran against the whole branch. The subagents raised
for it both stopped before executing anything, so the review was carried out
directly in the session that owns the track. Every finding below was verified
by running it, not by reading alone, and every correction carries a test that
fails without it.

- [x] Correction: A part reaching past the drawing invented pixels, silently
  - [x] Cause: the bulk read indexed the image's byte buffer without checking
        the rectangle lay inside it. Indexing a string from before its start
        counts backwards from its end in this language, so the read did not
        fail - it returned real bytes from the far side of the picture and
        assembled them into colours the drawing never held
  - [x] Reachable from ordinary use: parts are marked in the sprite's
        coordinates while a cel holds only the pixels drawn on, so a rectangle
        with any margin around a limb starts outside the cel it is cut from
  - [x] Why no test caught it: the bridge was only ever asked for the whole
        image or a window strictly inside it. The same shape as the lean that
        lost its rows - an input too small to reach the case
  - [x] Answer nothing outside the image, which is the answer the matrix
        already gives to the same question
  - [x] Test it in every colour mode, on all four sides and across a corner

- [x] Correction: The validator passed an instruction drawing on a layer the
      list never declares
  - [x] Cause: the layer was checked for being a name, not for being one of
        the names the list declares. The adapter creates exactly the declared
        layers and looks each instruction up among them, so such an
        instruction draws nowhere
  - [x] Not reachable from today's builders, which declare the one layer they
        use; it is a gap in the refusal this module exists to make
  - [x] Refuse it, and refuse a list that declares no layer at all

- [x] Correction: The enlargement accepted factors that would not enlarge
  - [x] Nought and a negative fell past the doubling loop and returned the
        picture unchanged, so a caller asking for the impossible got a
        plausible answer; a factor of one returned the caller's own picture
        rather than a copy, which is a write reaching back into something it
        does not own
  - [x] Refuse anything below one or fractional; return a copy at one

- [x] Correction: The default pivot was measured two different ways
  - [x] The horizontal fraction was applied to the rectangle's width and the
        vertical one to its height less one, in two files, for the same idea
  - [x] Give it one owner in the part layer and have the slice reader use it.
        Rounding to nearest reproduces both previous results exactly, so no
        frame changes - confirmed against the reference renders

- [x] Deferred: the turn's cost grows with the square of the part, unbounded
  - [x] Measured on this machine: a 16x24 part turns in 0.04 s and 3 MB; 32x48
        in 0.14 s and 10 MB; 64x96 in 0.57 s and 42 MB; 128x192 in 2.33 s and
        166 MB. Per frame, per turning part
  - [x] A twelve-frame animation with one 128x192 limb therefore locks the
        editor for around half a minute with no way to cancel
  - [x] Not corrected here: what the limit should be, and what happens when it
        is passed, is a decision rather than a repair, and it belongs with the
        track that bounds the other inputs. Recorded as a backlog row with
        these numbers

- [x] Task: Rerun every gate after the corrections
